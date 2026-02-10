import 'package:shared_preferences/shared_preferences.dart';

class PlayerPreferences {
  static const String keySkipBackward = 'player_skip_backward';
  static const String keySkipForward = 'player_skip_forward';
  static const String keyDefaultSpeed = 'player_default_speed';

  // Singleton pattern
  static final PlayerPreferences _instance = PlayerPreferences._internal();
  factory PlayerPreferences() => _instance;
  PlayerPreferences._internal();

  // Defaults
  static const int defaultSkipBackward = 10;
  static const int defaultSkipForward = 30;
  static const double defaultSpeed = 1.0;

  Future<int> getSkipBackward() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keySkipBackward) ?? defaultSkipBackward;
  }

  Future<void> setSkipBackward(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keySkipBackward, seconds);
  }

  Future<int> getSkipForward() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keySkipForward) ?? defaultSkipForward;
  }

  Future<void> setSkipForward(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keySkipForward, seconds);
  }

  Future<double> getDefaultSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(keyDefaultSpeed) ?? defaultSpeed;
  }

  Future<void> setDefaultSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(keyDefaultSpeed, speed);
  }
}
