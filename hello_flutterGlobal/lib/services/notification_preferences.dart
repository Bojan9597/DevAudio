import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences {
  // Master toggle
  Future<bool> isEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled_$userId') ?? true;
  }

  Future<void> setEnabled(String userId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled_$userId', enabled);
  }

  // Motivation sub-toggle
  Future<bool> isMotivationEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('motivation_enabled_$userId') ?? true;
  }

  Future<void> setMotivationEnabled(String userId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('motivation_enabled_$userId', enabled);
  }

  // Continue Listening sub-toggle
  Future<bool> isContinueListeningEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('continue_listening_enabled_$userId') ?? false;
  }

  Future<void> setContinueListeningEnabled(String userId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('continue_listening_enabled_$userId', enabled);
  }

  // Motivation time (defaults to 9:00 AM)
  Future<TimeOfDay> getMotivationTime(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('notification_time_hour_$userId') ?? 9;
    final minute = prefs.getInt('notification_time_minute_$userId') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setMotivationTime(String userId, TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_time_hour_$userId', time.hour);
    await prefs.setInt('notification_time_minute_$userId', time.minute);
  }

  // Continue Listening time (defaults to 6:00 PM)
  Future<TimeOfDay> getContinueListeningTime(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('cl_time_hour_$userId') ?? 18;
    final minute = prefs.getInt('cl_time_minute_$userId') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setContinueListeningTime(String userId, TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cl_time_hour_$userId', time.hour);
    await prefs.setInt('cl_time_minute_$userId', time.minute);
  }

  /// Sync data needed by background isolate (userId and locale).
  /// Called on login and locale change.
  Future<void> syncForBackground(String userId, String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_user_id', userId);
    await prefs.setString('notification_locale_$userId', locale);
  }

  // Recently shown motivation message indices (rolling window of 15)
  Future<List<int>> getRecentIndices(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('motivation_recent_indices_$userId');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<int>();
  }

  Future<void> updateRecentIndices(String userId, List<int> indices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'motivation_recent_indices_$userId',
      jsonEncode(indices),
    );
  }

  // Today's selected motivation indices (5 messages)
  Future<List<int>> getTodayIndices(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('motivation_today_indices_$userId');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<int>();
  }

  Future<void> setTodayIndices(String userId, List<int> indices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'motivation_today_indices_$userId',
      jsonEncode(indices),
    );
  }
}
