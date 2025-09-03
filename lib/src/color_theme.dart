import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
  // Light Theme
  static ThemeData materialLightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryLight,
      secondary: AppColors.secondaryLight,
      background: AppColors.backgroundLight,
      surface: AppColors.surfaceLight,
      error: AppColors.errorLight,
      onPrimary: AppColors.onPrimaryLight,
      onSecondary: AppColors.onSecondaryLight,
      onBackground: AppColors.onBackgroundLight,
      onSurface: AppColors.onSurfaceLight,
      onError: AppColors.onErrorLight,
    ),
  );

  static CupertinoThemeData cupertinoLightTheme = const CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primaryLight,
    //barBackgroundColor: AppColors.backgroundLight,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(fontFamily: 'Inter'),
      primaryColor: AppColors.onBackgroundLight,
    ),
  );

  // Dark Theme
  static ThemeData materialDarkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      secondary: AppColors.secondaryDark,
      background: AppColors.backgroundDark,
      surface: AppColors.surfaceDark,
      error: AppColors.errorDark,
      onPrimary: AppColors.onPrimaryDark,
      onSecondary: AppColors.onSecondaryDark,
      onBackground: AppColors.onBackgroundDark,
      onSurface: AppColors.onSurfaceDark,
      onError: AppColors.onErrorDark,
    ),
  );

  static CupertinoThemeData cupertinoDarkTheme = const CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryDark,
    //barBackgroundColor: AppColors.backgroundDark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(fontFamily: 'Inter'),
      primaryColor: AppColors.onBackgroundDark,
    ),
  );
}
