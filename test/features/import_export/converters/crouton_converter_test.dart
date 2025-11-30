import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/src/features/import_export/models/crouton_recipe.dart';
import 'package:recipe_app/src/features/import_export/services/converters/crouton_converter.dart';

void main() {
  group('CroutonConverter', () {
    late CroutonConverter converter;

    setUp(() {
      converter = CroutonConverter();
    });

    test('converts complete recipe with all fields', () {
      final croutonRecipe = CroutonRecipe(
        uuid: '550e8400-e29b-41d4-a716-446655440000',
        name: 'Chocolate Chip Cookies',
        serves: 24,
        duration: 900, // 15 minutes in seconds
        cookingDuration: 720, // 12 minutes in seconds
        defaultScale: 1.0,
        webLink: 'https://example.com/cookies',
        notes: 'Best enjoyed warm',
        nutritionalInfo: 'Calories: 150 per cookie',
        ingredients: [
          CroutonIngredient(
            uuid: 'ing1',
            order: 0,
            ingredient: CroutonIngredientInfo(
              uuid: 'inginfo1',
              name: 'flour',
            ),
            quantity: CroutonQuantity(
              amount: 2.5,
              quantityType: 'CUP',
            ),
          ),
          CroutonIngredient(
            uuid: 'ing2',
            order: 1,
            ingredient: CroutonIngredientInfo(
              uuid: 'inginfo2',
              name: 'butter',
            ),
            quantity: CroutonQuantity(
              amount: 1,
              quantityType: 'CUP',
            ),
          ),
          CroutonIngredient(
            uuid: 'ing3',
            order: 2,
            ingredient: CroutonIngredientInfo(
              uuid: 'inginfo3',
              name: 'eggs',
            ),
            quantity: CroutonQuantity(
              amount: 2,
              quantityType: 'ITEM',
            ),
          ),
        ],
        steps: [
          CroutonStep(
            uuid: 'step1',
            order: 0,
            step: 'Preparation',
            isSection: true,
          ),
          CroutonStep(
            uuid: 'step2',
            order: 1,
            step: 'Mix flour and butter together',
            isSection: false,
          ),
          CroutonStep(
            uuid: 'step3',
            order: 2,
            step: 'Add eggs and mix well',
            isSection: false,
          ),
        ],
        images: [
          'base64image1==',
          'base64image2==',
        ],
        tags: ['dessert', 'cookies', 'baking'],
        folderIDs: ['folder1', 'folder2'], // Should be ignored
        isPublicRecipe: false,
      );

      final imported = converter.convert(croutonRecipe);

      expect(imported.title, 'Chocolate Chip Cookies');
      expect(imported.description, null);
      expect(imported.rating, null);
      expect(imported.language, null);
      expect(imported.servings, 24);
      expect(imported.prepTime, 15);
      expect(imported.cookTime, 12);
      expect(imported.totalTime, 27);
      expect(imported.source, 'https://example.com/cookies');
      expect(imported.nutrition, 'Calories: 150 per cookie');
      expect(imported.generalNotes, 'Best enjoyed warm');
      expect(imported.pinned, false);
      expect(imported.tagNames, ['dessert', 'cookies', 'baking']);
      expect(imported.folderNames, isEmpty); // Folder IDs ignored

      // Check ingredients
      expect(imported.ingredients.length, 3);
      expect(imported.ingredients[0].type, 'ingredient');
      expect(imported.ingredients[0].name, '2.5 cup flour');
      expect(imported.ingredients[0].isCanonicalised, false);
      expect(imported.ingredients[1].name, '1 cup butter');
      expect(imported.ingredients[2].name, '2 eggs'); // ITEM has no unit

      // Check steps
      expect(imported.steps.length, 3);
      expect(imported.steps[0].type, 'section');
      expect(imported.steps[0].text, 'Preparation');
      expect(imported.steps[1].type, 'step');
      expect(imported.steps[1].text, 'Mix flour and butter together');
      expect(imported.steps[2].type, 'step');

      // Check images
      expect(imported.images.length, 2);
      expect(imported.images[0].isCover, true); // First image is cover
      expect(imported.images[0].data, 'base64image1==');
      expect(imported.images[1].isCover, false);
      expect(imported.images[1].data, 'base64image2==');
    });

    test('converts recipe with minimal fields', () {
      final croutonRecipe = CroutonRecipe(
        uuid: '550e8400-e29b-41d4-a716-446655440000',
        name: 'Simple Recipe',
      );

      final imported = converter.convert(croutonRecipe);

      expect(imported.title, 'Simple Recipe');
      expect(imported.servings, null);
      expect(imported.prepTime, null);
      expect(imported.cookTime, null);
      expect(imported.totalTime, null);
      expect(imported.ingredients, isEmpty);
      expect(imported.steps, isEmpty);
      expect(imported.images, isEmpty);
      expect(imported.tagNames, isEmpty);
    });

    test('maps Crouton units correctly', () {
      final ingredients = [
        _makeIngredient('flour', 2, 'CUP'),
        _makeIngredient('vanilla', 1, 'TABLESPOON'),
        _makeIngredient('salt', 0.5, 'TEASPOON'),
        _makeIngredient('sugar', 200, 'GRAM'),
        _makeIngredient('butter', 0.5, 'KILOGRAM'),
        _makeIngredient('chocolate', 8, 'OUNCE'),
        _makeIngredient('cheese', 1, 'POUND'),
        _makeIngredient('milk', 250, 'MILLILITER'),
        _makeIngredient('water', 1, 'LITER'),
        _makeIngredient('spice', 1, 'PINCH'),
        _makeIngredient('eggs', 3, 'ITEM'),
      ];

      final croutonRecipe = CroutonRecipe(
        uuid: 'test',
        name: 'Test',
        ingredients: ingredients,
      );

      final imported = converter.convert(croutonRecipe);

      expect(imported.ingredients[0].name, '2 cup flour');
      expect(imported.ingredients[1].name, '1 tbsp vanilla');
      expect(imported.ingredients[2].name, '0.5 tsp salt');
      expect(imported.ingredients[3].name, '200 g sugar');
      expect(imported.ingredients[4].name, '0.5 kg butter');
      expect(imported.ingredients[5].name, '8 oz chocolate');
      expect(imported.ingredients[6].name, '1 lb cheese');
      expect(imported.ingredients[7].name, '250 ml milk');
      expect(imported.ingredients[8].name, '1 l water');
      expect(imported.ingredients[9].name, '1 pinch spice');
      expect(imported.ingredients[10].name, '3 eggs'); // No unit for ITEM
    });

    test('formats amounts nicely', () {
      final ingredients = [
        _makeIngredient('flour', 2.0, 'CUP'), // Whole number
        _makeIngredient('sugar', 1.5, 'CUP'), // Decimal
        _makeIngredient('salt', 0.5, 'TEASPOON'), // Decimal
      ];

      final croutonRecipe = CroutonRecipe(
        uuid: 'test',
        name: 'Test',
        ingredients: ingredients,
      );

      final imported = converter.convert(croutonRecipe);

      expect(imported.ingredients[0].name, '2 cup flour'); // Not "2.0"
      expect(imported.ingredients[1].name, '1.5 cup sugar');
      expect(imported.ingredients[2].name, '0.5 tsp salt');
    });

    test('handles ingredients without quantity', () {
      final croutonRecipe = CroutonRecipe(
        uuid: 'test',
        name: 'Test',
        ingredients: [
          CroutonIngredient(
            uuid: 'ing1',
            order: 0,
            ingredient: CroutonIngredientInfo(
              uuid: 'inginfo1',
              name: 'salt to taste',
            ),
            quantity: null, // No quantity
          ),
        ],
      );

      final imported = converter.convert(croutonRecipe);

      expect(imported.ingredients.length, 1);
      expect(imported.ingredients[0].name, 'salt to taste');
    });

    test('handles ingredients without amount in quantity', () {
      final croutonRecipe = CroutonRecipe(
        uuid: 'test',
        name: 'Test',
        ingredients: [
          CroutonIngredient(
            uuid: 'ing1',
            order: 0,
            ingredient: CroutonIngredientInfo(
              uuid: 'inginfo1',
              name: 'eggs',
            ),
            quantity: CroutonQuantity(
              amount: null,
              quantityType: 'ITEM',
            ),
          ),
        ],
      );

      final imported = converter.convert(croutonRecipe);

      expect(imported.ingredients.length, 1);
      expect(imported.ingredients[0].name, 'eggs');
    });

    test('skips ingredients without ingredient info', () {
      final croutonRecipe = CroutonRecipe(
        uuid: 'test',
        name: 'Test',
        ingredients: [
          CroutonIngredient(
            uuid: 'ing1',
            order: 0,
            ingredient: null, // No ingredient info
            quantity: CroutonQuantity(amount: 2, quantityType: 'CUP'),
          ),
          CroutonIngredient(
            uuid: 'ing2',
            order: 1,
            ingredient: CroutonIngredientInfo(uuid: 'info2', name: 'flour'),
            quantity: CroutonQuantity(amount: 2, quantityType: 'CUP'),
          ),
        ],
      );

      final imported = converter.convert(croutonRecipe);

      expect(imported.ingredients.length, 1);
      expect(imported.ingredients[0].name, '2 cup flour');
    });

    test('converts seconds to minutes correctly', () {
      final testCases = [
        CroutonRecipe(uuid: '1', name: 'Test 1', duration: 900), // 15 min
        CroutonRecipe(uuid: '2', name: 'Test 2', duration: 1800), // 30 min
        CroutonRecipe(uuid: '3', name: 'Test 3', duration: 3600), // 60 min
        CroutonRecipe(uuid: '4', name: 'Test 4', duration: 75), // 1.25 min -> rounds to 1
        CroutonRecipe(uuid: '5', name: 'Test 5', duration: 0), // null
        CroutonRecipe(uuid: '6', name: 'Test 6'), // null
      ];

      final expected = [15, 30, 60, 1, null, null];

      for (var i = 0; i < testCases.length; i++) {
        final imported = converter.convert(testCases[i]);
        expect(
          imported.prepTime,
          expected[i],
          reason: 'Failed for: ${testCases[i].duration} seconds',
        );
      }
    });

    test('calculates total time from prep and cook', () {
      final croutonRecipe = CroutonRecipe(
        uuid: 'test',
        name: 'Test',
        duration: 600, // 10 min prep
        cookingDuration: 1200, // 20 min cook
      );

      final imported = converter.convert(croutonRecipe);

      expect(imported.prepTime, 10);
      expect(imported.cookTime, 20);
      expect(imported.totalTime, 30);
    });

    test('marks all ingredients as not canonicalized', () {
      final croutonRecipe = CroutonRecipe(
        uuid: 'test',
        name: 'Test',
        ingredients: [
          _makeIngredient('flour', 2, 'CUP'),
          _makeIngredient('sugar', 1, 'CUP'),
        ],
      );

      final imported = converter.convert(croutonRecipe);

      for (final ingredient in imported.ingredients) {
        expect(ingredient.isCanonicalised, false);
      }
    });

    test('handles unknown quantity types', () {
      final croutonRecipe = CroutonRecipe(
        uuid: 'test',
        name: 'Test',
        ingredients: [
          CroutonIngredient(
            uuid: 'ing1',
            order: 0,
            ingredient: CroutonIngredientInfo(uuid: 'info1', name: 'mystery'),
            quantity: CroutonQuantity(amount: 5, quantityType: 'UNKNOWN_UNIT'),
          ),
        ],
      );

      final imported = converter.convert(croutonRecipe);

      expect(imported.ingredients.length, 1);
      expect(imported.ingredients[0].name, '5 mystery'); // No unit
    });
  });
}

// Helper function to create test ingredients
CroutonIngredient _makeIngredient(String name, double amount, String unit) {
  return CroutonIngredient(
    uuid: 'ing-$name',
    order: 0,
    ingredient: CroutonIngredientInfo(
      uuid: 'info-$name',
      name: name,
    ),
    quantity: CroutonQuantity(
      amount: amount,
      quantityType: unit,
    ),
  );
}
