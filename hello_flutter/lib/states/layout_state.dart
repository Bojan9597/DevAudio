import 'package:flutter/material.dart';

class LayoutState extends ChangeNotifier {
  bool isCollapsed = false;
  String selectedCategoryId =
      'library'; // Default restored to 'library' as per previous successful state
  bool isGridView = true;
  Locale? _locale;

  Locale? get locale => _locale;

  void setLocale(Locale loc) {
    _locale = loc;
    notifyListeners();
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
