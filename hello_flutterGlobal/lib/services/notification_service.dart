import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../main.dart';
import '../models/book.dart';
import '../screens/playlist_screen.dart';
import 'notification_preferences.dart';
import 'notification_workmanager.dart';

/// Top-level handler for notification taps when the app is dead (cold start).
/// Must be a top-level or static function — runs in its own isolate.
@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  // Nothing to do here — the payload is captured via
  // getNotificationAppLaunchDetails() when the app cold-starts.
  // This handler just needs to exist so Flutter doesn't drop the tap.
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  String? _pendingPayload;

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  // Notification channel IDs
  static const String motivationChannelId = 'motivation_channel';
  static const String continueListeningChannelId = 'continue_listening_channel';

  // Notification IDs
  static const int motivationBaseId = 1000; // 1000-1004
  static const int continueListeningId = 2000;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    // Create notification channels
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          motivationChannelId,
          'Daily Motivation',
          description: 'History-themed motivational quotes',
          importance: Importance.defaultImportance,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          continueListeningChannelId,
          'Continue Listening',
          description: 'Reminders to continue your audiobook',
          importance: Importance.defaultImportance,
        ),
      );
    }

    // Check for cold-start deep-link
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _pendingPayload = launchDetails!.notificationResponse?.payload;
    }
  }

  /// Process pending payload from cold-start notification tap.
  /// Call after auth completes and main UI is mounted.
  void processPendingPayload() {
    if (_pendingPayload != null) {
      final payload = _pendingPayload!;
      _pendingPayload = null;
      // Defer to next frame so navigation stack is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handlePayload(payload);
      });
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    _handlePayload(response.payload!);
  }

  static void _handlePayload(String payload) async {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      print('[NotificationService] Notification tapped with payload: $data');

      if (data['type'] == 'continue_listening') {
        // Disabled deep linking to prevent black screen issues on cold start.
        // Tapping the notification will just open the app to the home screen.
        /*
        final bookId = data['bookId'] as String?;
        final trackId = data['resumeFromTrackId'] as int?;
        if (bookId == null) return;

        // Read cached discover data to reconstruct the Book
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('notification_user_id');
        final cacheKey = 'cached_discover_${userId ?? "anon"}';
        final cachedData = prefs.getString(cacheKey);
        if (cachedData == null) return;

        final Map<String, dynamic> discoverData = jsonDecode(cachedData);
        final listenHistory = discoverData['listenHistory'] as List? ?? [];

        // Find the book by ID
        Map<String, dynamic>? bookJson;
        for (final item in listenHistory) {
          if (item is Map<String, dynamic> && item['id'].toString() == bookId) {
            bookJson = item;
            break;
          }
        }
        if (bookJson == null) return;

        final book = Book.fromJson(bookJson);
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => PlaylistScreen(
              book: book,
              resumeFromTrackId: trackId,
            ),
          ),
        );
        */
      }
    } catch (e) {
      print('[NotificationService] Error handling payload: $e');
    }
  }

  /// Show a motivation notification.
  Future<void> showMotivationNotification(int slotIndex, String body) async {
    await _plugin.show(
      motivationBaseId + slotIndex,
      'Echoes Of History',
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          motivationChannelId,
          'Daily Motivation',
          channelDescription: 'History-themed motivational quotes',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      payload: jsonEncode({'type': 'motivation'}),
    );
  }

  /// Show a continue listening notification.
  Future<void> showContinueListeningNotification(
    String bookTitle,
    String bookId,
    int? resumeFromTrackId,
  ) async {
    await _plugin.show(
      continueListeningId,
      'Continue Listening',
      'Pick up where you left off: $bookTitle',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          continueListeningChannelId,
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
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Compute delay from now until the next occurrence of [hour]:[minute].
  /// If that time already passed today, targets tomorrow.
  static Duration _computeDelay(int hour, int minute) {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute);
    if (target.isBefore(now) || target.isAtSameMomentAs(now)) {
      target = target.add(const Duration(days: 1));
    }
    return target.difference(now);
  }

  /// Register WorkManager tasks based on user preferences.
  /// Uses OneOff tasks with REPLACE policy. The worker reschedules itself
  /// for the next day after firing.
  Future<void> registerNotificationTasks(String userId) async {
    final prefs = NotificationPreferences();
    if (!await prefs.isEnabled(userId)) return;

    // Daily motivation – its own scheduled time
    if (await prefs.isMotivationEnabled(userId)) {
      final mTime = await prefs.getMotivationTime(userId);
      final mDelay = _computeDelay(mTime.hour, mTime.minute);
      await Workmanager().registerOneOffTask(
        kDailyMotivationTask,
        kDailyMotivationTask,
        initialDelay: mDelay,
        constraints: Constraints(networkType: NetworkType.notRequired),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    }

    // Continue listening – its own scheduled time
    if (await prefs.isContinueListeningEnabled(userId)) {
      final clTime = await prefs.getContinueListeningTime(userId);
      final clDelay = _computeDelay(clTime.hour, clTime.minute);
      await Workmanager().registerOneOffTask(
        kContinueListeningTask,
        kContinueListeningTask,
        initialDelay: clDelay,
        constraints: Constraints(networkType: NetworkType.notRequired),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    }
  }

  /// Cancel all WorkManager tasks and local notifications.
  /// Call on logout or when user disables notifications entirely.
  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
    await _plugin.cancelAll();
  }

  /// Re-schedule tasks after user changes time or toggles.
  /// Cancels existing work first, then registers fresh.
  Future<void> rescheduleNotificationTasks(String userId) async {
    await Workmanager().cancelAll();
    await registerNotificationTasks(userId);
  }
}
