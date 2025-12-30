import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/src/services/ingredient_parser_service.dart';
import 'package:recipe_app/src/services/unit_conversion_service.dart';
import 'package:recipe_app/src/features/recipes/models/scale_convert_state.dart';

void main() {
  late IngredientParserService parser;
  late UnitConversionService converter;

  setUp(() {
    parser = IngredientParserService();
    converter = UnitConversionService();
  });

  group('IngredientParserService.parseEnhanced', () {
    group('simple quantities', () {
      test('parses whole number with unit', () {
        final result = parser.parseEnhanced('2 cups flour');
        expect(result.hasQuantities, isTrue);
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 2.0);
        expect(result.quantities[0].unit, 'cups');
        expect(result.quantities[0].canonicalUnit, 'cup');
        expect(result.quantities[0].unitType, UnitType.volume);
        expect(result.ingredientName, 'flour');
      });

      test('parses decimal with unit', () {
        final result = parser.parseEnhanced('1.5 tbsp olive oil');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 1.5);
        expect(result.quantities[0].canonicalUnit, 'tbsp');
        expect(result.quantities[0].unitType, UnitType.volume);
      });

      test('parses weight units correctly', () {
        final result = parser.parseEnhanced('500g ground beef');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 500);
        expect(result.quantities[0].canonicalUnit, 'g');
        expect(result.quantities[0].unitType, UnitType.weight);
      });

      test('parses count units correctly', () {
        final result = parser.parseEnhanced('3 cloves garlic');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 3);
        expect(result.quantities[0].canonicalUnit, 'clove');
        expect(result.quantities[0].unitType, UnitType.count);
      });
    });

    group('fractions', () {
      test('parses simple fraction', () {
        final result = parser.parseEnhanced('1/2 cup sugar');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, closeTo(0.5, 0.001));
        expect(result.quantities[0].canonicalUnit, 'cup');
      });

      test('parses mixed fraction', () {
        final result = parser.parseEnhanced('1 1/2 cups flour');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, closeTo(1.5, 0.001));
      });

      test('parses unicode fraction ½', () {
        final result = parser.parseEnhanced('½ cup butter');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, closeTo(0.5, 0.001));
      });

      test('parses unicode fraction with whole number', () {
        final result = parser.parseEnhanced('1½ cups milk');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, closeTo(1.5, 0.001));
      });

      test('parses ¼ fraction', () {
        final result = parser.parseEnhanced('¼ tsp salt');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, closeTo(0.25, 0.001));
      });

      test('parses ¾ fraction', () {
        final result = parser.parseEnhanced('¾ cup cream');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, closeTo(0.75, 0.001));
      });

      test('parses ⅓ fraction', () {
        final result = parser.parseEnhanced('⅓ cup honey');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, closeTo(1/3, 0.001));
      });

      test('parses ⅔ fraction', () {
        final result = parser.parseEnhanced('⅔ cup rice');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, closeTo(2/3, 0.001));
      });
    });

    group('ranges', () {
      test('parses range with dash', () {
        final result = parser.parseEnhanced('2-3 cups broth');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 2.0);
        expect(result.quantities[0].rangeMax, 3.0);
        expect(result.quantities[0].isRange, isTrue);
        expect(result.quantities[0].canonicalUnit, 'cup');
      });

      test('parses range with "to"', () {
        final result = parser.parseEnhanced('1 to 2 tablespoons vinegar');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 1.0);
        expect(result.quantities[0].rangeMax, 2.0);
      });
    });

    group('Japanese quantities', () {
      test('parses Japanese cup (カップ)', () {
        final result = parser.parseEnhanced('1カップ flour');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 1.0);
        expect(result.quantities[0].canonicalUnit, 'カップ');
        expect(result.quantities[0].unitType, UnitType.volume);
      });

      test('parses Japanese tablespoon (大さじ)', () {
        // Note: Parser expects number before unit (2大さじ not 大さじ2)
        final result = parser.parseEnhanced('2大さじ soy sauce');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 2.0);
        expect(result.quantities[0].canonicalUnit, '大さじ');
      });

      test('parses Japanese half (半)', () {
        final result = parser.parseEnhanced('半カップ水');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, closeTo(0.5, 0.001));
      });

      test('parses Kanji numbers', () {
        final result = parser.parseEnhanced('二カップ米');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 2.0);
      });

      test('parses Japanese count units', () {
        final result = parser.parseEnhanced('3個卵');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 3.0);
        expect(result.quantities[0].unitType, UnitType.count);
      });
    });

    group('edge cases', () {
      test('returns empty quantities for no-quantity ingredient', () {
        final result = parser.parseEnhanced('salt to taste');
        expect(result.quantities, isEmpty);
        expect(result.ingredientName.toLowerCase(), contains('salt'));
      });

      test('handles empty string', () {
        final result = parser.parseEnhanced('');
        expect(result.quantities, isEmpty);
        expect(result.ingredientName, '');
      });

      test('handles ingredient with no unit (bare number)', () {
        final result = parser.parseEnhanced('2 eggs');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 2.0);
        expect(result.quantities[0].unitType, UnitType.count);
      });

      test('identifies scalable vs non-scalable quantities', () {
        final scalableResult = parser.parseEnhanced('2 cups flour');
        expect(scalableResult.quantities[0].isScalable, isTrue);

        // Approximate terms aren't captured as quantities
        final approxResult = parser.parseEnhanced('salt to taste');
        expect(approxResult.quantities, isEmpty);
      });

      test('identifies convertible vs non-convertible quantities', () {
        final volumeResult = parser.parseEnhanced('2 cups flour');
        expect(volumeResult.quantities[0].isConvertible, isTrue);

        final countResult = parser.parseEnhanced('3 cloves garlic');
        expect(countResult.quantities[0].isConvertible, isFalse);
      });
    });

    group('position tracking', () {
      test('tracks start and end positions correctly', () {
        final result = parser.parseEnhanced('2 cups flour');
        expect(result.quantities[0].startIndex, 0);
        expect(result.quantities[0].endIndex, 6); // "2 cups"
        expect(result.quantities[0].originalText, '2 cups');
      });

      test('tracks positions for fraction', () {
        final result = parser.parseEnhanced('1/2 cup sugar');
        expect(result.quantities[0].originalText, '1/2 cup');
      });
    });

    group('ingredient name extraction', () {
      test('extracts clean ingredient name', () {
        final result = parser.parseEnhanced('2 cups all-purpose flour');
        expect(result.ingredientName, 'all-purpose flour');
      });

      test('removes "of" connector', () {
        final result = parser.parseEnhanced('1 cup of sugar');
        expect(result.ingredientName, 'sugar');
      });

      test('handles ingredient with modifier', () {
        final result = parser.parseEnhanced('500g fresh spinach, washed');
        expect(result.ingredientName, contains('spinach'));
      });
    });

    group('full-width numbers and wave dash', () {
      test('parses full-width numbers correctly', () {
        final result = parser.parseEnhanced('大さじ３塩'); // Full-width 3
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 3.0);
      });

      test('parses wave dash ranges correctly', () {
        final result = parser.parseEnhanced('1〜2個卵'); // Wave dash
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 1.0);
        expect(result.quantities[0].rangeMax, 2.0);
        expect(result.quantities[0].isRange, isTrue);
      });

      test('parses full-width fractions correctly', () {
        final result = parser.parseEnhanced('１／２カップ砂糖'); // Full-width 1/2
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, closeTo(0.5, 0.001));
      });
    });

    group('unit-before-number parsing', () {
      test('parses unit-before-number correctly', () {
        final result = parser.parseEnhanced('大さじ3');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 3.0);
        expect(result.quantities[0].canonicalUnit, '大さじ');
      });

      test('parses unit-before-fraction correctly', () {
        final result = parser.parseEnhanced('大さじ1/2');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, closeTo(0.5, 0.001));
      });

      test('parses unit-before-range correctly', () {
        final result = parser.parseEnhanced('大さじ1-2');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 1.0);
        expect(result.quantities[0].rangeMax, 2.0);
      });
    });

    group('compound Kanji number parsing', () {
      test('parses compound tens (十二 = 12)', () {
        final result = parser.parseEnhanced('十二個卵');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 12.0);
      });

      test('parses compound twenties (二十三 = 23)', () {
        final result = parser.parseEnhanced('二十三g塩');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 23.0);
      });

      test('parses hundreds (百 = 100)', () {
        final result = parser.parseEnhanced('百g小麦粉');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 100.0);
      });

      test('parses compound hundreds (二百 = 200)', () {
        final result = parser.parseEnhanced('二百g砂糖');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 200.0);
      });

      test('parses hundreds with tens (百五十 = 150)', () {
        final result = parser.parseEnhanced('百五十ml牛乳');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 150.0);
      });

      test('parses Kanji with half (二半 = 2.5)', () {
        final result = parser.parseEnhanced('二半カップ米');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, closeTo(2.5, 0.001));
      });
    });

    group('片 unit parsing', () {
      test('parses 片 unit correctly', () {
        final result = parser.parseEnhanced('にんにく2片');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 2.0);
        expect(result.quantities[0].unitType, UnitType.count);
      });

      test('parses 片 range correctly', () {
        final result = parser.parseEnhanced('しょうが1〜2片');
        expect(result.quantities.length, 1);
        expect(result.quantities[0].value, 1.0);
        expect(result.quantities[0].rangeMax, 2.0);
      });
    });
  });
}
