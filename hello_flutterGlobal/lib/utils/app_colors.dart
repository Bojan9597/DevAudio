import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0F172A); // Dark navy
  static const Color cardBackground = Color(0xFF1E293B);
  static const Color accent = Color(0xFF38BDF8); // Sky blue
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
