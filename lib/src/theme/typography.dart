import 'package:flutter/material.dart';

/// Semantic typography system for consistent text styling across the app.
///
/// This class provides a centralized set of text styles that align with
/// design system semantics (h1, h2, etc.) while maintaining consistency
/// with existing app patterns.
class AppTypography {
  // Headings - for page titles, section headers, and content hierarchy
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
    fontFamily: 'Inter',
    color: Color(0xFF1D2129),
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.2,
    fontFamily: 'Inter',
    color: Color(0xFF1D2129),
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    fontFamily: 'Inter',
    color: Color(0xFF1D2129),
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
    height: 1.3,
    fontFamily: 'Inter',
    color: Color(0xFF1D2129),
  );

  static const TextStyle h5 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    fontFamily: 'Inter',
    color: Color(0xFF1D2129),
  );

  // Body text - for main content and readable text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    fontFamily: 'Inter',
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    height: 1.5,
    fontFamily: 'Inter',
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.4,
    fontFamily: 'Inter',
  );

  // UI text - for form inputs, labels, and interface elements
  static const TextStyle input = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.4,
    fontFamily: 'Inter',
  );

  static const TextStyle label = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.2,
    fontFamily: 'Inter',
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.3,
    fontFamily: 'Inter',
  );

  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.5,
    fontFamily: 'Inter',
  );

  // Form-specific styles - for text field components
  static const TextStyle fieldInput = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    fontFamily: 'Inter',
  );

  static const TextStyle fieldLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w300,
    height: 1.2,
    fontFamily: 'Inter',
  );

  static const TextStyle fieldError = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.3,
    fontFamily: 'Inter',
  );

  static const TextStyle fieldHelper = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.3,
    fontFamily: 'Inter',
  );
}
