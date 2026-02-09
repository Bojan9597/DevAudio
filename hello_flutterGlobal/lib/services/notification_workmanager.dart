import 'dart:convert';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../data/motivation_messages.dart';
import 'notification_service.dart';

// Task name constants
const String kDailyMotivationTask = 'com.velorus.echoHistory.dailyMotivation';
const String kContinueListeningTask =
    'com.velorus.echoHistory.continueListening';

/// Top-level WorkManager callback. Runs in a background isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // Background isolate needs its own plugin instance
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );

      final prefs = await SharedPreferences.getInstance();

      // Read userId from shared prefs (set during login sync)
      final userId = prefs.getString('notification_user_id');
      if (userId == null) return Future.value(true);

      // Check master toggle
      final masterEnabled =
          prefs.getBool('notifications_enabled_$userId') ?? true;
      if (!masterEnabled) return Future.value(true);

      switch (taskName) {
        case kDailyMotivationTask:
          return await _handleDailyMotivation(prefs, plugin, userId);
        case kContinueListeningTask:
          return await _handleContinueListening(prefs, plugin, userId);
        default:
          return Future.value(true);
      }
    } catch (e) {
      print('[NotificationWorker] Error in $taskName: $e');
      return Future.value(true); // Return true to avoid retry loops
    }
  });
}

/// Compute delay from now until the next occurrence of [hour]:[minute] tomorrow.
Duration _delayUntilTomorrow(int hour, int minute) {
  final now = DateTime.now();
  var target = DateTime(
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  ).add(const Duration(days: 1));
  return target.difference(now);
}

/// Read the user's preferred motivation time from SharedPreferences.
Future<(int, int)> _getMotivationTime(
  SharedPreferences prefs,
  String userId,
) async {
  final hour = prefs.getInt('notification_time_hour_$userId') ?? 9;
  final minute = prefs.getInt('notification_time_minute_$userId') ?? 0;
  return (hour, minute);
}

/// Read the user's preferred continue listening time from SharedPreferences.
Future<(int, int)> _getContinueListeningTime(
  SharedPreferences prefs,
  String userId,
) async {
  final hour = prefs.getInt('cl_time_hour_$userId') ?? 18;
  final minute = prefs.getInt('cl_time_minute_$userId') ?? 0;
  return (hour, minute);
}

/// Handles the daily motivation task.
/// Picks 1 random non-repeating message, shows it,
/// then reschedules itself for tomorrow at the user's preferred time.
Future<bool> _handleDailyMotivation(
  SharedPreferences prefs,
  FlutterLocalNotificationsPlugin plugin,
  String userId,
) async {
  // Check sub-toggle
  final motivationEnabled = prefs.getBool('motivation_enabled_$userId') ?? true;
  if (!motivationEnabled) return true;

  // Get user locale
  final locale = prefs.getString('notification_locale_$userId') ?? 'en';
  final messages = motivationMessages[locale] ?? motivationMessages['en']!;

  // Load recent indices to avoid repeats
  final recentRaw = prefs.getString('motivation_recent_indices_$userId');
  List<int> recentIndices = recentRaw != null
      ? (jsonDecode(recentRaw) as List).cast<int>()
      : [];

  // Build pool of available indices
  List<int> available = [];
  for (int i = 0; i < messages.length; i++) {
    if (!recentIndices.contains(i)) {
      available.add(i);
    }
  }

  // If none available, reset recent list
  if (available.isEmpty) {
    recentIndices = [];
    available = List.generate(messages.length, (i) => i);
  }

  // Pick 1 random message
  final picked = available[Random().nextInt(available.length)];

  // Update recent indices (rolling window of 15)
  recentIndices.add(picked);
  if (recentIndices.length > 15) {
    recentIndices = recentIndices.sublist(recentIndices.length - 15);
  }
  await prefs.setString(
    'motivation_recent_indices_$userId',
    jsonEncode(recentIndices),
  );

  // Show the notification
  await plugin.show(
    NotificationService.motivationBaseId,
    'Echoes Of History',
    messages[picked],
    const NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationService.motivationChannelId,
        'Daily Motivation',
        channelDescription: 'History-themed motivational quotes',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    ),
    payload: jsonEncode({'type': 'motivation'}),
  );

  // Reschedule this task for tomorrow at the user's preferred motivation time
  final (hour, minute) = await _getMotivationTime(prefs, userId);
  await Workmanager().registerOneOffTask(
    kDailyMotivationTask,
    kDailyMotivationTask,
    initialDelay: _delayUntilTomorrow(hour, minute),
    constraints: Constraints(networkType: NetworkType.notRequired),
  );

  return true;
}

/// Handles the continue listening task.
/// Shows the notification, then reschedules itself for tomorrow.
Future<bool> _handleContinueListening(
  SharedPreferences prefs,
  FlutterLocalNotificationsPlugin plugin,
  String userId,
) async {
  // Check sub-toggle
  final clEnabled = prefs.getBool('continue_listening_enabled_$userId') ?? true;
  if (!clEnabled) return true;

  // Read cached discover data
  final cacheKey = 'cached_discover_$userId';
  final cachedData = prefs.getString(cacheKey);
  if (cachedData == null) return true;

  final Map<String, dynamic> discoverData = jsonDecode(cachedData);
  final listenHistory = discoverData['listenHistory'] as List? ?? [];
  if (listenHistory.isEmpty) return true;

  // Filter to books < 95% complete (mirrors home_screen logic)
  Map<String, dynamic>? firstBook;
  for (final item in listenHistory) {
    if (item is Map<String, dynamic>) {
      final lastPosition = item['lastPosition'] as int?;
      final duration = item['duration'] as int?;
      if (lastPosition != null && duration != null && duration > 0) {
        final progress = lastPosition / duration;
        if (progress >= 0.95) continue;
      }
      firstBook = item;
      break;
    }
  }

  if (firstBook == null) return true;

  final bookTitle = firstBook['title'] as String? ?? 'your audiobook';
  final bookId = firstBook['id']?.toString() ?? '';
  final resumeFromTrackId = firstBook['currentPlaylistItemId'] as int?;

  await plugin.show(
    NotificationService.continueListeningId,
    'Continue Listening',
    'Pick up where you left off: $bookTitle',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationService.continueListeningChannelId,
        'Continue Listening',
        channelDescription: 'Reminders to continue your audiobook',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    ),
    payload: jsonEncode({
      'type': 'continue_listening',
      'bookId': bookId,
      'bookTitle': bookTitle,
      'resumeFromTrackId': resumeFromTrackId,
    }),
  );

  // Reschedule for tomorrow at user's preferred continue listening time
  final (hour, minute) = await _getContinueListeningTime(prefs, userId);
  await Workmanager().registerOneOffTask(
    kContinueListeningTask,
    kContinueListeningTask,
    initialDelay: _delayUntilTomorrow(hour, minute),
    constraints: Constraints(networkType: NetworkType.notRequired),
  );

  return true;
}
