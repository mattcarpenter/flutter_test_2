import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/src/services/ingredient_parser_service.dart';
import 'package:recipe_app/src/widgets/ingredient_text_editing_controller.dart';

void main() {
  late IngredientTextEditingController controller;
  late IngredientParserService parser;

  setUp(() {
    parser = IngredientParserService();
    controller = IngredientTextEditingController(parser: parser);
  });

  tearDown(() {
    controller.dispose();
  });

  group('IngredientTextEditingController', () {
    test('returns plain TextSpan for empty text', () {
      controller.text = '';
      
      final span = controller.buildTextSpan(
        context: _MockContext(),
        style: const TextStyle(),
        withComposing: false,
      );
      
      expect(span.text, '');
      expect(span.children, isNull);
    });

    test('returns plain TextSpan for text without quantities', () {
      controller.text = 'vanilla extract';
      
      final span = controller.buildTextSpan(
        context: _MockContext(),
        style: const TextStyle(),
        withComposing: false,
      );
      
      expect(span.text, 'vanilla extract');
      expect(span.children, isNull);
    });

    test('highlights quantities in blue for simple quantity', () {
      controller.text = '1 cup flour';
      
      final span = controller.buildTextSpan(
        context: _MockContext(),
        style: const TextStyle(),
        withComposing: false,
      );
      
      expect(span.children, isNotNull);
      expect(span.children!.length, 2);
      
      // First child should be the quantity in blue
      final quantitySpan = span.children![0] as TextSpan;
      expect(quantitySpan.text, '1 cup');
      expect(quantitySpan.style?.color, Colors.blue.shade700);
      
      // Second child should be the ingredient name in default color
      final nameSpan = span.children![1] as TextSpan;
      expect(nameSpan.text, ' flour');
      expect(nameSpan.style?.color, isNull);
    });

    test('highlights multiple quantities', () {
      controller.text = '1 cup flour + 2 tbsp sugar';
      
      final span = controller.buildTextSpan(
        context: _MockContext(),
        style: const TextStyle(),
        withComposing: false,
      );
      
      expect(span.children, isNotNull);
      expect(span.children!.length, 4);
      
      // First quantity
      expect((span.children![0] as TextSpan).text, '1 cup');
      expect((span.children![0] as TextSpan).style?.color, Colors.blue.shade700);
      
      // Text between
      expect((span.children![1] as TextSpan).text, ' flour + ');
      expect((span.children![1] as TextSpan).style?.color, isNull);
      
      // Second quantity
      expect((span.children![2] as TextSpan).text, '2 tbsp');
      expect((span.children![2] as TextSpan).style?.color, Colors.blue.shade700);
      
      // Remaining text
      expect((span.children![3] as TextSpan).text, ' sugar');
      expect((span.children![3] as TextSpan).style?.color, isNull);
    });

    test('handles approximate quantities', () {
      controller.text = 'salt to taste';
      
      final span = controller.buildTextSpan(
        context: _MockContext(),
        style: const TextStyle(),
        withComposing: false,
      );
      
      expect(span.children, isNotNull);
      expect(span.children!.length, 2);
      
      // Ingredient name
      expect((span.children![0] as TextSpan).text, 'salt');
      expect((span.children![0] as TextSpan).style?.color, isNull);
      
      // Approximate quantity
      expect((span.children![1] as TextSpan).text, ' to taste');
      expect((span.children![1] as TextSpan).style?.color, Colors.blue.shade700);
    });

    test('uses caching to avoid re-parsing same text', () {
      controller.text = '1 cup flour';
      
      // First call
      final span1 = controller.buildTextSpan(
        context: _MockContext(),
        style: const TextStyle(),
        withComposing: false,
      );
      
      // Second call with same text should use cache
      final span2 = controller.buildTextSpan(
        context: _MockContext(),
        style: const TextStyle(),
        withComposing: false,
      );
      
      expect(span1.children!.length, equals(span2.children!.length));
      expect((span1.children![0] as TextSpan).text, 
             equals((span2.children![0] as TextSpan).text));
    });

    test('highlights bare numbers', () {
      controller.text = '2 onions';
      
      final span = controller.buildTextSpan(
        context: _MockContext(),
        style: const TextStyle(),
        withComposing: false,
      );
      
      expect(span.children, isNotNull);
      expect(span.children!.length, 2);
      
      // First child should be the bare number in blue
      final quantitySpan = span.children![0] as TextSpan;
      expect(quantitySpan.text, '2');
      expect(quantitySpan.style?.color, Colors.blue.shade700);
      
      // Second child should be the ingredient name in default color
      final nameSpan = span.children![1] as TextSpan;
      expect(nameSpan.text, ' onions');
      expect(nameSpan.style?.color, isNull);
    });

    test('highlights Unicode fractions', () {
      controller.text = '½ cup flour';
      
      final span = controller.buildTextSpan(
        context: _MockContext(),
        style: const TextStyle(),
        withComposing: false,
      );
      
      expect(span.children, isNotNull);
      expect(span.children!.length, 2);
      
      // First child should be the Unicode fraction quantity in blue
      final quantitySpan = span.children![0] as TextSpan;
      expect(quantitySpan.text, '½ cup');
      expect(quantitySpan.style?.color, Colors.blue.shade700);
      
      // Second child should be the ingredient name in default color
      final nameSpan = span.children![1] as TextSpan;
      expect(nameSpan.text, ' flour');
      expect(nameSpan.style?.color, isNull);
    });

    test('highlights bare Unicode fractions', () {
      controller.text = '¼ onion';
      
      final span = controller.buildTextSpan(
        context: _MockContext(),
        style: const TextStyle(),
        withComposing: false,
      );
      
      expect(span.children, isNotNull);
      expect(span.children!.length, 2);
      
      // First child should be the bare Unicode fraction in blue
      final quantitySpan = span.children![0] as TextSpan;
      expect(quantitySpan.text, '¼');
      expect(quantitySpan.style?.color, Colors.blue.shade700);
      
      // Second child should be the ingredient name in default color
      final nameSpan = span.children![1] as TextSpan;
      expect(nameSpan.text, ' onion');
      expect(nameSpan.style?.color, isNull);
    });

    test('gracefully handles parsing errors', () {
      // Create a controller with a mock parser that throws
      final throwingParser = _ThrowingParser();
      final throwingController = IngredientTextEditingController(parser: throwingParser);
      
      throwingController.text = '1 cup flour';
      
      final span = throwingController.buildTextSpan(
        context: _MockContext(),
        style: const TextStyle(),
        withComposing: false,
      );
      
      // Should fallback to plain text
      expect(span.text, '1 cup flour');
      expect(span.children, isNull);
      
      throwingController.dispose();
    });
  });
}

class _MockContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ThrowingParser implements IngredientParserService {
  @override
  IngredientParseResult parse(String input) {
    throw Exception('Test exception');
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}