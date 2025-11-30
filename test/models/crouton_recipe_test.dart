import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/src/features/import_export/models/crouton_recipe.dart';

void main() {
  group('CroutonRecipe', () {
    test('parses complete Crouton JSON correctly', () {
      final jsonString = '''
      {
        "uuid": "test-uuid-123",
        "name": "Test Recipe",
        "serves": 4,
        "duration": 900,
        "cookingDuration": 1200,
        "defaultScale": 1,
        "webLink": "https://example.com",
        "notes": "Test notes",
        "neutritionalInfo": "Nutrition info",
        "ingredients": [
          {
            "uuid": "ingredient-uuid-1",
            "order": 0,
            "ingredient": {
              "uuid": "salt-uuid",
              "name": "Salt"
            },
            "quantity": {
              "amount": 1,
              "quantityType": "TABLESPOON"
            }
          }
        ],
        "steps": [
          {
            "uuid": "step-uuid-1",
            "order": 0,
            "step": "Mix ingredients",
            "isSection": false
          }
        ],
        "images": ["base64-string-1", "base64-string-2"],
        "tags": ["dinner", "quick"],
        "folderIDs": ["folder-uuid-1"],
        "isPublicRecipe": false
      }
      ''';

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final recipe = CroutonRecipe.fromJson(json);

      expect(recipe.uuid, 'test-uuid-123');
      expect(recipe.name, 'Test Recipe');
      expect(recipe.serves, 4);
      expect(recipe.duration, 900);
      expect(recipe.cookingDuration, 1200);
      expect(recipe.defaultScale, 1);
      expect(recipe.webLink, 'https://example.com');
      expect(recipe.notes, 'Test notes');
      expect(recipe.nutritionalInfo, 'Nutrition info');
      expect(recipe.ingredients?.length, 1);
      expect(recipe.steps?.length, 1);
      expect(recipe.images?.length, 2);
      expect(recipe.tags?.length, 2);
      expect(recipe.folderIDs?.length, 1);
      expect(recipe.isPublicRecipe, false);
    });

    test('parses minimal Crouton JSON correctly', () {
      final jsonString = '''
      {
        "uuid": "minimal-uuid",
        "name": "Minimal Recipe"
      }
      ''';

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final recipe = CroutonRecipe.fromJson(json);

      expect(recipe.uuid, 'minimal-uuid');
      expect(recipe.name, 'Minimal Recipe');
      expect(recipe.serves, null);
      expect(recipe.ingredients, null);
      expect(recipe.steps, null);
    });

    test('handles neutritionalInfo typo correctly', () {
      final jsonString = '''
      {
        "uuid": "test-uuid",
        "name": "Test Recipe",
        "neutritionalInfo": "Contains vitamins"
      }
      ''';

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final recipe = CroutonRecipe.fromJson(json);

      expect(recipe.nutritionalInfo, 'Contains vitamins');
    });

    test('parses ingredient with all fields', () {
      final jsonString = '''
      {
        "uuid": "ingredient-uuid",
        "order": 5,
        "ingredient": {
          "uuid": "flour-uuid",
          "name": "Flour"
        },
        "quantity": {
          "amount": 2.5,
          "quantityType": "CUP"
        }
      }
      ''';

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final ingredient = CroutonIngredient.fromJson(json);

      expect(ingredient.uuid, 'ingredient-uuid');
      expect(ingredient.order, 5);
      expect(ingredient.ingredient?.name, 'Flour');
      expect(ingredient.ingredient?.uuid, 'flour-uuid');
      expect(ingredient.quantity?.amount, 2.5);
      expect(ingredient.quantity?.quantityType, 'CUP');
    });

    test('parses step with isSection flag', () {
      final jsonString = '''
      {
        "uuid": "step-uuid",
        "order": 0,
        "step": "Preparation",
        "isSection": true
      }
      ''';

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final step = CroutonStep.fromJson(json);

      expect(step.uuid, 'step-uuid');
      expect(step.order, 0);
      expect(step.step, 'Preparation');
      expect(step.isSection, true);
    });

    test('roundtrip JSON serialization', () {
      final original = CroutonRecipe(
        uuid: 'roundtrip-uuid',
        name: 'Roundtrip Recipe',
        serves: 2,
        duration: 600,
      );

      final json = original.toJson();
      final parsed = CroutonRecipe.fromJson(json);

      expect(parsed.uuid, original.uuid);
      expect(parsed.name, original.name);
      expect(parsed.serves, original.serves);
      expect(parsed.duration, original.duration);
    });
  });
}
