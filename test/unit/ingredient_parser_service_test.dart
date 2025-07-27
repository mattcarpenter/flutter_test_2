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

    group('Unicode fractions', () {
      test('parses simple Unicode fractions', () {
        final result = parser.parse('½ cup sugar');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '½ cup');
        expect(result.cleanName, 'sugar');
      });

      test('parses mixed Unicode fractions', () {
        final result = parser.parse('1½ cups flour');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '1½ cups');
        expect(result.cleanName, 'flour');
      });

      test('parses various Unicode fractions', () {
        final testCases = [
          ('¼ cup milk', '¼ cup', 'milk'),
          ('¾ tsp salt', '¾ tsp', 'salt'),
          ('⅓ cup water', '⅓ cup', 'water'),
          ('⅔ cup oats', '⅔ cup', 'oats'),
          ('⅛ tsp pepper', '⅛ tsp', 'pepper'),
          ('⅞ cup cream', '⅞ cup', 'cream'),
        ];
        
        for (final (input, expectedQuantity, expectedName) in testCases) {
          final result = parser.parse(input);
          expect(result.quantities.length, 1, reason: 'Failed for: $input');
          expect(result.quantities[0].text, expectedQuantity, reason: 'Failed for: $input');
          expect(result.cleanName, expectedName, reason: 'Failed for: $input');
        }
      });

      test('parses bare Unicode fractions', () {
        final result = parser.parse('½ onion');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '½');
        expect(result.cleanName, 'onion');
      });

      test('parses mixed bare Unicode fractions', () {
        final result = parser.parse('1½ tomatoes');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '1½');
        expect(result.cleanName, 'tomatoes');
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

    group('Bare numbers', () {
      test('parses bare number at start', () {
        final result = parser.parse('1 onion');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '1');
        expect(result.quantities[0].start, 0);
        expect(result.quantities[0].end, 1);
        expect(result.cleanName, 'onion');
      });

      test('parses bare fraction at start', () {
        final result = parser.parse('1/2 avocado');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '1/2');
        expect(result.cleanName, 'avocado');
      });

      test('parses bare mixed fraction at start', () {
        final result = parser.parse('1 1/2 onions');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '1 1/2');
        expect(result.cleanName, 'onions');
      });

      test('does not parse bare number if unit follows', () {
        // Should be handled by regular quantity parsing, not bare number
        final result = parser.parse('1 cup flour');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '1 cup'); // Full quantity with unit
        expect(result.cleanName, 'flour');
      });

      test('does not parse numbers in middle of text', () {
        final result = parser.parse('eggs 2 dozen');
        
        expect(result.quantities.length, 0); // No bare number parsing in middle
        expect(result.cleanName, 'eggs 2 dozen');
      });

      test('parses multiple items with bare numbers', () {
        final result = parser.parse('2 eggs');
        
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '2');
        expect(result.cleanName, 'eggs');
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

    test('scales bare numbers', () {
      final scaled = '2 eggs'.scaleIngredient(1.5, parser);
      expect(scaled, '3 eggs');
    });

    test('scales bare fractions', () {
      final scaled = '1/2 onion'.scaleIngredient(4, parser);
      expect(scaled, '2 onion');
    });

    test('scales bare mixed fractions', () {
      final scaled = '1 1/2 tomatoes'.scaleIngredient(2, parser);
      expect(scaled, '3 tomatoes');
    });

    test('scales Unicode fractions', () {
      final scaled = '½ cup flour'.scaleIngredient(2, parser);
      expect(scaled, '1 cup flour');
    });

    test('scales mixed Unicode fractions', () {
      final scaled = '1½ cups sugar'.scaleIngredient(2, parser);
      expect(scaled, '3 cups sugar');
    });

    test('scales bare Unicode fractions', () {
      final scaled = '¼ onion'.scaleIngredient(4, parser);
      expect(scaled, '1 onion');
    });

    test('scales complex Unicode fractions', () {
      final scaled = '⅔ cup milk'.scaleIngredient(1.5, parser);
      expect(scaled, '1 cup milk');
    });
  });

  group('Japanese Language Support', () {
    group('Language Detection', () {
      test('detects Japanese text with Hiragana', () {
        final language = parser.detectLanguage('小麦粉');
        expect(language, Language.japanese);
      });

      test('detects Japanese text with Katakana', () {
        final language = parser.detectLanguage('カップ');
        expect(language, Language.japanese);
      });

      test('detects Japanese text with Kanji', () {
        final language = parser.detectLanguage('大さじ');
        expect(language, Language.japanese);
      });

      test('detects English text', () {
        final language = parser.detectLanguage('cup flour');
        expect(language, Language.english);
      });

      test('prefers Japanese when mixed', () {
        final language = parser.detectLanguage('1カップ flour');
        expect(language, Language.japanese);
      });
    });

    group('Japanese Units', () {
      test('parses Japanese volume units', () {
        final testCases = [
          ('1カップ小麦粉', '1カップ', '小麦粉'),
          ('2大さじバター', '2大さじ', 'バター'),
          ('1小さじ塩', '1小さじ', '塩'),
          ('200ml牛乳', '200ml', '牛乳'),
        ];

        for (final (input, expectedQuantity, expectedName) in testCases) {
          final result = parser.parse(input);
          expect(result.quantities.length, 1, reason: 'Failed for: $input');
          expect(result.quantities[0].text, expectedQuantity, reason: 'Failed for: $input');
          expect(result.cleanName, expectedName, reason: 'Failed for: $input');
        }
      });

      test('parses Japanese weight units', () {
        final testCases = [
          ('100gチーズ', '100g', 'チーズ'),
          ('1キロ肉', '1キロ', '肉'),
        ];

        for (final (input, expectedQuantity, expectedName) in testCases) {
          final result = parser.parse(input);
          expect(result.quantities.length, 1, reason: 'Failed for: $input');
          expect(result.quantities[0].text, expectedQuantity, reason: 'Failed for: $input');
          expect(result.cleanName, expectedName, reason: 'Failed for: $input');
        }
      });

      test('parses Japanese count units', () {
        final testCases = [
          ('卵2個', '2個', '卵'),
          ('にんじん3本', '3本', 'にんじん'),
          ('トマト1玉', '1玉', 'トマト'),
          ('豆腐1丁', '1丁', '豆腐'),
        ];

        for (final (input, expectedQuantity, expectedName) in testCases) {
          final result = parser.parse(input);
          expect(result.quantities.length, 1, reason: 'Failed for: $input');
          expect(result.quantities[0].text, expectedQuantity, reason: 'Failed for: $input');
          expect(result.cleanName, expectedName, reason: 'Failed for: $input');
        }
      });
    });

    group('Japanese Numbers', () {
      test('parses Arabic numbers with half', () {
        final result = parser.parse('2半個卵');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '2半個');
        expect(result.cleanName, '卵');
      });

      test('parses Kanji numbers', () {
        final testCases = [
          ('一個りんご', '一個', 'りんご'),
          ('二本バナナ', '二本', 'バナナ'),
          ('三枚チーズ', '三枚', 'チーズ'),
        ];

        for (final (input, expectedQuantity, expectedName) in testCases) {
          final result = parser.parse(input);
          expect(result.quantities.length, 1, reason: 'Failed for: $input');
          expect(result.quantities[0].text, expectedQuantity, reason: 'Failed for: $input');
          expect(result.cleanName, expectedName, reason: 'Failed for: $input');
        }
      });

      test('parses Kanji numbers with half', () {
        final result = parser.parse('二半カップ小麦粉');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '二半カップ');
        expect(result.cleanName, '小麦粉');
      });

      test('parses pure half', () {
        final result = parser.parse('半分');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '半');
        expect(result.cleanName, '分');
      });
    });

    group('Japanese Approximate Terms', () {
      test('parses Japanese approximate quantities', () {
        final testCases = [
          ('塩適量', '適量', '塩'),
          ('砂糖少々', '少々', '砂糖'),
          ('胡椒ひとつまみ', 'ひとつまみ', '胡椒'),
          ('醤油お好みで', 'お好みで', '醤油'),
        ];

        for (final (input, expectedQuantity, expectedName) in testCases) {
          final result = parser.parse(input);
          expect(result.quantities.length, 1, reason: 'Failed for: $input');
          expect(result.quantities[0].text, expectedQuantity, reason: 'Failed for: $input');
          expect(result.cleanName, expectedName, reason: 'Failed for: $input');
        }
      });
    });

    group('Japanese Scaling', () {
      test('scales Japanese quantities with Arabic numbers', () {
        final scaled = '2カップ小麦粉'.scaleIngredient(1.5, parser);
        expect(scaled, '3カップ小麦粉');
      });

      test('scales Japanese numbers with half', () {
        final scaled = '2半個卵'.scaleIngredient(2, parser);
        expect(scaled, '5個卵');
      });

      test('scales Kanji numbers', () {
        final scaled = '二個りんご'.scaleIngredient(2, parser);
        expect(scaled, '4個りんご');
      });

      test('scales pure half', () {
        final scaled = '半カップ牛乳'.scaleIngredient(2, parser);
        expect(scaled, '1カップ牛乳');
      });

      test('preserves Japanese approximate terms', () {
        final scaled = '塩適量'.scaleIngredient(2, parser);
        expect(scaled, '塩適量');
      });
    });

    group('Mixed Language Support', () {
      test('handles mixed English-Japanese input', () {
        final result = parser.parse('1 cup 小麦粉');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '1 cup');
        expect(result.cleanName, '小麦粉');
      });

      test('handles Japanese units with English ingredient names', () {
        final result = parser.parse('2カップ flour');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '2カップ');
        expect(result.cleanName, 'flour');
      });

      test('falls back to English when Japanese parsing fails', () {
        final result = parser.parse('1 cup flour (with some カタカナ)');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '1 cup');
        expect(result.cleanName, 'flour (with some カタカナ)');
      });
    });

    group('Complex Japanese Patterns', () {
      test('handles traditional measurements', () {
        final testCases = [
          ('米1合', '1合', '米'),
          ('酒2升', '2升', '酒'),
        ];

        for (final (input, expectedQuantity, expectedName) in testCases) {
          final result = parser.parse(input);
          expect(result.quantities.length, 1, reason: 'Failed for: $input');
          expect(result.quantities[0].text, expectedQuantity, reason: 'Failed for: $input');
          expect(result.cleanName, expectedName, reason: 'Failed for: $input');
        }
      });

      test('handles portions and containers', () {
        final testCases = [
          ('4人分', '4人分', ''),
          ('牛乳1パック', '1パック', '牛乳'),
          ('ヨーグルト1杯', '1杯', 'ヨーグルト'),
        ];

        for (final (input, expectedQuantity, expectedName) in testCases) {
          final result = parser.parse(input);
          expect(result.quantities.length, 1, reason: 'Failed for: $input');
          expect(result.quantities[0].text, expectedQuantity, reason: 'Failed for: $input');
          expect(result.cleanName, expectedName, reason: 'Failed for: $input');
        }
      });

      test('handles ingredients with preparation notes', () {
        final result = parser.parse('2カップ小麦粉、ふるったもの');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].text, '2カップ');
        expect(result.cleanName, '小麦粉、ふるったもの');
      });
    });
  });
}