import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // for navigatorKey
import '../services/auth_service.dart';
import '../widgets/achievement_dialog.dart';

class DailyGoalService {
  static final DailyGoalService _instance = DailyGoalService._internal();
  factory DailyGoalService() => _instance;
  DailyGoalService._internal();

  static const String _progressKey = 'daily_goal_progress';
  static const String _dateKey = 'daily_goal_date';
  static const String _reachedKey = 'daily_goal_reached';

  // In-memory state
  int _currentSeconds = 0;
  int _targetSeconds = 15 * 60; // Default 15 min
  bool _goalReached = false;
  String _todayDate = '';

  // Stream for UI updates (optional, for progress bars)
  final StreamController<int> _progressController =
      StreamController<int>.broadcast();
  Stream<int> get progressStream => _progressController.stream;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month}-${now.day}";

    _todayDate = dateStr;

    // Check if new day
    final savedDate = prefs.getString(_dateKey);
    if (savedDate != dateStr) {
      // New day, reset
      _currentSeconds = 0;
      _goalReached = false;
      await prefs.setString(_dateKey, dateStr);
      await prefs.setInt(_progressKey, 0);
      await prefs.setBool(_reachedKey, false);
    } else {
      // Load today's progress
      _currentSeconds = prefs.getInt(_progressKey) ?? 0;
      _goalReached = prefs.getBool(_reachedKey) ?? false;
    }

    // Load target from Auth/User
    await _loadTarget(prefs);
    print(
      '[DailyGoalService] Init complete. Target: $_targetSeconds, Current: $_currentSeconds, Reached: $_goalReached',
    );
  }

  Future<void> _loadTarget(SharedPreferences prefs) async {
    // Try to get from AuthService (user profile)
    final user = await AuthService().getUser();
    int? customMinutes;

    if (user != null) {
      // Check if preferences is a Map or JSON string
      Map<String, dynamic> prefs = {};
      if (user['preferences'] != null) {
        if (user['preferences'] is String) {
          try {
            prefs = json.decode(user['preferences']);
          } catch (e) {
            print("[DailyGoalService] Error parsing preferences: $e");
          }
        } else if (user['preferences'] is Map) {
          prefs = Map<String, dynamic>.from(user['preferences']);
        }
      }

      if (prefs.containsKey('daily_goal_minutes')) {
        customMinutes = prefs['daily_goal_minutes'];
      }
    }

    if (customMinutes != null) {
      _targetSeconds = customMinutes * 60;
      // If target is 0 or less, confirm default is 15 mins (900s)
      if (_targetSeconds <= 0) _targetSeconds = 900;
    } else {
      // Fallback
      _targetSeconds = 900; // 15 min default
    }
  }

  // Allow updating target immediately (e.g. after onboarding)
  void updateTarget(int minutes) {
    _targetSeconds = minutes * 60;
    print('[DailyGoalService] Target updated to $_targetSeconds seconds');
    // Re-check if goal met immediately?
    if (!_goalReached && _currentSeconds >= _targetSeconds) {
      _goalReached = true;
      // We might not want to trigger popup immediately upon setting goal if they already listened enough?
      // but user "set" it, so maybe they want to know.
      // For now, let's just update state.
    }
  }

  Future<void> addSeconds(int seconds) async {
    // Ensure we are on the correct day
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month}-${now.day}";

    final prefs = await SharedPreferences.getInstance();

    if (_todayDate != dateStr) {
      // Date changed
      _todayDate = dateStr;
      _currentSeconds = 0;
      _goalReached = false;
      await prefs.setString(_dateKey, dateStr);
      await prefs.setBool(_reachedKey, false);
      await _loadTarget(prefs);
      print('[DailyGoalService] New day reset');
    }

    _currentSeconds += seconds;
    await prefs.setInt(_progressKey, _currentSeconds);
    _progressController.add(_currentSeconds);

    print('[DailyGoalService] Progress: $_currentSeconds / $_targetSeconds');

    if (!_goalReached && _currentSeconds >= _targetSeconds) {
      print('[DailyGoalService] Goal reached! Triggering popup.');
      _goalReached = true;
      await prefs.setBool(_reachedKey, true);
      _triggerAchievement();
    }
  }

  Future<void> _triggerAchievement() async {
    // Call API to record goal and get streak/badges
    int streak = 0;
    List<dynamic> newBadges = [];

    try {
      final token = await AuthService().getAccessToken();
      if (token != null) {
        final url = Uri.parse(
          '${ApiConstants.baseUrl}/user/daily-goal-reached',
        );
        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'X-App-Source':
                'Echo_Secured_9xQ2zP5mL8kR4wN1vJ7', // Should ideally come from ApiConstants or AuthService
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          streak = data['streak'] ?? 0;
          newBadges = data['badges_earned'] ?? [];
          print(
            '[DailyGoalService] API recorded goal. Streak: $streak, Badges: ${newBadges.length}',
          );
        } else {
          print(
            '[DailyGoalService] API failed: ${response.statusCode} ${response.body}',
          );
        }
      }
    } catch (e) {
      print('[DailyGoalService] Error calling API: $e');
    }

    // Determine context
    final context = navigatorKey.currentState?.context;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AchievementDialog(
          minutes: (_targetSeconds / 60).round(),
          streak: streak,
          badges: newBadges,
        ),
      );
    }
  }

  // Helpers for UI
  int get currentSeconds => _currentSeconds;
  int get targetSeconds => _targetSeconds;
  bool get isGoalMet => _goalReached;
}
