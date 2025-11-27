import 'package:flutter/material.dart';
import 'beacon_colors.dart';

/// BEACON Light Theme
final ThemeData beaconLightTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  scaffoldBackgroundColor: BeaconColors.lightBackground,
  primaryColor: BeaconColors.primary,
  
  colorScheme: const ColorScheme.light(
    primary: BeaconColors.primary,
    secondary: BeaconColors.secondary,
    surface: BeaconColors.lightSurface,
    background: BeaconColors.lightBackground,
    error: BeaconColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: BeaconColors.lightTextPrimary,
    onBackground: BeaconColors.lightTextPrimary,
    onError: Colors.white,
  ),

  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: BeaconColors.lightTextPrimary,
      fontWeight: FontWeight.bold,
      fontSize: 32,
    ),
    displayMedium: TextStyle(
      color: BeaconColors.lightTextPrimary,
      fontWeight: FontWeight.bold,
      fontSize: 28,
    ),
    displaySmall: TextStyle(
      color: BeaconColors.lightTextPrimary,
      fontWeight: FontWeight.bold,
      fontSize: 24,
    ),
    headlineMedium: TextStyle(
      color: BeaconColors.lightTextPrimary,
      fontWeight: FontWeight.bold,
      fontSize: 28,
    ),
    headlineSmall: TextStyle(
      color: BeaconColors.lightTextPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 24,
    ),
    titleLarge: TextStyle(
      color: BeaconColors.lightTextPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    ),
    titleMedium: TextStyle(
      color: BeaconColors.lightTextPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 18,
    ),
    bodyLarge: TextStyle(
      color: BeaconColors.lightTextPrimary,
      fontSize: 18,
    ),
    bodyMedium: TextStyle(
      color: BeaconColors.lightTextPrimary,
      fontSize: 16,
    ),
    bodySmall: TextStyle(
      color: BeaconColors.lightTextSecondary,
      fontSize: 14,
    ),
    labelLarge: TextStyle(
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: TextStyle(
      color: BeaconColors.lightTextPrimary,
      fontSize: 14,
    ),
    labelSmall: TextStyle(
      color: BeaconColors.lightTextSecondary,
      fontSize: 12,
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: BeaconColors.lightSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: BeaconColors.lightBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: BeaconColors.lightBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: BeaconColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: BeaconColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: BeaconColors.error, width: 2),
    ),
    labelStyle: const TextStyle(color: BeaconColors.lightTextPrimary),
    hintStyle: const TextStyle(color: BeaconColors.lightTextSecondary),
    helperStyle: const TextStyle(color: BeaconColors.lightTextSecondary),
    errorStyle: const TextStyle(color: BeaconColors.error),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: BeaconColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: BeaconColors.primary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: BeaconColors.primary,
      side: const BorderSide(color: BeaconColors.primary, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: BeaconColors.primary,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: BeaconColors.lightSurface,
    foregroundColor: BeaconColors.lightTextPrimary,
    elevation: 0,
    centerTitle: true,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      color: BeaconColors.lightTextPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(
      color: BeaconColors.lightTextPrimary,
    ),
  ),

  cardTheme: CardThemeData(
    color: BeaconColors.lightSurface,
    elevation: 1,
    shadowColor: Colors.black.withOpacity(0.1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: BeaconColors.lightBorder, width: 1),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),

  dialogTheme: DialogThemeData(
    backgroundColor: BeaconColors.lightSurface,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    titleTextStyle: const TextStyle(
      color: BeaconColors.lightTextPrimary,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    contentTextStyle: const TextStyle(
      color: BeaconColors.lightTextPrimary,
      fontSize: 16,
    ),
  ),

  snackBarTheme: SnackBarThemeData(
    backgroundColor: BeaconColors.lightTextPrimary,
    contentTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 14,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    behavior: SnackBarBehavior.floating,
  ),

  dividerTheme: const DividerThemeData(
    color: BeaconColors.lightBorder,
    thickness: 1,
    space: 1,
  ),

  iconTheme: const IconThemeData(
    color: BeaconColors.lightTextPrimary,
    size: 24,
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: BeaconColors.primary,
    foregroundColor: Colors.white,
    elevation: 4,
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: BeaconColors.lightSurface,
    selectedItemColor: BeaconColors.primary,
    unselectedItemColor: BeaconColors.lightTextSecondary,
    selectedLabelStyle: TextStyle(
      fontWeight: FontWeight.w600,
    ),
  ),

  chipTheme: ChipThemeData(
    backgroundColor: BeaconColors.lightBackground,
    selectedColor: BeaconColors.primary.withOpacity(0.2),
    labelStyle: const TextStyle(color: BeaconColors.lightTextPrimary),
    secondaryLabelStyle: const TextStyle(color: Colors.white),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: BeaconColors.lightBorder),
    ),
  ),

  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return BeaconColors.primary;
      }
      return BeaconColors.lightTextSecondary;
    }),
    trackColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return BeaconColors.primary.withOpacity(0.5);
      }
      return BeaconColors.lightBorder;
    }),
  ),

  checkboxTheme: CheckboxThemeData(
    fillColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return BeaconColors.primary;
      }
      return Colors.transparent;
    }),
    checkColor: MaterialStateProperty.all(Colors.white),
    side: const BorderSide(color: BeaconColors.lightBorder, width: 2),
  ),
);

/// BEACON Dark Theme
final ThemeData beaconDarkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  scaffoldBackgroundColor: BeaconColors.darkBackground,
  primaryColor: BeaconColors.primary,
  
  colorScheme: const ColorScheme.dark(
    primary: BeaconColors.primary,
    secondary: BeaconColors.secondary,
    surface: BeaconColors.darkSurface,
    background: BeaconColors.darkBackground,
    error: BeaconColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: BeaconColors.darkTextPrimary,
    onBackground: BeaconColors.darkTextPrimary,
    onError: Colors.white,
  ),

  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: BeaconColors.darkTextPrimary,
      fontWeight: FontWeight.bold,
      fontSize: 32,
    ),
    displayMedium: TextStyle(
      color: BeaconColors.darkTextPrimary,
      fontWeight: FontWeight.bold,
      fontSize: 28,
    ),
    displaySmall: TextStyle(
      color: BeaconColors.darkTextPrimary,
      fontWeight: FontWeight.bold,
      fontSize: 24,
    ),
    headlineMedium: TextStyle(
      color: BeaconColors.darkTextPrimary,
      fontWeight: FontWeight.bold,
      fontSize: 28,
    ),
    headlineSmall: TextStyle(
      color: BeaconColors.darkTextPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 24,
    ),
    titleLarge: TextStyle(
      color: BeaconColors.darkTextPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    ),
    titleMedium: TextStyle(
      color: BeaconColors.darkTextPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 18,
    ),
    bodyLarge: TextStyle(
      color: BeaconColors.darkTextPrimary,
      fontSize: 18,
    ),
    bodyMedium: TextStyle(
      color: BeaconColors.darkTextPrimary,
      fontSize: 16,
    ),
    bodySmall: TextStyle(
      color: BeaconColors.darkTextSecondary,
      fontSize: 14,
    ),
    labelLarge: TextStyle(
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: TextStyle(
      color: BeaconColors.darkTextPrimary,
      fontSize: 14,
    ),
    labelSmall: TextStyle(
      color: BeaconColors.darkTextSecondary,
      fontSize: 12,
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: BeaconColors.darkSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: BeaconColors.darkBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: BeaconColors.darkBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: BeaconColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: BeaconColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: BeaconColors.error, width: 2),
    ),
    labelStyle: const TextStyle(color: BeaconColors.darkTextPrimary),
    hintStyle: const TextStyle(color: BeaconColors.darkTextSecondary),
    helperStyle: const TextStyle(color: BeaconColors.darkTextSecondary),
    errorStyle: const TextStyle(color: BeaconColors.error),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: BeaconColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: BeaconColors.primary,
      side: const BorderSide(color: BeaconColors.primary, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: BeaconColors.primary,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: BeaconColors.darkBackground,
    foregroundColor: BeaconColors.darkTextPrimary,
    elevation: 0,
    centerTitle: true,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      color: BeaconColors.darkTextPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(
      color: BeaconColors.darkTextPrimary,
    ),
  ),

  cardTheme: CardThemeData(
    color: BeaconColors.darkSurface,
    elevation: 1,
    shadowColor: Colors.black.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: BeaconColors.darkBorder, width: 1),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),

  dialogTheme: DialogThemeData(
    backgroundColor: BeaconColors.darkSurface,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    titleTextStyle: const TextStyle(
      color: BeaconColors.darkTextPrimary,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    contentTextStyle: const TextStyle(
      color: BeaconColors.darkTextPrimary,
      fontSize: 16,
    ),
  ),

  snackBarTheme: SnackBarThemeData(
    backgroundColor: BeaconColors.darkSurface,
    contentTextStyle: const TextStyle(
      color: BeaconColors.darkTextPrimary,
      fontSize: 14,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    behavior: SnackBarBehavior.floating,
  ),

  dividerTheme: const DividerThemeData(
    color: BeaconColors.darkBorder,
    thickness: 1,
    space: 1,
  ),

  iconTheme: const IconThemeData(
    color: BeaconColors.darkTextPrimary,
    size: 24,
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: BeaconColors.primary,
    foregroundColor: Colors.white,
    elevation: 4,
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: BeaconColors.darkSurface,
    selectedItemColor: BeaconColors.primary,
    unselectedItemColor: BeaconColors.darkTextSecondary,
    selectedLabelStyle: TextStyle(
      fontWeight: FontWeight.w600,
    ),
  ),

  chipTheme: ChipThemeData(
    backgroundColor: BeaconColors.darkSurface,
    selectedColor: BeaconColors.primary.withOpacity(0.2),
    labelStyle: const TextStyle(color: BeaconColors.darkTextPrimary),
    secondaryLabelStyle: const TextStyle(color: Colors.white),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: BeaconColors.darkBorder),
    ),
  ),

  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return BeaconColors.primary;
      }
      return BeaconColors.darkTextSecondary;
    }),
    trackColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return BeaconColors.primary.withOpacity(0.5);
      }
      return BeaconColors.darkBorder;
    }),
  ),

  checkboxTheme: CheckboxThemeData(
    fillColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return BeaconColors.primary;
      }
      return Colors.transparent;
    }),
    checkColor: MaterialStateProperty.all(Colors.white),
    side: const BorderSide(color: BeaconColors.darkBorder, width: 2),
  ),
);

// Legacy support - defaults to dark theme
final ThemeData beaconTheme = beaconDarkTheme;
