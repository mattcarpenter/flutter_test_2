import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/src/features/import_export/services/parsers/stockpot_parser.dart';

void main() {
  late StockpotParser parser;

  setUp(() {
    parser = StockpotParser();
  });

  group('StockpotParser', () {
    test('has correct supported extensions', () {
      expect(parser.supportedExtensions, equals(['.zip']));
    });

    test('parses valid single recipe JSON', () {
      final jsonFile = File('test/fixtures/import/stockpot/minimal_recipe.json');
      final bytes = jsonFile.readAsBytesSync();

      final recipe = parser.parseRecipe(bytes, 'minimal_recipe.json');

      expect(recipe.title, equals('Minimal Test Recipe'));
      expect(recipe.description, equals('A minimal valid recipe for testing import/export'));
      expect(recipe.rating, equals(4));
      expect(recipe.language, equals('en'));
      expect(recipe.servings, equals(2));
      expect(recipe.prepTime, equals(10));
      expect(recipe.cookTime, equals(20));
      expect(recipe.totalTime, equals(30));
      expect(recipe.source, equals('test.example.com'));
      expect(recipe.nutrition, equals('Per serving: 200 calories'));
      expect(recipe.generalNotes, equals('Test notes for the recipe'));
      expect(recipe.pinned, equals(false));
      expect(recipe.folderNames, equals(['Test Folder']));
      expect(recipe.tagNames, equals(['test-tag']));
      expect(recipe.ingredients?.length, equals(2));
      expect(recipe.steps?.length, equals(2));
      expect(recipe.images, equals([]));
    });

    test('parses recipe ingredients correctly', () {
      final jsonFile = File('test/fixtures/import/stockpot/minimal_recipe.json');
      final bytes = jsonFile.readAsBytesSync();

      final recipe = parser.parseRecipe(bytes, 'minimal_recipe.json');

      final firstIngredient = recipe.ingredients![0];
      expect(firstIngredient.type, equals('ingredient'));
      expect(firstIngredient.name, equals('2 cups flour'));
      expect(firstIngredient.note, equals('all-purpose'));
      expect(firstIngredient.isCanonicalised, equals(true));
      expect(firstIngredient.category, equals('baking'));
      expect(firstIngredient.terms?.length, equals(1));
      expect(firstIngredient.terms![0].value, equals('flour'));
      expect(firstIngredient.terms![0].source, equals('ai'));
      expect(firstIngredient.terms![0].sort, equals(0));
    });

    test('parses recipe steps correctly', () {
      final jsonFile = File('test/fixtures/import/stockpot/minimal_recipe.json');
      final bytes = jsonFile.readAsBytesSync();

      final recipe = parser.parseRecipe(bytes, 'minimal_recipe.json');

      final firstStep = recipe.steps![0];
      expect(firstStep.type, equals('step'));
      expect(firstStep.text, equals('Mix flour and salt together'));
      expect(firstStep.note, isNull);
      expect(firstStep.timerDurationSeconds, isNull);

      final secondStep = recipe.steps![1];
      expect(secondStep.type, equals('step'));
      expect(secondStep.text, equals('Cook for 20 minutes'));
      expect(secondStep.note, equals('until golden brown'));
      expect(secondStep.timerDurationSeconds, equals(1200));
    });

    test('handles malformed JSON gracefully', () {
      final malformedJson = '{"title": "Test", invalid json}'.codeUnits;

      expect(
        () => parser.parseRecipe(malformedJson, 'malformed.json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('handles empty JSON object gracefully', () {
      // Missing required 'title' field
      final emptyJson = '{}'.codeUnits;

      expect(
        () => parser.parseRecipe(emptyJson, 'empty.json'),
        throwsA(anything),
      );
    });
  });
}
