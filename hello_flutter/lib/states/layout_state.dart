import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LayoutState extends ChangeNotifier {
  bool isCollapsed = false;
  String selectedCategoryId = 'home'; // Default to home page on first login
  bool isGridView = true;
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;
  String? _currentUserId;

  LayoutState() {
    _loadSettings();
  }

  Locale? get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  Future<void> updateUser(String? userId) async {
    _currentUserId = userId;
    // Reset to home screen when user changes (login/logout)
    selectedCategoryId = 'home';
    // Ensure side menu is closed
    isCollapsed = true;
    await _loadSettings();
  }

  String _getStorageKey(String baseKey) {
    if (_currentUserId != null) {
      return '${baseKey}_$_currentUserId';
    }
    return baseKey; // Fallback to global/default for logged out state
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Theme
    final themeString = prefs.getString(_getStorageKey('theme_mode'));
    if (themeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeString,
        orElse: () => ThemeMode.system,
      );
    } else {
      // If no user specific setting, maybe reset to system?
      // Or try loading global? Let's just default to system for fresh user.
      _themeMode = ThemeMode.system;
    }

    // Load Locale
    final langCode = prefs.getString(_getStorageKey('locale_language_code'));
    if (langCode != null) {
      _locale = Locale(langCode);
    } else {
      _locale = null; // System default
    }

    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getStorageKey('theme_mode'), mode.toString());
  }

  void setLocale(Locale loc) async {
    _locale = loc;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _getStorageKey('locale_language_code'),
      loc.languageCode,
    );
  }

  void toggleMenu() {
    isCollapsed = !isCollapsed;
    notifyListeners();
  }

  void setCategoryId(String id) {
    selectedCategoryId = id;
    notifyListeners();
  }

  int refreshVersion = 0;

  void toggleViewMode() {
    isGridView = !isGridView;
    notifyListeners();
  }

  void triggerRefresh() {
    refreshVersion++;
    notifyListeners();
  }
}

// Simple global instance for easy access
final globalLayoutState = LayoutState();
