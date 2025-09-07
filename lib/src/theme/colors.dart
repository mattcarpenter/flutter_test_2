import 'package:flutter/material.dart';

/// Comprehensive color swatch system for the app.
///
/// This provides a consistent set of color swatches with shades from 50-900,
/// following Material Design principles. Each swatch can be accessed with
/// bracket notation, e.g., AppColorSwatches.primary[300].
class AppColorSwatches {
  // Private constructor to prevent instantiation
  AppColorSwatches._();

  /// Neutral palette - warm-toned grays for better visual harmony
  /*static const MaterialColor neutral = MaterialColor(0xFF6B7078, {
    50: Color(0xFFFBFAF9),   // Very light warm gray
    100: Color(0xFFF6F4F3),  // Light warm gray (backgrounds)
    200: Color(0xFFEBE9E7),  // Warm border gray
    300: Color(0xFFDBD7D3),  // Medium light warm gray
    400: Color(0xFFAFA9A3),  // Warm placeholder gray
    500: Color(0xFF6B7078),  // Base warm gray (labels)
    600: Color(0xFF63585B),  // Dark warm gray
    700: Color(0xFF514B51),  // Darker warm gray
    800: Color(0xFF372F37),  // Very dark warm gray
    900: Color(0xFF271827),  // Almost black with warm undertone
    950: Color(0xFF120712),  // True black with subtle warm undertone
  });*/

  // Updated neutral pallette with no tone
  static const MaterialColor neutral = MaterialColor(0xFF222222, {
    50:  Color(0xFFFFFFFF),
    100: Color(0xFFFFFFFF),
    200: Color(0xFFFBFBFB),
    250: Color(0xFFF2F2F2),
    300: Color(0xFFE8E8E8),
    400: Color(0xFFB6B6B6),
    500: Color(0xFF7A7A7A),
    600: Color(0xFF646464),
    700: Color(0xFF545454),
    800: Color(0xFF373737),
    900: Color(0xFF222222), // Pure neutral target
    950: Color(0xFF0D0D0D),
  });

  /// Primary color - Coral/Salmon red
  /*static const MaterialColor primary = MaterialColor(0xFFFF595E, {
    50: Color(0xFFFFF1F1),   // Lightest tint
    100: Color(0xFFFFE1E2),  // Very light
    200: Color(0xFFFFC7C9),  // Light
    300: Color(0xFFF99A9E),  // Light medium
    400: Color(0xFFFF6469),  // Medium light
    500: Color(0xFFFF595E),  // Base (current primary)
    600: Color(0xFFED3338),  // Medium dark
    700: Color(0xFFC92428),  // Dark
    800: Color(0xFFA52322),  // Darker
    900: Color(0xFF8A2522),  // Darkest
  });*/

  static const MaterialColor primary = MaterialColor(0xFFF27405, {
    50:  Color(0xFFFFF4E8), // Very pale cream
    100: Color(0xFFFFE6CC), // Soft apricot
    150: Color(0xFFFFD7B3), // Light peach (extra step)
    200: Color(0xFFFFBF80), // Muted orange
    300: Color(0xFFFF9F40), // Bright pumpkin
    400: Color(0xFFFF861A), // Vivid orange
    500: Color(0xFFF27405), // Base (bold orange)
    600: Color(0xFFD36204), // Burnt orange
    700: Color(0xFFAA4E03), // Deep amber
    800: Color(0xFF803B02), // Dark umber
    900: Color(0xFF552801), // Almost black brown-orange
  });










  /// Secondary color - Teal/Cyan
  static const MaterialColor secondary = MaterialColor(0xFF03DAC6, {
    50: Color(0xFFE0F7FA),   // Lightest
    100: Color(0xFFB2EBF2),  // Very light
    200: Color(0xFF80DEEA),  // Light
    300: Color(0xFF4DD0E1),  // Light medium
    400: Color(0xFF26C6DA),  // Medium light
    500: Color(0xFF03DAC6),  // Base (current secondary)
    600: Color(0xFF00ACC1),  // Medium dark
    700: Color(0xFF0097A7),  // Dark
    800: Color(0xFF00838F),  // Darker
    900: Color(0xFF006064),  // Darkest
  });

  /// Accent color - Pink/Magenta (used for focus states)
  static const MaterialColor accent = MaterialColor(0xFFE91E63, {
    50: Color(0xFFFCE4EC),   // Lightest
    100: Color(0xFFF8BBD0),  // Very light
    200: Color(0xFFF48FB1),  // Light
    300: Color(0xFFF06292),  // Light medium
    400: Color(0xFFEC407A),  // Medium light
    500: Color(0xFFE91E63),  // Base (current focus color)
    600: Color(0xFFD81B60),  // Medium dark
    700: Color(0xFFC2185B),  // Dark
    800: Color(0xFFAD1457),  // Darker
    900: Color(0xFF880E4F),  // Darkest
  });

  /// Info/Blue color palette
  static const MaterialColor info = MaterialColor(0xFF1565C0, {
    50: Color(0xFFE3F2FD),   // Lightest (chip background)
    100: Color(0xFFBBDEFB),  // Very light
    200: Color(0xFF90CAF9),  // Light
    300: Color(0xFF64B5F6),  // Light medium
    400: Color(0xFF42A5F5),  // Medium light
    500: Color(0xFF2196F3),  // Base blue
    600: Color(0xFF1E88E5),  // Medium dark
    700: Color(0xFF1976D2),  // Dark
    800: Color(0xFF1565C0),  // Darker (chip text)
    900: Color(0xFF0D47A1),  // Darkest
  });

  static const MaterialColor surface = MaterialColor(0xFFD9BCA3, {
    50:  Color(0xFFFCF9F7), // Almost white, warm tint
    75:  Color(0xFFF9F4F3), // Midpoint between 50 & 100 (new step)
    100: Color(0xFFF6EFE9), // Very pale beige
    150: Color(0xFFEFE4DB), // Soft cream
    200: Color(0xFFE6D7C9), // Light sand
    300: Color(0xFFE0CCBB), // Pale tan
    400: Color(0xFFDCC3AF), // Muted beige
    500: Color(0xFFD9BCA3), // Base surface (warm sandy beige)
    600: Color(0xFFC3A68F), // Medium beige-brown
    700: Color(0xFFA68974), // Warm taupe
    800: Color(0xFF876C5B), // Dark taupe / mocha
    900: Color(0xFF5E4A3C), // Rich brown
  });


  /// Success/Green color palette
  static const MaterialColor success = MaterialColor(0xFF10B981, {
    50: Color(0xFFECFDF5),   // Lightest
    100: Color(0xFFD1FAE5),  // Very light
    200: Color(0xFFA7F3D0),  // Light
    300: Color(0xFF6EE7B7),  // Light medium
    400: Color(0xFF34D399),  // Medium light
    500: Color(0xFF10B981),  // Base green
    600: Color(0xFF059669),  // Medium dark
    700: Color(0xFF047857),  // Dark
    800: Color(0xFF065F46),  // Darker
    900: Color(0xFF064E3B),  // Darkest
  });

  /// Warning/Yellow color palette
  static const MaterialColor warning = MaterialColor(0xFFF59E0B, {
    50: Color(0xFFFFFBEB),   // Lightest
    100: Color(0xFFFEF3C7),  // Very light
    200: Color(0xFFFDE68A),  // Light
    300: Color(0xFFFCD34D),  // Light medium
    400: Color(0xFFFBBF24),  // Medium light
    500: Color(0xFFF59E0B),  // Base yellow
    600: Color(0xFFD97706),  // Medium dark
    700: Color(0xFFB45309),  // Dark
    800: Color(0xFF92400E),  // Darker
    900: Color(0xFF78350F),  // Darkest
  });

  /// Error/Red color palette
  static const MaterialColor error = MaterialColor(0xFFDC2626, {
    50: Color(0xFFFEF2F2),   // Lightest
    100: Color(0xFFFEE2E2),  // Very light
    200: Color(0xFFFECACA),  // Light
    300: Color(0xFFFCA5A5),  // Light medium
    400: Color(0xFFF87171),  // Medium light
    500: Color(0xFFEF4444),  // Base error
    600: Color(0xFFDC2626),  // Current error color
    700: Color(0xFFB91C1C),  // Dark
    800: Color(0xFF991B1B),  // Darker
    900: Color(0xFF7F1D1D),  // Darkest
  });
}

/// Theme-aware color resolution.
///
/// This class provides semantic color getters that automatically adapt
/// to the current theme brightness (light/dark mode).
class AppColors {
  final Brightness brightness;

  const AppColors({required this.brightness});

  /// Factory constructor from BuildContext
  factory AppColors.of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return AppColors(brightness: brightness);
  }

  // Background colors
  Color get background => brightness == Brightness.light
      ? Colors.white  // #FFFFFF - better hierarchy, was neutral[50]
      : const Color(0xFF121212);  // True Material Design dark, was neutral[900]

  Color get input => brightness == Brightness.light
      ? AppColorSwatches.neutral[250]!
      : AppColorSwatches.neutral[800]!;

  Color get surface => brightness == Brightness.light
      ? const Color(0xFFFAFAFA)  // Very light gray for cards/inputs, was Colors.white
      : const Color(0xFF1F1F1F);  // Warmer dark gray, was neutral[800]

  Color get surfaceVariant => brightness == Brightness.light
      ? AppColorSwatches.neutral[100]!
      : AppColorSwatches.neutral[700]!;

  // Primary colors
  Color get primary => brightness == Brightness.light
      ? AppColorSwatches.primary[500]!
      : AppColorSwatches.primary[400]!;

  Color get primaryVariant => brightness == Brightness.light
      ? AppColorSwatches.primary[700]!
      : AppColorSwatches.primary[300]!;

  Color get onPrimary => brightness == Brightness.light
      ? Colors.white
      : AppColorSwatches.neutral[900]!;

  // Secondary colors
  Color get secondary => brightness == Brightness.light
      ? AppColorSwatches.secondary[500]!
      : AppColorSwatches.secondary[400]!;

  Color get onSecondary => brightness == Brightness.light
      ? AppColorSwatches.neutral[900]!
      : AppColorSwatches.neutral[900]!;

  // Text colors
  Color get textPrimary => brightness == Brightness.light
      ? AppColorSwatches.neutral[900]!
      : AppColorSwatches.neutral[50]!;

  Color get textSecondary => brightness == Brightness.light
      ? AppColorSwatches.neutral[600]!
      : AppColorSwatches.neutral[300]!;

  Color get textTertiary => brightness == Brightness.light
      ? AppColorSwatches.neutral[500]!
      : AppColorSwatches.neutral[400]!;

  Color get textDisabled => brightness == Brightness.light
      ? AppColorSwatches.neutral[400]!
      : AppColorSwatches.neutral[600]!;

  // Heading colors for visual hierarchy
  Color get headingPrimary => textPrimary;  // Main headings (same as textPrimary)

  Color get headingSecondary => brightness == Brightness.light
      ? AppColorSwatches.neutral[800]!  // #373737 - slightly lighter than textPrimary
      : AppColorSwatches.neutral[200]!;  // #FBFBFB - slightly darker than textPrimary

  // Border colors
  Color get border => brightness == Brightness.light
      ? AppColorSwatches.neutral[200]!
      : AppColorSwatches.neutral[700]!;

  Color get borderStrong => brightness == Brightness.light
      ? AppColorSwatches.neutral[300]!
      : AppColorSwatches.neutral[600]!;

  // Focus and interaction states
  Color get focus => brightness == Brightness.light
      ? AppColorSwatches.accent[500]!
      : AppColorSwatches.accent[400]!;

  Color get hover => brightness == Brightness.light
      ? AppColorSwatches.neutral[100]!
      : AppColorSwatches.neutral[700]!;

  Color get pressed => brightness == Brightness.light
      ? AppColorSwatches.neutral[200]!
      : AppColorSwatches.neutral[600]!;

  // Semantic colors
  Color get error => brightness == Brightness.light
      ? AppColorSwatches.error[600]!
      : AppColorSwatches.error[400]!;

  Color get errorBackground => brightness == Brightness.light
      ? AppColorSwatches.error[50]!
      : AppColorSwatches.error[900]!.withOpacity(0.15);

  Color get success => brightness == Brightness.light
      ? AppColorSwatches.success[600]!
      : AppColorSwatches.success[400]!;

  Color get successBackground => brightness == Brightness.light
      ? AppColorSwatches.success[50]!
      : AppColorSwatches.success[900]!.withOpacity(0.15);

  Color get warning => brightness == Brightness.light
      ? AppColorSwatches.warning[600]!
      : AppColorSwatches.warning[400]!;

  Color get warningBackground => brightness == Brightness.light
      ? AppColorSwatches.warning[50]!
      : AppColorSwatches.warning[900]!.withOpacity(0.15);

  Color get info => brightness == Brightness.light
      ? AppColorSwatches.info[700]!
      : AppColorSwatches.info[300]!;

  Color get infoBackground => brightness == Brightness.light
      ? AppColorSwatches.info[50]!
      : AppColorSwatches.info[900]!.withOpacity(0.15);

  // Chip colors (for duration picker, etc.)
  Color get chipBackground => brightness == Brightness.light
      ? AppColorSwatches.primary[100]!
      : AppColorSwatches.primary[900]!.withOpacity(0.15);

  Color get chipText => brightness == Brightness.light
      ? AppColorSwatches.primary[700]!
      : AppColorSwatches.primary[300]!;

  // Button specific colors
  Color get buttonPrimary => brightness == Brightness.light
      ? AppColorSwatches.neutral[900]!
      : AppColorSwatches.neutral[50]!;

  Color get buttonPrimaryHover => brightness == Brightness.light
      ? AppColorSwatches.neutral[700]!
      : AppColorSwatches.neutral[200]!;

  Color get buttonPrimaryPressed => brightness == Brightness.light
      ? AppColorSwatches.neutral[600]!
      : AppColorSwatches.neutral[300]!;

  Color get onButtonPrimary => brightness == Brightness.light
      ? Colors.white
      : AppColorSwatches.neutral[900]!;

  // Input field colors
  Color get inputBackground => brightness == Brightness.light
      ? Colors.white
      : AppColorSwatches.neutral[800]!;

  Color get inputBackgroundFilled => brightness == Brightness.light
      ? AppColorSwatches.neutral[100]!
      : AppColorSwatches.neutral[700]!;

  Color get inputPlaceholder => brightness == Brightness.light
      ? AppColorSwatches.neutral[400]!
      : AppColorSwatches.neutral[500]!;

  Color get inputLabel => brightness == Brightness.light
      ? AppColorSwatches.neutral[500]!
      : AppColorSwatches.neutral[400]!;

  // Content text colors (for list items, descriptions, user-generated content)
  Color get contentPrimary => textPrimary;  // Main content text (ingredient names, step descriptions)

  Color get contentSecondary => textSecondary;  // Supporting content (section headers in lists)

  Color get contentHint => inputPlaceholder;  // Content placeholder hints ('e.g. 1 cup flour')

  // UI text colors (for interface elements, form controls, navigation)
  Color get uiLabel => inputLabel;  // Form field labels, button labels

  Color get uiSecondary => textTertiary;  // Secondary interface elements (drag handles)

  Color get uiHint => inputPlaceholder;  // Form field placeholders ('Enter value')
}
