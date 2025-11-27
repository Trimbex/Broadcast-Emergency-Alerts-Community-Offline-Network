import 'package:flutter/material.dart';

/// BEACON Design System - Color Constants
/// 
/// Premium-grade, disaster-communication-friendly color palette
/// with high contrast and accessibility (AA/AAA compliant)
/// Supports both light and dark themes
class BeaconColors {
  // Accent & Emergency Colors (same for both themes)
  static const Color primary = Color(0xFFFF6B35); // Beacon Orange
  static const Color warning = Color(0xFFFFB627); // Signal Amber
  static const Color error = Color(0xFFEF233C); // Alert Red
  static const Color success = Color(0xFF4CAF50); // Safe Green
  static const Color secondary = Color(0xFF4EA8DE); // Sky Teal

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0D1B2A); // Night Blue
  static const Color darkSurface = Color(0xFF1B263B); // Steel Blue
  static const Color darkBorder = Color(0xFF415A77); // Deep Gray Blue
  static const Color darkTextPrimary = Color(0xFFE0E5EA); // Mist Gray
  static const Color darkTextSecondary = Color(0xFF9BA8B2); // Soft gray

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF5F7FA); // Soft White
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure White
  static const Color lightBorder = Color(0xFFE1E8ED); // Light Gray
  static const Color lightTextPrimary = Color(0xFF1A1F2E); // Dark Navy
  static const Color lightTextSecondary = Color(0xFF6B7280); // Medium Gray

  // Gradient Colors - Dark Theme
  static const List<Color> darkPrimaryGradient = [
    Color(0xFF0D1B2A), // Night Blue
    Color(0xFF1B263B), // Steel Blue
  ];

  static const List<Color> darkAccentGradient = [
    Color(0xFFFF6B35), // Beacon Orange
    Color(0xFFFF8C42), // Lighter orange
  ];

  // Gradient Colors - Light Theme
  static const List<Color> lightPrimaryGradient = [
    Color(0xFFF5F7FA), // Soft White
    Color(0xFFFFFFFF), // Pure White
  ];

  static const List<Color> lightAccentGradient = [
    Color(0xFFFF6B35), // Beacon Orange
    Color(0xFFFF8C42), // Lighter orange
  ];

  // Helper methods to get theme-appropriate colors
  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : lightSurface;
  }

  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorder
        : lightBorder;
  }

  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : lightTextPrimary;
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : lightTextSecondary;
  }

  static List<Color> primaryGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkPrimaryGradient
        : lightPrimaryGradient;
  }

  static List<Color> accentGradient(BuildContext context) {
    return darkAccentGradient; // Same for both themes
  }
}
