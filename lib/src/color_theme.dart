import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'theme/colors.dart';

// LEGACY: These static constants are deprecated.
// Use AppColors.of(context) from theme/colors.dart instead.
class AppColors {
  // Light Mode Colors
  static const Color primaryLight = Color(0xFFFF595E);
  static const Color secondaryLight = Color(0xFF03DAC6);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color sidebarLight = Color(0xFFF0F0F5); // Sidebar color for light mode
  static const Color errorLight = Color(0xFFB00020);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onSecondaryLight = Color(0xFF000000);
  static const Color onBackgroundLight = Color(0xFF000000);
  static const Color onSurfaceLight = Color(0xFF000000);
  static const Color onErrorLight = Color(0xFFFFFFFF);

  // Dark Mode Colors
  static const Color primaryDark = Color(0xFFFF595E);
  static const Color secondaryDark = Color(0xFF03DAC6);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1F1F1F);
  static const Color sidebarDark = Color(0xFF1E1E1E); // Sidebar color for dark mode
  static const Color errorDark = Color(0xFFCF6679);
  static const Color onPrimaryDark = Color(0xFF000000);
  static const Color onSecondaryDark = Color(0xFF000000);
  static const Color onBackgroundDark = Color(0xFFFFFFFF);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  static const Color onErrorDark = Color(0xFF000000);
}

class AppTheme {
  // Helper to create themes using our new color system
  static ThemeData materialLightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: AppColorSwatches.primary[500]!,
      secondary: AppColorSwatches.secondary[500]!,
      surface: const Color(0xFFFAFAFA),  // From our new system
      error: AppColorSwatches.error[600]!,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: AppColorSwatches.neutral[900]!,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,  // From our new system
  );

  static CupertinoThemeData cupertinoLightTheme = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: AppColorSwatches.primary[500]!,
    scaffoldBackgroundColor: Colors.white,  // From our new system
    textTheme: CupertinoTextThemeData(
      textStyle: const TextStyle(fontFamily: 'Inter'),
      primaryColor: AppColorSwatches.neutral[900]!,
    ),
  );

  // Dark Theme
  static ThemeData materialDarkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppColorSwatches.primary[400]!,
      secondary: AppColorSwatches.secondary[400]!,
      surface: const Color(0xFF1F1F1F),  // From our new system
      error: AppColorSwatches.error[400]!,
      onPrimary: AppColorSwatches.neutral[900]!,
      onSecondary: Colors.black,
      onSurface: AppColorSwatches.neutral[50]!,
      onError: Colors.black,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),  // From our new system
  );

  static CupertinoThemeData cupertinoDarkTheme = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColorSwatches.primary[400]!,
    scaffoldBackgroundColor: const Color(0xFF121212),  // From our new system
    textTheme: CupertinoTextThemeData(
      textStyle: const TextStyle(fontFamily: 'Inter'),
      primaryColor: AppColorSwatches.neutral[50]!,
    ),
  );
}
