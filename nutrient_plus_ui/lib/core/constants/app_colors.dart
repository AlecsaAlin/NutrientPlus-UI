import 'package:flutter/material.dart';

class AppColors {
  // Primary color - Green from splash screen
  static const Color primary = Color(0xFF2D5016);
  static const Color primaryLight = Color(0xFF3D6B1E);
  static const Color primaryDark = Color(0xFF1E3A0F);
  
  // Background colors
  static const Color background = Color(0xFFFAF8F5);
  static const Color cardBackground = Colors.white;
  
  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  
  // Accent colors
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFB347);
  
  // With opacity
  static Color primaryWithOpacity(double opacity) => primary.withValues(alpha: opacity);
}
