import 'dart:io';
import 'package:flutter/material.dart';

/// Semantic typography system for consistent text styling across the app.
///
/// This class provides a centralized set of text styles that align with
/// design system semantics (h1, h2, etc.) while maintaining consistency
/// with existing app patterns.
///
/// Platform-aware implementation:
/// - iOS: Uses San Francisco (SF Pro) system font with w600 weights
/// - Other platforms: Uses Inter font with appropriate fallbacks
class AppTypography {
  // Platform-aware font configuration
  static String? get _fontFamily => Platform.isIOS ? null : 'Inter'; // null = system font on iOS
  static FontWeight get _boldWeight => Platform.isIOS ? FontWeight.w600 : FontWeight.bold;
  static FontWeight get _semiBoldWeight => FontWeight.w600;
  static FontWeight get _mediumWeight => FontWeight.w500;
  static double? get _letterSpacing => Platform.isIOS ? -0.41 : 0; // SF Pro handles spacing automatically
  // Headings - for page titles, section headers, and content hierarchy
  static TextStyle get h1 => TextStyle(
    fontSize: 28,
    fontWeight: _boldWeight,
    height: Platform.isIOS ? 1.3 : 1.2, // iOS needs slightly more line height
    fontFamily: _fontFamily,
    letterSpacing: _letterSpacing,
    color: const Color(0xFF1D2129),
  );

  static TextStyle get h2 => TextStyle(
    fontSize: 24,
    fontWeight: _boldWeight,
    height: Platform.isIOS ? 1.3 : 1.2,
    fontFamily: _fontFamily,
    letterSpacing: _letterSpacing,
    color: const Color(0xFF1D2129),
  );

  static TextStyle get h3 => TextStyle(
    fontSize: 20,
    fontWeight: _semiBoldWeight,
    height: Platform.isIOS ? 1.4 : 1.3,
    fontFamily: _fontFamily,
    letterSpacing: _letterSpacing,
    color: const Color(0xFF1D2129),
  );

  static TextStyle get h4 => TextStyle(
    fontSize: 18,
    fontWeight: _boldWeight,
    height: Platform.isIOS ? 1.4 : 1.3,
    fontFamily: _fontFamily,
    letterSpacing: _letterSpacing,
    color: const Color(0xFF1D2129),
  );

  static TextStyle get h5 => TextStyle(
    fontSize: 16,
    fontWeight: _semiBoldWeight,
    height: Platform.isIOS ? 1.5 : 1.4,
    fontFamily: _fontFamily,
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
    fontSize: 12,
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

  // Form-specific styles - for text field components
  static TextStyle get fieldInput => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: Platform.isIOS ? 1.6 : 1.5,
    fontFamily: _fontFamily,
    letterSpacing: _letterSpacing,
  );

  static TextStyle get fieldLabel => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w300,
    height: Platform.isIOS ? 1.3 : 1.2,
    fontFamily: _fontFamily,
    letterSpacing: _letterSpacing,
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
