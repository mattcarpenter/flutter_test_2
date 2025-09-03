import 'package:flutter/material.dart';
import '../services/ingredient_parser_service.dart';

/// Custom TextEditingController that provides real-time syntax highlighting
/// for ingredient strings, coloring quantities differently from ingredient names.
class IngredientTextEditingController extends TextEditingController {
  final IngredientParserService _parser;
  
  // Enhanced caching with language awareness
  String? _lastText;
  Language? _lastLanguage;
  List<QuantitySpan>? _lastQuantities;
  
  IngredientTextEditingController({
    required IngredientParserService parser,
    String? text,
  }) : _parser = parser, super(text: text);

  @override
  TextSpan buildTextSpan({
    required BuildContext context, 
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    
    if (text.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }
    
    try {
      // Detect language for current text
      final currentLanguage = _parser.detectLanguage(text);
      
      // Use cached result if text and language haven't changed
      List<QuantitySpan> quantities;
      if (text == _lastText && currentLanguage == _lastLanguage && _lastQuantities != null) {
        quantities = _lastQuantities!;
      } else {
        final parseResult = _parser.parse(text);
        quantities = parseResult.quantities;
        _lastText = text;
        _lastLanguage = currentLanguage;
        _lastQuantities = quantities;
      }
      
      if (quantities.isEmpty) {
        return TextSpan(text: text, style: baseStyle);
      }
      
      final children = <TextSpan>[];
      int currentIndex = 0;
      
      // Build TextSpan with blue quantities, black ingredient names
      for (final quantity in quantities) {
        // Text before quantity (ingredient name)
        if (quantity.start > currentIndex) {
          children.add(TextSpan(
            text: text.substring(currentIndex, quantity.start),
            style: baseStyle,
          ));
        }
        
        // Quantity with blue color
        children.add(TextSpan(
          text: text.substring(quantity.start, quantity.end),
          style: baseStyle.copyWith(color: Colors.blue.shade700, fontWeight: FontWeight.w500),
        ));
        
        currentIndex = quantity.end;
      }
      
      // Remaining text after last quantity
      if (currentIndex < text.length) {
        children.add(TextSpan(
          text: text.substring(currentIndex),
          style: baseStyle,
        ));
      }
      
      return TextSpan(children: children);
    } catch (e) {
      // Fallback to unstyled text if parsing fails
      debugPrint('Error parsing ingredient text: $e');
      return TextSpan(text: text, style: baseStyle);
    }
  }
  
  @override
  void dispose() {
    _lastText = null;
    _lastLanguage = null;
    _lastQuantities = null;
    super.dispose();
  }
}