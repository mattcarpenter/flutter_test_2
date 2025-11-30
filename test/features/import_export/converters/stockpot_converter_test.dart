import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/src/features/import_export/models/export_recipe.dart';
import 'package:recipe_app/src/features/import_export/services/converters/stockpot_converter.dart';

void main() {
  group('StockpotConverter', () {
    late StockpotConverter converter;

    setUp(() {
      converter = StockpotConverter();
    });

    test('converts complete recipe with all fields', () {
      final exportRecipe = ExportRecipe(
        title: 'Test Recipe',
        description: 'A delicious test recipe',
        rating: 5,
        language: 'en',
        servings: 4,
        prepTime: 15,
        cookTime: 30,
        totalTime: 45,
        source: 'Test Source',
        nutrition: 'Calories: 200',
        generalNotes: 'Some notes',
        createdAt: 1609459200000, // 2021-01-01
        updatedAt: 1640995200000, // 2022-01-01
        pinned: true,
        tagNames: ['dinner', 'vegetarian'],
        folderNames: ['Main Dishes', 'Favorites'],
        ingredients: [
          ExportIngredient(
            type: 'section',
            name: 'For the sauce',
          ),
          ExportIngredient(
            type: 'ingredient',
            name: '2 cups tomatoes',
            note: 'diced',
            terms: [
              ExportIngredientTerm(
                value: 'tomato',
                source: 'ai',
                sort: 0,
              ),
            ],
            isCanonicalised: true,
            category: 'vegetables',
          ),
        ],
        steps: [
          ExportStep(
            type: 'section',
            text: 'Preparation',
          ),
          ExportStep(
            type: 'step',
            text: 'Dice the tomatoes',
            note: 'Make sure they are ripe',
          ),
          ExportStep(
            type: 'timer',
            text: 'Simmer for 10 minutes',
            timerDurationSeconds: 600,
          ),
        ],
        images: [
          ExportImage(
            isCover: true,
            publicUrl: 'https://example.com/image.jpg',
          ),
          ExportImage(
            isCover: false,
            data: 'base64data==',
          ),
        ],
      );

      final imported = converter.convert(exportRecipe);

      expect(imported.title, 'Test Recipe');
      expect(imported.description, 'A delicious test recipe');
      expect(imported.rating, 5);
      expect(imported.language, 'en');
      expect(imported.servings, 4);
      expect(imported.prepTime, 15);
      expect(imported.cookTime, 30);
      expect(imported.totalTime, 45);
      expect(imported.source, 'Test Source');
      expect(imported.nutrition, 'Calories: 200');
      expect(imported.generalNotes, 'Some notes');
      expect(imported.createdAt, 1609459200000);
      expect(imported.updatedAt, 1640995200000);
      expect(imported.pinned, true);
      expect(imported.tagNames, ['dinner', 'vegetarian']);
      expect(imported.folderNames, ['Main Dishes', 'Favorites']);

      // Check ingredients
      expect(imported.ingredients.length, 2);
      expect(imported.ingredients[0].type, 'section');
      expect(imported.ingredients[0].name, 'For the sauce');
      expect(imported.ingredients[1].type, 'ingredient');
      expect(imported.ingredients[1].name, '2 cups tomatoes');
      expect(imported.ingredients[1].note, 'diced');
      expect(imported.ingredients[1].isCanonicalised, true);
      expect(imported.ingredients[1].category, 'vegetables');
      expect(imported.ingredients[1].terms!.length, 1);
      expect(imported.ingredients[1].terms![0].value, 'tomato');
      expect(imported.ingredients[1].terms![0].source, 'ai');
      expect(imported.ingredients[1].terms![0].sort, 0);

      // Check steps
      expect(imported.steps.length, 3);
      expect(imported.steps[0].type, 'section');
      expect(imported.steps[0].text, 'Preparation');
      expect(imported.steps[1].type, 'step');
      expect(imported.steps[1].text, 'Dice the tomatoes');
      expect(imported.steps[1].note, 'Make sure they are ripe');
      expect(imported.steps[2].type, 'timer');
      expect(imported.steps[2].text, 'Simmer for 10 minutes');
      expect(imported.steps[2].timerDurationSeconds, 600);

      // Check images
      expect(imported.images.length, 2);
      expect(imported.images[0].isCover, true);
      expect(imported.images[0].publicUrl, 'https://example.com/image.jpg');
      expect(imported.images[1].isCover, false);
      expect(imported.images[1].data, 'base64data==');
    });

    test('converts recipe with minimal fields', () {
      final exportRecipe = ExportRecipe(
        title: 'Minimal Recipe',
      );

      final imported = converter.convert(exportRecipe);

      expect(imported.title, 'Minimal Recipe');
      expect(imported.description, null);
      expect(imported.rating, null);
      expect(imported.servings, null);
      expect(imported.pinned, false);
      expect(imported.tagNames, isEmpty);
      expect(imported.folderNames, isEmpty);
      expect(imported.ingredients, isEmpty);
      expect(imported.steps, isEmpty);
      expect(imported.images, isEmpty);
    });

    test('converts multiple recipes', () {
      final recipes = [
        ExportRecipe(title: 'Recipe 1'),
        ExportRecipe(title: 'Recipe 2'),
        ExportRecipe(title: 'Recipe 3'),
      ];

      final imported = converter.convertAll(recipes);

      expect(imported.length, 3);
      expect(imported[0].title, 'Recipe 1');
      expect(imported[1].title, 'Recipe 2');
      expect(imported[2].title, 'Recipe 3');
    });

    test('handles null pinned as false', () {
      final exportRecipe = ExportRecipe(
        title: 'Test',
        pinned: null,
      );

      final imported = converter.convert(exportRecipe);

      expect(imported.pinned, false);
    });

    test('preserves canonicalization status', () {
      final exportRecipe = ExportRecipe(
        title: 'Test',
        ingredients: [
          ExportIngredient(
            type: 'ingredient',
            name: 'flour',
            isCanonicalised: true,
          ),
          ExportIngredient(
            type: 'ingredient',
            name: 'sugar',
            isCanonicalised: false,
          ),
          ExportIngredient(
            type: 'ingredient',
            name: 'salt',
            // null isCanonicalised
          ),
        ],
      );

      final imported = converter.convert(exportRecipe);

      expect(imported.ingredients[0].isCanonicalised, true);
      expect(imported.ingredients[1].isCanonicalised, false);
      expect(imported.ingredients[2].isCanonicalised, false);
    });
  });
}
