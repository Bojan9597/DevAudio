import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/notification_preferences.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _prefs = NotificationPreferences();
  final _authService = AuthService();

  bool _isLoading = true;
  String? _userId;

  bool _masterEnabled = false;
  bool _motivationEnabled = true;
  bool _continueListeningEnabled = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final uid = userId.toString();
    final masterEnabled = await _prefs.isEnabled(uid);
    final motivationEnabled = await _prefs.isMotivationEnabled(uid);
    final clEnabled = await _prefs.isContinueListeningEnabled(uid);
    final time = await _prefs.getNotificationTime(uid);

    if (mounted) {
      setState(() {
        _userId = uid;
        _masterEnabled = masterEnabled;
        _motivationEnabled = motivationEnabled;
        _continueListeningEnabled = clEnabled;
        _notificationTime = time;
        _isLoading = false;
      });
    }
  }

  Future<void> _onMasterToggle(bool value) async {
    if (_userId == null) return;

    if (value) {
      // Request notification permission on Android 13+
      final status = await Permission.notification.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.notificationPermissionRequired,
              ),
            ),
          );
        }
        return;
      }
    }

    setState(() => _masterEnabled = value);
    await _prefs.setEnabled(_userId!, value);

    if (value) {
      await NotificationService().registerNotificationTasks(_userId!);
    } else {
      await NotificationService().cancelAll();
      await _cancelAllTasks();
    }
  }

  Future<void> _cancelAllTasks() async {
    // Workmanager is cancelled inside registerNotificationTasks when disabled,
    // but also cancel explicitly here for immediate effect
    await NotificationService().registerNotificationTasks(_userId!);
  }

  Future<void> _onMotivationToggle(bool value) async {
    if (_userId == null) return;
    setState(() => _motivationEnabled = value);
    await _prefs.setMotivationEnabled(_userId!, value);
    await NotificationService().registerNotificationTasks(_userId!);
  }

  Future<void> _onContinueListeningToggle(bool value) async {
    if (_userId == null) return;
    setState(() => _continueListeningEnabled = value);
    await _prefs.setContinueListeningEnabled(_userId!, value);
    await NotificationService().registerNotificationTasks(_userId!);
  }

  Future<void> _onTimeTap() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (picked == null || _userId == null) return;

    setState(() => _notificationTime = picked);
    await _prefs.setNotificationTime(_userId!, picked);

    if (_masterEnabled) {
      await NotificationService().registerNotificationTasks(_userId!);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationSettings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 8),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: Text(l10n.enableNotifications),
                  value: _masterEnabled,
                  onChanged: _onMasterToggle,
                ),
                if (_masterEnabled) ...[
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(Icons.format_quote),
                    title: Text(l10n.dailyMotivation),
                    subtitle: Text(l10n.dailyMotivationSubtitle),
                    value: _motivationEnabled,
                    onChanged: _onMotivationToggle,
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.headphones),
                    title: Text(l10n.continueListeningNotification),
                    subtitle: Text(l10n.continueListeningSubtitle),
                    value: _continueListeningEnabled,
                    onChanged: _onContinueListeningToggle,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(l10n.notificationTime),
                    subtitle: Text(l10n.notificationTimeSubtitle),
                    trailing: Text(
                      _formatTime(_notificationTime),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    onTap: _onTimeTap,
                  ),
                ],
              ],
            ),
    );
  }
}
