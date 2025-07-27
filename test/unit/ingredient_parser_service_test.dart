import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/src/services/ingredient_parser_service.dart';

void main() {
  late IngredientParserService parser;

  setUp(() {
    parser = IngredientParserService();
  });

  group('IngredientParserService', () {
    group('Simple quantities', () {
      test('parses single quantity with space', () {
        final result = parser.parse('1 cup flour');
        
        expect(result.originalText, '1 cup flour');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '1 cup');
        expect(result.quantities[0].start, 0);
        expect(result.quantities[0].end, 5);
        expect(result.cleanName, 'flour');
      });

      test('parses single quantity without space', () {
        final result = parser.parse('2T olive oil');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '2T');
        expect(result.cleanName, 'olive oil');
      });

      test('parses decimal quantities', () {
        final result = parser.parse('1.5 cups milk');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '1.5 cups');
        expect(result.cleanName, 'milk');
      });

      test('handles plural units', () {
        final result = parser.parse('3 tablespoons butter');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '3 tablespoons');
        expect(result.cleanName, 'butter');
      });
    });

    group('Fractions', () {
      test('parses simple fractions', () {
        final result = parser.parse('1/2 cup sugar');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '1/2 cup');
        expect(result.cleanName, 'sugar');
      });

      test('parses mixed fractions', () {
        final result = parser.parse('1 1/2 cups all-purpose flour');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '1 1/2 cups');
        expect(result.cleanName, 'all-purpose flour');
      });

      test('parses complex fractions', () {
        final result = parser.parse('2/3 cup brown sugar');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '2/3 cup');
        expect(result.cleanName, 'brown sugar');
      });
    });

    group('Ranges', () {
      test('parses ranges with hyphen', () {
        final result = parser.parse('2-3 cloves garlic');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '2-3 cloves');
        expect(result.cleanName, 'garlic');
      });

      test('parses ranges with "to"', () {
        final result = parser.parse('1 to 2 tablespoons vinegar');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '1 to 2 tablespoons');
        expect(result.cleanName, 'vinegar');
      });

      test('parses decimal ranges', () {
        final result = parser.parse('0.5-1 cup broth');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '0.5-1 cup');
        expect(result.cleanName, 'broth');
      });
    });

    group('Multiple quantities', () {
      test('parses multiple quantities with plus', () {
        final result = parser.parse('1 cup + 2 tablespoons flour');
        
        expect(result.quantities.length, 2);
        expect(result.quantities[0].text, '1 cup');
        expect(result.quantities[1].text, '2 tablespoons');
        expect(result.cleanName, 'flour');
      });

      test('parses multiple quantities with comma', () {
        final result = parser.parse('1 cup flour, 2 tbsp water');
        
        expect(result.quantities.length, 2);
        expect(result.quantities[0].text, '1 cup');
        expect(result.quantities[1].text, '2 tbsp');
        expect(result.cleanName, 'flour, water');
      });

      test('parses parenthetical quantities', () {
        final result = parser.parse('1 (15 oz) can tomatoes');
        
        expect(result.quantities.length, 1);
        // Our parser currently doesn't parse bare numbers without units
        expect(result.quantities[0].text, '15 oz');
        expect(result.cleanName, '1 ( ) can tomatoes');
      });
    });

    group('Special cases', () {
      test('handles approximate terms', () {
        final result = parser.parse('salt to taste');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, ' to taste');
        expect(result.cleanName, 'salt');
      });

      test('handles "as needed"', () {
        final result = parser.parse('flour as needed for dusting');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, ' as needed ');
        expect(result.cleanName, 'flour for dusting');
      });

      test('handles ingredients with no quantities', () {
        final result = parser.parse('vanilla extract');
        
        expect(result.quantities.length, 0);
        expect(result.cleanName, 'vanilla extract');
      });

      test('handles empty input', () {
        final result = parser.parse('');
        
        expect(result.quantities.length, 0);
        expect(result.cleanName, '');
      });

      test('handles quantity at end', () {
        final result = parser.parse('eggs, 2');
        
        expect(result.quantities.length, 0); // Number without unit not parsed
        expect(result.cleanName, 'eggs, 2');
      });
    });

    group('Unit variations', () {
      test('recognizes tablespoon variations', () {
        final variations = ['1 tablespoon', '2 tablespoons', '1 tbsp', '1 Tbsp', '1 T', '1 tbs'];
        
        for (final input in variations) {
          final result = parser.parse('$input salt');
          expect(result.quantities.length, 1, reason: 'Failed for: $input');
          expect(result.cleanName, 'salt');
        }
      });

      test('recognizes teaspoon variations', () {
        final variations = ['1 teaspoon', '2 teaspoons', '1 tsp', '1 Tsp', '1 t'];
        
        for (final input in variations) {
          final result = parser.parse('$input vanilla');
          expect(result.quantities.length, 1, reason: 'Failed for: $input');
          expect(result.cleanName, 'vanilla');
        }
      });

      test('recognizes weight units', () {
        final testCases = [
          ('1 pound beef', 'beef'),
          ('2 lbs chicken', 'chicken'),
          ('100 grams cheese', 'cheese'),
          ('1 kg potatoes', 'potatoes'),
          ('8 oz chocolate', 'chocolate'),
        ];
        
        for (final (input, expectedName) in testCases) {
          final result = parser.parse(input);
          expect(result.quantities.length, 1, reason: 'Failed for: $input');
          expect(result.cleanName, expectedName);
        }
      });
    });

    group('Complex real-world examples', () {
      test('handles ingredient with preparation notes', () {
        final result = parser.parse('2 cups carrots, diced');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '2 cups');
        expect(result.cleanName, 'carrots, diced');
      });

      test('handles brand names and specifics', () {
        final result = parser.parse('1 (14.5 oz) can Hunt\'s diced tomatoes');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '14.5 oz');
        expect(result.cleanName, '1 ( ) can Hunt\'s diced tomatoes');
      });

      test('handles multiple units in sequence', () {
        final result = parser.parse('1 pound (450 g) ground beef');
        
        expect(result.quantities.length, 2);
        expect(result.quantities[0].text, '1 pound');
        expect(result.quantities[1].text, '450 g');
        expect(result.cleanName, '( ) ground beef');
      });

      test('handles ingredients starting with "of"', () {
        final result = parser.parse('1 cup of flour');
        
        expect(result.quantities.length, 1);
        expect(result.cleanName, 'flour'); // "of" should be removed
      });
    });

    group('Edge cases', () {
      test('handles special characters', () {
        final result = parser.parse('1/4 cup olive oil (extra-virgin)');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '1/4 cup');
        expect(result.cleanName, 'olive oil (extra-virgin)');
      });

      test('handles units that could be confused', () {
        // 't' could be teaspoon, 'T' could be tablespoon
        final result1 = parser.parse('1 t salt');
        final result2 = parser.parse('1 T sugar');
        
        expect(result1.quantities.length, 1);
        expect(result2.quantities.length, 1);
      });

      test('handles ingredients with numbers in name', () {
        final result = parser.parse('2 cups 2% milk');
        
        expect(result.quantities.length, 1);
        expect(result.cleanName, '2% milk');
      });
    });
  });

  group('Scaling functionality', () {
    test('scales simple quantities', () {
      final scaled = '1 cup flour'.scaleIngredient(2, parser);
      expect(scaled, '2 cup flour');
    });

    test('scales fractions', () {
      final scaled = '1/2 cup sugar'.scaleIngredient(2, parser);
      expect(scaled, '1 cup sugar');
    });

    test('scales mixed fractions', () {
      final scaled = '1 1/2 cups flour'.scaleIngredient(2, parser);
      expect(scaled, '3 cups flour');
    });

    test('scales ranges', () {
      final scaled = '2-3 cloves garlic'.scaleIngredient(2, parser);
      expect(scaled, '4-6 cloves garlic');
    });

    test('scales decimal quantities', () {
      final scaled = '0.5 cup milk'.scaleIngredient(3, parser);
      expect(scaled, '1 1/2 cup milk');
    });

    test('scales multiple quantities', () {
      final scaled = '1 cup + 2 tablespoons flour'.scaleIngredient(2, parser);
      expect(scaled, '2 cup + 4 tablespoons flour');
    });

    test('formats scaled values nicely', () {
      // Should convert to fractions when possible
      final scaled1 = '1 tablespoon oil'.scaleIngredient(0.5, parser);
      expect(scaled1, '1/2 tablespoon oil');
      
      final scaled2 = '1 cup sugar'.scaleIngredient(0.75, parser);
      expect(scaled2, '3/4 cup sugar');
    });

    test('handles non-scalable ingredients', () {
      final scaled = 'salt to taste'.scaleIngredient(2, parser);
      expect(scaled, 'salt to taste'); // Should remain unchanged
    });

    test('preserves original formatting', () {
      final scaled = '1T butter'.scaleIngredient(3, parser);
      expect(scaled, '3T butter'); // Keeps the 'T' format
    });
  });
}