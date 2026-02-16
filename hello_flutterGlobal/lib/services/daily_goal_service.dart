import 'dart:async';
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
    if (user != null && user['daily_goal_minutes'] != null) {
      _targetSeconds = (user['daily_goal_minutes'] as int) * 60;
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

  void _triggerAchievement() {
    // Determine context
    final context = navigatorKey.currentState?.context;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) =>
            AchievementDialog(minutes: (_targetSeconds / 60).round()),
      );
    }
  }

  // Helpers for UI
  int get currentSeconds => _currentSeconds;
  int get targetSeconds => _targetSeconds;
  bool get isGoalMet => _goalReached;
}
