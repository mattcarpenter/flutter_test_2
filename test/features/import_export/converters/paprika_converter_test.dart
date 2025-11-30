import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/src/features/import_export/models/paprika_recipe.dart';
import 'package:recipe_app/src/features/import_export/services/converters/paprika_converter.dart';

void main() {
  group('PaprikaConverter', () {
    late PaprikaConverter converter;

    setUp(() {
      converter = PaprikaConverter();
    });

    test('converts complete recipe with all fields', () {
      final paprikaRecipe = PaprikaRecipe(
        uid: '12345',
        name: 'Pasta Carbonara',
        description: 'Classic Italian pasta dish',
        ingredients: '''
PASTA
1 lb spaghetti
SAUCE
4 eggs
1 cup parmesan cheese, grated
8 oz pancetta, diced''',
        directions: '''
1. Cook pasta according to package directions.
2. Meanwhile, cook pancetta until crispy.
3. Beat eggs with cheese.
4. Toss hot pasta with pancetta and egg mixture.''',
        notes: 'Best served immediately',
        source: 'Italian Cookbook',
        sourceUrl: 'https://example.com/recipe',
        prepTime: '10 mins',
        cookTime: '20 minutes',
        totalTime: '30 min',
        servings: '4 servings',
        rating: 5,
        nutritionalInfo: 'Calories: 450 per serving',
        categories: ['Pasta', 'Italian', 'Dinner'],
        photoData: 'base64encodedimage==',
        photos: [
          PaprikaPhoto(
            filename: 'step1.jpg',
            data: 'base64step1==',
          ),
        ],
        created: '2021-01-15T10:30:00Z',
      );

      final imported = converter.convert(paprikaRecipe);

      expect(imported.title, 'Pasta Carbonara');
      expect(imported.description, 'Classic Italian pasta dish');
      expect(imported.rating, 5);
      expect(imported.servings, 4);
      expect(imported.prepTime, 10);
      expect(imported.cookTime, 20);
      expect(imported.totalTime, 30);
      expect(imported.source, 'Italian Cookbook');
      expect(imported.nutrition, 'Calories: 450 per serving');
      expect(imported.generalNotes, 'Best served immediately');
      expect(imported.createdAt, isNotNull);
      expect(imported.pinned, false);
      expect(imported.tagNames, ['Pasta', 'Italian', 'Dinner']);
      expect(imported.folderNames, isEmpty);

      // Check ingredients parsing
      expect(imported.ingredients.length, 6);
      expect(imported.ingredients[0].type, 'section');
      expect(imported.ingredients[0].name, 'PASTA');
      expect(imported.ingredients[1].type, 'ingredient');
      expect(imported.ingredients[1].name, '1 lb spaghetti');
      expect(imported.ingredients[1].isCanonicalised, false);
      expect(imported.ingredients[2].type, 'section');
      expect(imported.ingredients[2].name, 'SAUCE');
      expect(imported.ingredients[3].type, 'ingredient');
      expect(imported.ingredients[3].name, '4 eggs');

      // Check steps parsing
      expect(imported.steps.length, 4);
      expect(imported.steps[0].type, 'step');
      expect(imported.steps[0].text, 'Cook pasta according to package directions.');
      expect(imported.steps[1].text, 'Meanwhile, cook pancetta until crispy.');

      // Check images
      expect(imported.images.length, 2);
      expect(imported.images[0].isCover, true);
      expect(imported.images[0].data, 'base64encodedimage==');
      expect(imported.images[1].isCover, false);
      expect(imported.images[1].data, 'base64step1==');
    });

    test('converts recipe with minimal fields', () {
      final paprikaRecipe = PaprikaRecipe(
        uid: '12345',
        name: 'Simple Recipe',
      );

      final imported = converter.convert(paprikaRecipe);

      expect(imported.title, 'Simple Recipe');
      expect(imported.description, null);
      expect(imported.rating, null);
      expect(imported.ingredients, isEmpty);
      expect(imported.steps, isEmpty);
      expect(imported.images, isEmpty);
    });

    test('parses time strings correctly', () {
      final testCases = [
        PaprikaRecipe(uid: '1', name: 'Test 1', prepTime: '15 mins'),
        PaprikaRecipe(uid: '2', name: 'Test 2', prepTime: '1 hour'),
        PaprikaRecipe(uid: '3', name: 'Test 3', prepTime: '1 hr 30 min'),
        PaprikaRecipe(uid: '4', name: 'Test 4', prepTime: '2 hours 15 minutes'),
        PaprikaRecipe(uid: '5', name: 'Test 5', prepTime: '45 min'),
        PaprikaRecipe(uid: '6', name: 'Test 6', prepTime: ''),
        PaprikaRecipe(uid: '7', name: 'Test 7'),
      ];

      final expected = [15, 60, 90, 135, 45, null, null];

      for (var i = 0; i < testCases.length; i++) {
        final imported = converter.convert(testCases[i]);
        expect(
          imported.prepTime,
          expected[i],
          reason: 'Failed for: ${testCases[i].prepTime}',
        );
      }
    });

    test('parses servings correctly', () {
      final testCases = [
        PaprikaRecipe(uid: '1', name: 'Test 1', servings: '4 servings'),
        PaprikaRecipe(uid: '2', name: 'Test 2', servings: '2'),
        PaprikaRecipe(uid: '3', name: 'Test 3', servings: 'Serves 6'),
        PaprikaRecipe(uid: '4', name: 'Test 4', servings: ''),
        PaprikaRecipe(uid: '5', name: 'Test 5'),
      ];

      final expected = [4, 2, 6, null, null];

      for (var i = 0; i < testCases.length; i++) {
        final imported = converter.convert(testCases[i]);
        expect(
          imported.servings,
          expected[i],
          reason: 'Failed for: ${testCases[i].servings}',
        );
      }
    });

    test('parses directions with different formats', () {
      // Numbered format
      final numbered = PaprikaRecipe(
        uid: '1',
        name: 'Test',
        directions: '1. First step\n2. Second step\n3. Third step',
      );
      var imported = converter.convert(numbered);
      expect(imported.steps.length, 3);
      expect(imported.steps[0].text, 'First step');

      // Paragraph format
      final paragraphs = PaprikaRecipe(
        uid: '2',
        name: 'Test',
        directions: 'First step paragraph.\n\nSecond step paragraph.\n\nThird step.',
      );
      imported = converter.convert(paragraphs);
      expect(imported.steps.length, 3);

      // Single line format
      final singleLine = PaprikaRecipe(
        uid: '3',
        name: 'Test',
        directions: 'First step\nSecond step\nThird step',
      );
      imported = converter.convert(singleLine);
      expect(imported.steps.length, 3);
    });

    test('identifies section headers correctly', () {
      final paprikaRecipe = PaprikaRecipe(
        uid: '1',
        name: 'Test',
        ingredients: '''
FOR THE DOUGH:
2 cups flour
For the filling:
1 cup cheese
regular ingredient
TOPPING''',
      );

      final imported = converter.convert(paprikaRecipe);

      expect(imported.ingredients[0].type, 'section'); // FOR THE DOUGH:
      expect(imported.ingredients[1].type, 'ingredient'); // 2 cups flour
      expect(imported.ingredients[2].type, 'section'); // For the filling:
      expect(imported.ingredients[3].type, 'ingredient'); // 1 cup cheese
      expect(imported.ingredients[4].type, 'ingredient'); // regular ingredient
      expect(imported.ingredients[5].type, 'section'); // TOPPING (all caps)
    });

    test('uses source URL as fallback for source', () {
      final withBoth = PaprikaRecipe(
        uid: '1',
        name: 'Test',
        source: 'Cookbook',
        sourceUrl: 'https://example.com',
      );
      var imported = converter.convert(withBoth);
      expect(imported.source, 'Cookbook');

      final urlOnly = PaprikaRecipe(
        uid: '2',
        name: 'Test',
        sourceUrl: 'https://example.com',
      );
      imported = converter.convert(urlOnly);
      expect(imported.source, 'https://example.com');
    });

    test('marks all ingredients as not canonicalized', () {
      final paprikaRecipe = PaprikaRecipe(
        uid: '1',
        name: 'Test',
        ingredients: '2 cups flour\n1 tsp salt\n3 eggs',
      );

      final imported = converter.convert(paprikaRecipe);

      for (final ingredient in imported.ingredients) {
        expect(ingredient.isCanonicalised, false);
      }
    });

    test('handles empty ingredients and directions', () {
      final paprikaRecipe = PaprikaRecipe(
        uid: '1',
        name: 'Test',
        ingredients: '',
        directions: '',
      );

      final imported = converter.convert(paprikaRecipe);

      expect(imported.ingredients, isEmpty);
      expect(imported.steps, isEmpty);
    });

    test('parses ISO 8601 created date', () {
      final paprikaRecipe = PaprikaRecipe(
        uid: '1',
        name: 'Test',
        created: '2021-01-15T10:30:00Z',
      );

      final imported = converter.convert(paprikaRecipe);

      expect(imported.createdAt, isNotNull);
      final date = DateTime.fromMillisecondsSinceEpoch(imported.createdAt!);
      expect(date.year, 2021);
      expect(date.month, 1);
      expect(date.day, 15);
    });
  });
}
