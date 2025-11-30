import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/src/features/import_export/services/parsers/crouton_parser.dart';

void main() {
  late CroutonParser parser;

  setUp(() {
    parser = CroutonParser();
  });

  group('CroutonParser', () {
    test('has correct supported extensions', () {
      expect(parser.supportedExtensions, equals(['.zip']));
    });

    test('parses valid crouton recipe', () {
      final crumbFile = File('test/fixtures/import/crouton/minimal_recipe.crumb');
      final bytes = crumbFile.readAsBytesSync();

      final recipe = parser.parseRecipe(bytes, 'minimal_recipe.crumb');

      expect(recipe.uuid, equals('2D679F46-2C93-435E-9B9D-5603C37D321B'));
      expect(recipe.name, equals('test'));
      expect(recipe.serves, equals(4));
      expect(recipe.duration, equals(254));
      expect(recipe.cookingDuration, equals(424));
      expect(recipe.defaultScale, equals(1.0));
      expect(recipe.webLink, equals('HTTPS://www.google.com'));
      expect(recipe.notes, equals('Notes'));
      expect(recipe.nutritionalInfo, equals('Nutrition'));
      expect(recipe.isPublicRecipe, equals(false));
      expect(recipe.folderIDs, equals([]));
      expect(recipe.tags, equals([]));
      expect(recipe.images, equals([]));
      expect(recipe.ingredients?.length, equals(3));
      expect(recipe.steps?.length, equals(3));
    });

    test('parses recipe ingredients correctly', () {
      final crumbFile = File('test/fixtures/import/crouton/minimal_recipe.crumb');
      final bytes = crumbFile.readAsBytesSync();

      final recipe = parser.parseRecipe(bytes, 'minimal_recipe.crumb');

      final firstIngredient = recipe.ingredients![0];
      expect(firstIngredient.uuid, equals('DD8EAFBB-574C-4CD8-B7C7-B139ACA96B98'));
      expect(firstIngredient.order, equals(0));
      expect(firstIngredient.ingredient?.uuid, equals('491B1100-9425-4D63-ABE3-1A3823DC9B85'));
      expect(firstIngredient.ingredient?.name, equals('Apples'));
      expect(firstIngredient.quantity?.amount, equals(2.0));
      expect(firstIngredient.quantity?.quantityType, equals('ITEM'));

      final secondIngredient = recipe.ingredients![1];
      expect(secondIngredient.ingredient?.name, equals('onions'));
      expect(secondIngredient.quantity?.amount, equals(4.0));
      expect(secondIngredient.quantity?.quantityType, equals('ITEM'));

      final thirdIngredient = recipe.ingredients![2];
      expect(thirdIngredient.ingredient?.name, equals('Test 4'));
      expect(thirdIngredient.quantity?.amount, equals(0.0));
      expect(thirdIngredient.quantity?.quantityType, equals('RECIPE'));
    });

    test('parses recipe steps correctly', () {
      final crumbFile = File('test/fixtures/import/crouton/minimal_recipe.crumb');
      final bytes = crumbFile.readAsBytesSync();

      final recipe = parser.parseRecipe(bytes, 'minimal_recipe.crumb');

      expect(recipe.steps?.length, equals(3));

      final firstStep = recipe.steps![0];
      expect(firstStep.uuid, equals('F6388464-09FC-46C6-8FB6-75E1FB7BF6FA'));
      expect(firstStep.order, equals(0));
      expect(firstStep.step, equals('Test'));
      expect(firstStep.isSection, equals(false));

      final secondStep = recipe.steps![1];
      expect(secondStep.uuid, equals('62998948-155B-47B8-8FB7-C961A7CB2E4D'));
      expect(secondStep.order, equals(1));
      expect(secondStep.step, equals('Test'));
      expect(secondStep.isSection, equals(false));
    });

    test('handles malformed JSON gracefully', () {
      final malformedJson = '{"name": "Test", invalid json}'.codeUnits;

      expect(
        () => parser.parseRecipe(malformedJson, 'malformed.crumb'),
        throwsA(isA<FormatException>()),
      );
    });

    test('handles empty JSON object gracefully', () {
      // Missing required 'uuid' and 'name' fields
      final emptyJson = '{}'.codeUnits;

      expect(
        () => parser.parseRecipe(emptyJson, 'empty.crumb'),
        throwsA(anything),
      );
    });

    test('handles missing required fields gracefully', () {
      // Only uuid, missing required 'name' field
      final partialJson = '{"uuid": "test-uuid"}'.codeUnits;

      expect(
        () => parser.parseRecipe(partialJson, 'partial.crumb'),
        throwsA(anything),
      );
    });
  });
}
