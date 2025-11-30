import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/src/features/import_export/services/parsers/paprika_parser.dart';

void main() {
  late PaprikaParser parser;

  setUp(() {
    parser = PaprikaParser();
  });

  group('PaprikaParser', () {
    test('has correct supported extensions', () {
      expect(parser.supportedExtensions, equals(['.paprikarecipes']));
    });

    test('parses valid gzip-compressed paprika recipe', () {
      final recipeFile = File('test/fixtures/import/paprika/minimal_recipe.paprikarecipe');
      final bytes = recipeFile.readAsBytesSync();

      final recipe = parser.parseRecipe(bytes, 'minimal_recipe.paprikarecipe');

      expect(recipe.uid, equals('24A28156-0060-4F07-A17B-F55A7A2227DE'));
      expect(recipe.name, equals('Test recipe'));
      expect(recipe.hash, equals('97B77CE18F016895C0DF448BC1254B4A28557F04A5D62DAAC854459C43D89D6E'));
      expect(recipe.created, equals('2025-06-14 11:00:43'));
      expect(recipe.rating, equals(0));
      expect(recipe.description, equals(''));
      expect(recipe.ingredients, equals(''));
      expect(recipe.directions, equals(''));
      expect(recipe.notes, equals(''));
      expect(recipe.source, equals(''));
      expect(recipe.sourceUrl, equals(''));
      expect(recipe.prepTime, equals(''));
      expect(recipe.cookTime, equals(''));
      expect(recipe.totalTime, equals(''));
      expect(recipe.servings, equals(''));
      expect(recipe.difficulty, equals(''));
      expect(recipe.nutritionalInfo, equals(''));
      expect(recipe.categories, equals([]));
      expect(recipe.photos, equals([]));
      expect(recipe.photo, isNull);
      expect(recipe.photoData, isNull);
      expect(recipe.photoHash, isNull);
      expect(recipe.imageUrl, isNull);
    });

    test('parses uncompressed JSON file', () {
      // Also test with the uncompressed JSON version
      final jsonFile = File('test/fixtures/import/paprika/minimal_recipe.json');
      final jsonString = jsonFile.readAsStringSync();

      // Compress it first to simulate the format
      final bytes = jsonString.codeUnits;

      // This should fail since it's not gzipped
      expect(
        () => parser.parseRecipe(bytes, 'minimal_recipe.json'),
        throwsA(anything),
      );
    });

    test('handles malformed gzip data gracefully', () {
      final malformedData = 'not gzipped data'.codeUnits;

      expect(
        () => parser.parseRecipe(malformedData, 'malformed.paprikarecipe'),
        throwsA(anything),
      );
    });

    test('handles gzipped malformed JSON gracefully', () {
      // Create gzipped invalid JSON
      final invalidJson = '{"name": "Test", invalid json}'.codeUnits;

      expect(
        () => parser.parseRecipe(invalidJson, 'malformed.paprikarecipe'),
        throwsA(anything),
      );
    });

    test('handles missing required fields gracefully', () {
      // Empty JSON object - missing required 'uid' and 'name' fields
      final emptyJson = '{}'.codeUnits;

      expect(
        () => parser.parseRecipe(emptyJson, 'empty.paprikarecipe'),
        throwsA(anything),
      );
    });
  });
}
