import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/src/services/content_extraction/json_ld_parser.dart';

void main() {
  group('JsonLdRecipeParser ingredient normalization', () {
    late JsonLdRecipeParser parser;

    setUp(() {
      parser = JsonLdRecipeParser();
    });

    // Helper to test ingredient normalization via a minimal JSON-LD structure
    List<String> parseIngredients(List<String> ingredients) {
      final html = '''
        <script type="application/ld+json">
        {
          "@type": "Recipe",
          "name": "Test Recipe",
          "recipeIngredient": ${ingredients.map((i) => '"$i"').toList()}
        }
        </script>
      ''';
      final recipe = parser.parse(html);
      return recipe?.ingredients.map((i) => i.name).toList() ?? [];
    }

    test('collapses double parentheses', () {
      final results = parseIngredients([
        '2 tbsp finely chopped white onion ((or red, brown or yellow))',
        '2 medium avocados (or 1 very large one) ((Note 1))',
      ]);

      expect(results[0], '2 tbsp finely chopped white onion (or red, brown or yellow)');
      expect(results[1], '2 medium avocados (or 1 very large one) (Note 1)');
    });

    test('fixes empty prep comma bug', () {
      final results = parseIngredients([
        '1/2 tsp salt (, plus more to taste)',
        'Lime juice (, to taste (I use 1/4 - 1/2 lime))',
        'Optional: 1 ripe tomato (, peeled, deseeded and chopped)',
      ]);

      expect(results[0], '1/2 tsp salt (plus more to taste)');
      expect(results[1], 'Lime juice (to taste (I use 1/4 - 1/2 lime))');
      expect(results[2], 'Optional: 1 ripe tomato (peeled, deseeded and chopped)');
    });

    test('handles space before comma in parens', () {
      final results = parseIngredients([
        'Lime juice ( , to taste)',
      ]);

      expect(results[0], 'Lime juice (to taste)');
    });

    test('handles complex nested cases', () {
      final results = parseIngredients([
        '1 tbsp finely chopped jalapeno or serrano chilli ((or other chilli of choice) (adjust to taste))',
      ]);

      expect(results[0], '1 tbsp finely chopped jalapeno or serrano chilli (or other chilli of choice) (adjust to taste)');
    });

    test('preserves normal single parentheses', () {
      final results = parseIngredients([
        '1 cup flour (210 g)',
        '2 eggs (large)',
        '1/4 cup sugar (I use 1/4 - 1/2 cup)',
      ]);

      expect(results[0], '1 cup flour (210 g)');
      expect(results[1], '2 eggs (large)');
      expect(results[2], '1/4 cup sugar (I use 1/4 - 1/2 cup)');
    });

    test('cleans up extra whitespace', () {
      final results = parseIngredients([
        '  2 cups  flour  ',
        '1 cup ( with extra space )',
      ]);

      expect(results[0], '2 cups flour');
      expect(results[1], '1 cup (with extra space)');
    });

    test('removes empty parentheses', () {
      final results = parseIngredients([
        '1 cup flour ()',
        '2 eggs (,)',
      ]);

      expect(results[0], '1 cup flour');
      expect(results[1], '2 eggs');
    });

    test('preserves legitimate nested parentheses without ((', () {
      // This case has )) at the end but no (( - should not collapse
      final results = parseIngredients([
        '1 cup (outer note (inner note))',
        'salt (to taste (about 1 tsp))',
      ]);

      expect(results[0], '1 cup (outer note (inner note))');
      expect(results[1], 'salt (to taste (about 1 tsp))');
    });

    test('handles all real-world examples from WordPress/Yoast', () {
      final results = parseIngredients([
        '2 tbsp finely chopped white onion ((or red, brown or yellow))',
        '1 tbsp finely chopped jalapeno or serrano chilli ((or other chilli of choice) (adjust to taste))',
        '1/2 tsp salt (, plus more to taste)',
        'Lime juice (, to taste (I use 1/4 - 1/2 lime))',
        '2 medium avocados (or 1 very large one) ((Note 1))',
        'Optional: 1 ripe tomato (, peeled, deseeded and chopped)',
      ]);

      expect(results[0], '2 tbsp finely chopped white onion (or red, brown or yellow)');
      expect(results[1], '1 tbsp finely chopped jalapeno or serrano chilli (or other chilli of choice) (adjust to taste)');
      expect(results[2], '1/2 tsp salt (plus more to taste)');
      expect(results[3], 'Lime juice (to taste (I use 1/4 - 1/2 lime))');
      expect(results[4], '2 medium avocados (or 1 very large one) (Note 1)');
      expect(results[5], 'Optional: 1 ripe tomato (peeled, deseeded and chopped)');
    });
  });
}
