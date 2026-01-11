import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LayoutState extends ChangeNotifier {
  bool isCollapsed = false;
  String selectedCategoryId =
      'library'; // Default restored to 'library' as per previous successful state
  bool isGridView = true;
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;

  LayoutState() {
    _loadSettings();
  }

  Locale? get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Theme
    final themeString = prefs.getString('theme_mode');
    if (themeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeString,
        orElse: () => ThemeMode.system,
      );
    }

    // Load Locale
    final langCode = prefs.getString('locale_language_code');
    if (langCode != null) {
      _locale = Locale(langCode);
    }

    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.toString());
  }

  void setLocale(Locale loc) async {
    _locale = loc;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale_language_code', loc.languageCode);
  }

  void toggleMenu() {
    isCollapsed = !isCollapsed;
    notifyListeners();
  }

  void setCategoryId(String id) {
    selectedCategoryId = id;
    notifyListeners();
  }

  void toggleViewMode() {
    isGridView = !isGridView;
    notifyListeners();
  }
}

// Simple global instance for easy access
final globalLayoutState = LayoutState();
