import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../utils/api_constants.dart';

class EmailNotificationSettingsScreen extends StatefulWidget {
  const EmailNotificationSettingsScreen({super.key});

  @override
  State<EmailNotificationSettingsScreen> createState() =>
      _EmailNotificationSettingsScreenState();
}

class _EmailNotificationSettingsScreenState
    extends State<EmailNotificationSettingsScreen> {
  bool _isLoading = true;
  bool _notificationsEnabled = false;
  String _notificationTime = "09:00";
  bool _newReleasesEnabled = false;
  bool _topPicksEnabled = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/user/email-settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-App-Source': ApiConstants.appSourceValue,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _notificationsEnabled = data['enabled'] ?? false;
          _notificationTime = data['time'] ?? "09:00";
          _newReleasesEnabled = data['newReleases'] ?? false;
          _topPicksEnabled = data['topPicks'] ?? false;
        });
      }
    } catch (e) {
      debugPrint("Error loading email settings: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    // Optimistic UI update/Save on change or separate save button?
    // Plan implied "Auto-save" or "Back button save".
    // I'll implement auto-save on change.

    try {
      final token = await _authService.getAccessToken();
      if (token == null) return;

      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/user/email-settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'X-App-Source': ApiConstants.appSourceValue,
        },
        body: jsonEncode({
          'enabled': _notificationsEnabled,
          'time': _notificationTime,
          'newReleases': _newReleasesEnabled,
          'topPicks': _topPicksEnabled,
        }),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.emailSettingsSaved),
          ),
        );
        print("Settings saved successfully!"); // VISIBLE LOG
      }
    } catch (e) {
      print("Error saving email settings: $e"); // VISIBLE LOG
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.error(e.toString())),
          ),
        );
      }
    }
  }

  Future<void> _pickTime() async {
    final parts = _notificationTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        _notificationTime = formatted;
      });
      _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emailNotifications),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text(l10n.getNotifications),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                    _saveSettings();
                  },
                ),
                const Divider(),
                // Only enable sub-settings if master toggle is on
                Opacity(
                  opacity: _notificationsEnabled ? 1.0 : 0.5,
                  child: AbsorbPointer(
                    absorbing: !_notificationsEnabled,
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: Text(l10n.seeWhatIsTrending),
                          subtitle: Text(l10n.trendingToday),
                          value: _topPicksEnabled,
                          onChanged: (value) {
                            setState(() => _topPicksEnabled = value ?? false);
                            _saveSettings();
                          },
                        ),
                        CheckboxListTile(
                          title: Text(l10n.seeWhatIsNew), // "See what is new"
                          subtitle: Text(l10n.newReleases),
                          value: _newReleasesEnabled,
                          onChanged: (value) {
                            setState(
                              () => _newReleasesEnabled = value ?? false,
                            );
                            _saveSettings();
                          },
                        ),
                        ListTile(
                          title: Text(l10n.notificationTime),
                          subtitle: Text(_notificationTime),
                          trailing: const Icon(Icons.access_time),
                          onTap: _pickTime,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
