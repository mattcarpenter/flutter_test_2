import 'dart:io';
import 'package:flutter/material.dart';

/// Semantic typography system for consistent text styling across the app.
///
/// This class provides a centralized set of text styles that align with
/// design system semantics (h1, h2, etc.) while maintaining consistency
/// with existing app patterns.
///
/// Platform-aware implementation:
/// - iOS: Uses SF Rounded for headings, SF Pro for body text, w600 weights
/// - Other platforms: Uses Inter font with appropriate fallbacks
class AppTypography {
  // Platform-aware font configuration
  static String? get _fontFamily => Platform.isIOS ? null : 'Inter'; // null = system font on iOS
  static String? get _headingFontFamily => Platform.isIOS ? 'SF Pro Rounded' : 'Inter'; // SF Rounded for iOS headings
  static String? get _headingFontFamilyAlternate => 'Playfair Display'; // Custom font for headings on all platforms
  static String? get _buttonFontFamily => Platform.isIOS ? 'SF Pro Rounded' : 'Inter';
  static FontWeight get _boldWeight => Platform.isIOS ? FontWeight.w700 : FontWeight.bold;
  static FontWeight get _semiBoldWeight => FontWeight.w600;
  static FontWeight get _mediumWeight => FontWeight.w500;
  static double? get _letterSpacing => Platform.isIOS ? -0.41 : 0; // SF Pro handles spacing automatically
  // Headings - for page titles, section headers, and content hierarchy (SF Pro Rounded)
  static TextStyle get h1 => TextStyle(
    fontSize: 32,
    fontWeight: _boldWeight,
    height: Platform.isIOS ? 1.3 : 1.2, // iOS needs slightly more line height
    fontFamily: _headingFontFamily,
    letterSpacing: _letterSpacing,
    color: const Color(0xFF1D2129),
  );

  static TextStyle get h2 => TextStyle(
    fontSize: 22,
    fontWeight: _mediumWeight,
    height: Platform.isIOS ? 1.3 : 1.2,
    fontFamily: _headingFontFamily,
    letterSpacing: _letterSpacing,
    color: const Color(0xFF1D2129),
  );

  static TextStyle get h3 => TextStyle(
    fontSize: 20,
    fontWeight: _semiBoldWeight,
    height: Platform.isIOS ? 1.4 : 1.3,
    fontFamily: _headingFontFamily,
    letterSpacing: 0.36,
    color: const Color(0xFF1D2129),
  );

  static TextStyle get h4 => TextStyle(
    fontSize: 18,
    fontWeight: _boldWeight,
    height: Platform.isIOS ? 1.4 : 1.3,
    fontFamily: _headingFontFamily,
    letterSpacing: 0.37,
    color: const Color(0xFF1D2129),
  );

  // Serif headings - for editorial content and section titles (Playfair Display)
  static TextStyle get h1Serif => TextStyle(
    fontSize: 32,
    fontWeight: _boldWeight,
    height: Platform.isIOS ? 1.3 : 1.2,
    fontFamily: _headingFontFamilyAlternate,
    letterSpacing: _letterSpacing,
    color: const Color(0xFF1D2129),
  );

  static TextStyle get h2Serif => TextStyle(
    fontSize: 18,
    fontWeight: _boldWeight,
    height: Platform.isIOS ? 1.3 : 1.2,
    fontFamily: _headingFontFamily,
    color: const Color(0xFF1D2129),
  );

  static TextStyle get h3Serif => TextStyle(
    fontSize: 20,
    fontWeight: _semiBoldWeight,
    height: Platform.isIOS ? 1.4 : 1.3,
    fontFamily: _headingFontFamilyAlternate,
    color: const Color(0xFF1D2129),
  );

  static TextStyle get h4Serif => TextStyle(
    fontSize: 18,
    fontWeight: _boldWeight,
    height: Platform.isIOS ? 1.4 : 1.3,
    fontFamily: _headingFontFamilyAlternate,
    color: const Color(0xFF1D2129),
  );

  static TextStyle get h5 => TextStyle(
    fontSize: 16,
    fontWeight: _semiBoldWeight,
    height: Platform.isIOS ? 1.5 : 1.4,
    fontFamily: _headingFontFamily,
    letterSpacing: _letterSpacing,
    color: const Color(0xFF1D2129),
  );

  // Body text - for main content and readable text
  static TextStyle get bodyLarge => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: Platform.isIOS ? 1.6 : 1.5,
    fontFamily: _fontFamily,
    letterSpacing: _letterSpacing,
  );

  static TextStyle get body => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    height: Platform.isIOS ? 1.6 : 1.5,
    fontFamily: _fontFamily,
    letterSpacing: _letterSpacing,
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: Platform.isIOS ? 1.5 : 1.4,
    fontFamily: _fontFamily,
    letterSpacing: _letterSpacing,
  );

  // UI text - for form inputs, labels, and interface elements
  static TextStyle get input => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: Platform.isIOS ? 1.5 : 1.4,
    fontFamily: _fontFamily,
    letterSpacing: _letterSpacing,
  );

  static TextStyle get label => TextStyle(
    fontSize: 16,
    fontWeight: _mediumWeight,
    height: Platform.isIOS ? 1.3 : 1.2,
    fontFamily: _fontFamily,
    letterSpacing: _letterSpacing,
  );

  static TextStyle get caption => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    height: Platform.isIOS ? 1.4 : 1.3,
    fontFamily: _fontFamily,
    letterSpacing: _letterSpacing,
  );

  static TextStyle get overline => TextStyle(
    fontSize: 11,
    fontWeight: _mediumWeight,
    height: Platform.isIOS ? 1.4 : 1.3,
    fontFamily: _fontFamily,
    letterSpacing: Platform.isIOS ? null : 0.5, // iOS handles spacing
  );

  // Section label - for uppercase category labels with tracked letters
  static TextStyle get sectionLabel => TextStyle(
    fontSize: 13,
    fontWeight: _semiBoldWeight,
    letterSpacing: 0.9,
    fontFamily: _fontFamily,
    color: const Color(0xFF7A7A7A), // neutral[500]
  );

  // Button text - for button labels and call-to-action text
  static TextStyle get button => TextStyle(
    fontSize: 16, // Will be overridden by AppButton's dynamic sizing
    fontWeight: _boldWeight,
    height: 1,
    fontFamily: _buttonFontFamily,
    letterSpacing: 0.41,
  );

  // Form-specific styles - for text field components
  static TextStyle get fieldInput => TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: Platform.isIOS ? 1.6 : 1.5,
    fontFamily: _fontFamily,
    letterSpacing: -0.31,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static TextStyle get fieldLabel => TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: Platform.isIOS ? 1.3 : 1.2,
    fontFamily: _fontFamily,
    letterSpacing: -0.31,
  );

  static TextStyle get fieldError => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: Platform.isIOS ? 1.4 : 1.3,
    fontFamily: _fontFamily,
    letterSpacing: _letterSpacing,
  );

  static TextStyle get fieldHelper => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: Platform.isIOS ? 1.4 : 1.3,
    fontFamily: _fontFamily,
    letterSpacing: _letterSpacing,
  );
}
