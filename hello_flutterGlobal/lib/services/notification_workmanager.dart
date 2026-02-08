import 'dart:convert';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../data/motivation_messages.dart';
import 'notification_service.dart';

// Task name constants
const String kDailyMotivationTask =
    'com.velorus.echoHistory.dailyMotivation';
const String kMotivationSlotTask =
    'com.velorus.echoHistory.motivationSlot';
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
          prefs.getBool('notifications_enabled_$userId') ?? false;
      if (!masterEnabled) return Future.value(true);

      switch (taskName) {
        case kDailyMotivationTask:
          return await _handleDailyMotivation(prefs, plugin, userId);
        case kMotivationSlotTask:
          return await _handleMotivationSlot(prefs, plugin, inputData, userId);
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

/// Handles the daily motivation periodic task.
/// Shows message #1 immediately, schedules 4 one-off tasks for the rest.
Future<bool> _handleDailyMotivation(
  SharedPreferences prefs,
  FlutterLocalNotificationsPlugin plugin,
  String userId,
) async {
  // Check sub-toggle
  final motivationEnabled =
      prefs.getBool('motivation_enabled_$userId') ?? true;
  if (!motivationEnabled) return true;

  // Get user locale
  final locale = prefs.getString('notification_locale_$userId') ?? 'en';
  final messages = motivationMessages[locale] ?? motivationMessages['en']!;

  // Select 5 non-repeating messages
  final recentRaw = prefs.getString('motivation_recent_indices_$userId');
  List<int> recentIndices =
      recentRaw != null ? (jsonDecode(recentRaw) as List).cast<int>() : [];

  // Build pool of available indices
  List<int> available = [];
  for (int i = 0; i < messages.length; i++) {
    if (!recentIndices.contains(i)) {
      available.add(i);
    }
  }

  // If not enough available, reset recent list
  if (available.length < 5) {
    recentIndices = [];
    available = List.generate(messages.length, (i) => i);
  }

  // Shuffle and pick 5
  available.shuffle(Random());
  final selected = available.take(5).toList();

  // Update recent indices (rolling window of 15)
  recentIndices.addAll(selected);
  if (recentIndices.length > 15) {
    recentIndices = recentIndices.sublist(recentIndices.length - 15);
  }
  await prefs.setString(
    'motivation_recent_indices_$userId',
    jsonEncode(recentIndices),
  );
  await prefs.setString(
    'motivation_today_indices_$userId',
    jsonEncode(selected),
  );

  // Show first notification immediately
  await plugin.show(
    NotificationService.motivationBaseId,
    'Echoes Of History',
    messages[selected[0]],
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

  // Schedule 4 one-off tasks for remaining messages
  for (int i = 1; i < selected.length; i++) {
    await Workmanager().registerOneOffTask(
      '${kMotivationSlotTask}_$i',
      kMotivationSlotTask,
      initialDelay: Duration(hours: 2 * i), // +2h, +4h, +6h, +8h
      constraints: Constraints(networkType: NetworkType.notRequired),
      inputData: {'slotIndex': i},
    );
  }

  return true;
}

/// Handles a staggered motivation slot (messages 2-5).
Future<bool> _handleMotivationSlot(
  SharedPreferences prefs,
  FlutterLocalNotificationsPlugin plugin,
  Map<String, dynamic>? inputData,
  String userId,
) async {
  final motivationEnabled =
      prefs.getBool('motivation_enabled_$userId') ?? true;
  if (!motivationEnabled) return true;

  final slotIndex = inputData?['slotIndex'] as int? ?? 0;

  // Get today's selected indices
  final todayRaw = prefs.getString('motivation_today_indices_$userId');
  if (todayRaw == null) return true;
  final todayIndices = (jsonDecode(todayRaw) as List).cast<int>();
  if (slotIndex >= todayIndices.length) return true;

  // Get user locale
  final locale = prefs.getString('notification_locale_$userId') ?? 'en';
  final messages = motivationMessages[locale] ?? motivationMessages['en']!;
  final messageIndex = todayIndices[slotIndex];
  if (messageIndex >= messages.length) return true;

  await plugin.show(
    NotificationService.motivationBaseId + slotIndex,
    'Echoes Of History',
    messages[messageIndex],
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

  return true;
}

/// Handles the continue listening periodic task.
Future<bool> _handleContinueListening(
  SharedPreferences prefs,
  FlutterLocalNotificationsPlugin plugin,
  String userId,
) async {
  // Check sub-toggle
  final clEnabled =
      prefs.getBool('continue_listening_enabled_$userId') ?? true;
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

  return true;
}
