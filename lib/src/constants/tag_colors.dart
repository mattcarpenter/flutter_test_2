import 'package:flutter/material.dart';

/// Constants for tag color palette and utilities
class TagColors {
  static const List<Color> palette = [
    Color(0xFF4285F4), // Blue
    Color(0xFF34A853), // Green  
    Color(0xFFEA4335), // Red
    Color(0xFFFBBC04), // Yellow
    Color(0xFF9C27B0), // Purple
    Color(0xFFFF9800), // Orange
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF795548), // Brown
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF3F51B5), // Indigo
  ];
  
  static const Color defaultColor = Color(0xFF4285F4);
  
  /// Get the display name for a color value
  static String getColorName(Color color) {
    switch (color.value) {
      case 0xFF4285F4: return 'Blue';
      case 0xFF34A853: return 'Green';
      case 0xFFEA4335: return 'Red';
      case 0xFFFBBC04: return 'Yellow';
      case 0xFF9C27B0: return 'Purple';
      case 0xFFFF9800: return 'Orange';
      case 0xFF607D8B: return 'Blue Grey';
      case 0xFF795548: return 'Brown';
      case 0xFFE91E63: return 'Pink';
      case 0xFF00BCD4: return 'Cyan';
      case 0xFF009688: return 'Teal';
      case 0xFF3F51B5: return 'Indigo';
      default: return 'Custom';
    }
  }
  
  /// Convert a hex color string to Color object
  static Color fromHex(String hexString) {
    // Remove # if present and add alpha channel if not present
    final cleanHex = hexString.replaceFirst('#', '');
    final hex = cleanHex.length == 6 ? 'FF$cleanHex' : cleanHex;
    return Color(int.parse(hex, radix: 16));
  }
  
  /// Convert a Color object to hex string
  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}