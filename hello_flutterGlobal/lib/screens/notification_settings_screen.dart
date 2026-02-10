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
  bool _continueListeningEnabled = false;
  TimeOfDay _motivationTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _continueListeningTime = const TimeOfDay(hour: 18, minute: 0);

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
    final mTime = await _prefs.getMotivationTime(uid);
    final clTime = await _prefs.getContinueListeningTime(uid);

    if (mounted) {
      setState(() {
        _userId = uid;
        _masterEnabled = masterEnabled;
        _motivationEnabled = motivationEnabled;
        _continueListeningEnabled = clEnabled;
        _motivationTime = mTime;
        _continueListeningTime = clTime;
        _isLoading = false;
      });
    }
  }

  Future<void> _onMasterToggle(bool value) async {
    if (_userId == null) return;

    if (value) {
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
      await NotificationService().rescheduleNotificationTasks(_userId!);
    } else {
      await NotificationService().cancelAllTasks();
    }
  }

  Future<void> _onMotivationToggle(bool value) async {
    if (_userId == null) return;
    setState(() => _motivationEnabled = value);
    await _prefs.setMotivationEnabled(_userId!, value);
    await NotificationService().rescheduleNotificationTasks(_userId!);
  }

  Future<void> _onContinueListeningToggle(bool value) async {
    if (_userId == null) return;
    setState(() => _continueListeningEnabled = value);
    await _prefs.setContinueListeningEnabled(_userId!, value);
    await NotificationService().rescheduleNotificationTasks(_userId!);
  }

  Future<void> _onMotivationTimeTap() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _motivationTime,
    );
    if (picked == null || _userId == null) return;

    setState(() => _motivationTime = picked);
    await _prefs.setMotivationTime(_userId!, picked);

    if (_masterEnabled && _motivationEnabled) {
      await NotificationService().rescheduleNotificationTasks(_userId!);
    }
  }

  Future<void> _onContinueListeningTimeTap() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _continueListeningTime,
    );
    if (picked == null || _userId == null) return;

    setState(() => _continueListeningTime = picked);
    await _prefs.setContinueListeningTime(_userId!, picked);

    if (_masterEnabled && _continueListeningEnabled) {
      await NotificationService().rescheduleNotificationTasks(_userId!);
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
        title: Text(l10n.listeningNotifications),
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
                  // --- Daily Motivation section ---
                  SwitchListTile(
                    secondary: const Icon(Icons.format_quote),
                    title: Text(l10n.dailyMotivation),
                    subtitle: Text(l10n.dailyMotivationSubtitle),
                    value: _motivationEnabled,
                    onChanged: _onMotivationToggle,
                  ),
                  if (_motivationEnabled)
                    ListTile(
                      leading: const SizedBox(width: 24),
                      title: Text(l10n.notificationTime),
                      trailing: Text(
                        _formatTime(_motivationTime),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      onTap: _onMotivationTimeTap,
                    ),
                  const Divider(),
                  // --- Continue Listening section ---
                  SwitchListTile(
                    secondary: const Icon(Icons.headphones),
                    title: Text(l10n.continueListeningNotification),
                    subtitle: Text(l10n.continueListeningSubtitle),
                    value: _continueListeningEnabled,
                    onChanged: _onContinueListeningToggle,
                  ),
                  if (_continueListeningEnabled)
                    ListTile(
                      leading: const SizedBox(width: 24),
                      title: Text(l10n.notificationTime),
                      trailing: Text(
                        _formatTime(_continueListeningTime),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      onTap: _onContinueListeningTimeTap,
                    ),
                ],
              ],
            ),
    );
  }
}
