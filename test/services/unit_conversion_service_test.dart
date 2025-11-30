import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/src/services/unit_conversion_service.dart';
import 'package:recipe_app/src/features/recipes/models/scale_convert_state.dart';

void main() {
  late UnitConversionService service;

  setUp(() {
    service = UnitConversionService();
  });

  group('UnitConversionService', () {
    group('getUnitType', () {
      test('identifies volume units correctly', () {
        expect(service.getUnitType('cup'), UnitType.volume);
        expect(service.getUnitType('cups'), UnitType.volume);
        expect(service.getUnitType('Cup'), UnitType.volume);
        expect(service.getUnitType('ml'), UnitType.volume);
        expect(service.getUnitType('tbsp'), UnitType.volume);
        expect(service.getUnitType('tsp'), UnitType.volume);
        expect(service.getUnitType('liter'), UnitType.volume);
        expect(service.getUnitType('l'), UnitType.volume);
      });

      test('identifies Japanese volume units correctly', () {
        expect(service.getUnitType('カップ'), UnitType.volume);
        expect(service.getUnitType('大さじ'), UnitType.volume);
        expect(service.getUnitType('小さじ'), UnitType.volume);
        expect(service.getUnitType('合'), UnitType.volume);
      });

      test('identifies weight units correctly', () {
        expect(service.getUnitType('g'), UnitType.weight);
        expect(service.getUnitType('gram'), UnitType.weight);
        expect(service.getUnitType('kg'), UnitType.weight);
        expect(service.getUnitType('oz'), UnitType.weight);
        expect(service.getUnitType('lb'), UnitType.weight);
        expect(service.getUnitType('pound'), UnitType.weight);
      });

      test('identifies Japanese weight units correctly', () {
        expect(service.getUnitType('グラム'), UnitType.weight);
        expect(service.getUnitType('キログラム'), UnitType.weight);
        expect(service.getUnitType('キロ'), UnitType.weight);
      });

      test('identifies count units correctly', () {
        expect(service.getUnitType('piece'), UnitType.count);
        expect(service.getUnitType('pieces'), UnitType.count);
        expect(service.getUnitType('clove'), UnitType.count);
        expect(service.getUnitType('cloves'), UnitType.count);
        expect(service.getUnitType('slice'), UnitType.count);
        expect(service.getUnitType('can'), UnitType.count);
      });

      test('identifies Japanese count units correctly', () {
        expect(service.getUnitType('個'), UnitType.count);
        expect(service.getUnitType('本'), UnitType.count);
        expect(service.getUnitType('枚'), UnitType.count);
        expect(service.getUnitType('パック'), UnitType.count);
      });

      test('identifies approximate terms correctly', () {
        expect(service.getUnitType('pinch'), UnitType.approximate);
        expect(service.getUnitType('dash'), UnitType.approximate);
        expect(service.getUnitType('to taste'), UnitType.approximate);
        expect(service.getUnitType('適量'), UnitType.approximate);
        expect(service.getUnitType('少々'), UnitType.approximate);
      });

      test('returns unknown for unrecognized units', () {
        expect(service.getUnitType('blorp'), UnitType.unknown);
        expect(service.getUnitType('xyz'), UnitType.unknown);
      });
    });

    group('getCanonicalUnit', () {
      test('normalizes volume unit variations', () {
        expect(service.getCanonicalUnit('cups'), 'cup');
        expect(service.getCanonicalUnit('Cup'), 'cup');
        expect(service.getCanonicalUnit('c'), 'cup');
        expect(service.getCanonicalUnit('tablespoon'), 'tbsp');
        expect(service.getCanonicalUnit('tablespoons'), 'tbsp');
        expect(service.getCanonicalUnit('teaspoon'), 'tsp');
      });

      test('normalizes weight unit variations', () {
        expect(service.getCanonicalUnit('grams'), 'g');
        expect(service.getCanonicalUnit('gram'), 'g');
        expect(service.getCanonicalUnit('ounces'), 'oz');
        expect(service.getCanonicalUnit('pounds'), 'lb');
        expect(service.getCanonicalUnit('lbs'), 'lb');
      });

      test('normalizes Japanese units to standard forms', () {
        expect(service.getCanonicalUnit('グラム'), 'g');
        expect(service.getCanonicalUnit('キログラム'), 'kg');
      });

      test('returns original for unrecognized units', () {
        expect(service.getCanonicalUnit('blorp'), 'blorp');
      });
    });

    group('areUnitsConvertible', () {
      test('volume units are convertible to each other', () {
        expect(service.areUnitsConvertible('cup', 'ml'), isTrue);
        expect(service.areUnitsConvertible('tbsp', 'tsp'), isTrue);
        expect(service.areUnitsConvertible('liter', 'cup'), isTrue);
      });

      test('weight units are convertible to each other', () {
        expect(service.areUnitsConvertible('g', 'oz'), isTrue);
        expect(service.areUnitsConvertible('kg', 'lb'), isTrue);
        expect(service.areUnitsConvertible('gram', 'pound'), isTrue);
      });

      test('volume and weight are not convertible', () {
        expect(service.areUnitsConvertible('cup', 'g'), isFalse);
        expect(service.areUnitsConvertible('ml', 'oz'), isFalse);
      });

      test('count units are not convertible', () {
        expect(service.areUnitsConvertible('piece', 'slice'), isFalse);
        expect(service.areUnitsConvertible('clove', 'cup'), isFalse);
      });

      test('approximate terms are not convertible', () {
        expect(service.areUnitsConvertible('pinch', 'dash'), isFalse);
        expect(service.areUnitsConvertible('pinch', 'tsp'), isFalse);
      });
    });

    group('convert', () {
      test('converts cups to ml', () {
        final result = service.convert(value: 1, fromUnit: 'cup', toUnit: 'ml');
        expect(result, isNotNull);
        expect(result!.value, closeTo(236.588, 0.01));
        expect(result.unit, 'ml');
      });

      test('converts ml to cups', () {
        final result = service.convert(value: 236.588, fromUnit: 'ml', toUnit: 'cup');
        expect(result, isNotNull);
        expect(result!.value, closeTo(1.0, 0.01));
      });

      test('converts tablespoons to teaspoons', () {
        final result = service.convert(value: 1, fromUnit: 'tbsp', toUnit: 'tsp');
        expect(result, isNotNull);
        expect(result!.value, closeTo(3.0, 0.01));
      });

      test('converts grams to ounces', () {
        final result = service.convert(value: 100, fromUnit: 'g', toUnit: 'oz');
        expect(result, isNotNull);
        expect(result!.value, closeTo(3.527, 0.01));
      });

      test('converts pounds to grams', () {
        final result = service.convert(value: 1, fromUnit: 'lb', toUnit: 'g');
        expect(result, isNotNull);
        expect(result!.value, closeTo(453.592, 0.01));
      });

      test('converts kg to lb', () {
        final result = service.convert(value: 1, fromUnit: 'kg', toUnit: 'lb');
        expect(result, isNotNull);
        expect(result!.value, closeTo(2.205, 0.01));
      });

      test('returns null for incompatible unit types', () {
        expect(service.convert(value: 1, fromUnit: 'cup', toUnit: 'g'), isNull);
        expect(service.convert(value: 1, fromUnit: 'piece', toUnit: 'ml'), isNull);
      });

      test('handles Japanese cup to ml (200ml, not 237ml)', () {
        final result = service.convert(value: 1, fromUnit: 'カップ', toUnit: 'ml');
        expect(result, isNotNull);
        expect(result!.value, closeTo(200.0, 0.01));
      });

      test('handles Japanese tablespoon to ml', () {
        final result = service.convert(value: 1, fromUnit: '大さじ', toUnit: 'ml');
        expect(result, isNotNull);
        expect(result!.value, closeTo(15.0, 0.01));
      });

      test('handles Japanese teaspoon to ml', () {
        final result = service.convert(value: 1, fromUnit: '小さじ', toUnit: 'ml');
        expect(result, isNotNull);
        expect(result!.value, closeTo(5.0, 0.01));
      });
    });

    group('convertToSystem', () {
      group('original mode', () {
        test('returns unchanged values', () {
          final result = service.convertToSystem(
            value: 2,
            fromUnit: 'cup',
            targetSystem: ConversionMode.original,
          );
          expect(result.value, 2);
          expect(result.unit, 'cup');
        });
      });

      group('metric conversion', () {
        test('converts cups to ml for small amounts', () {
          final result = service.convertToSystem(
            value: 0.25, // 1/4 cup
            fromUnit: 'cup',
            targetSystem: ConversionMode.metric,
          );
          expect(result.unit, 'ml');
          expect(result.value, closeTo(59.15, 0.1));
        });

        test('converts cups to liters for large amounts', () {
          final result = service.convertToSystem(
            value: 4,
            fromUnit: 'cup',
            targetSystem: ConversionMode.metric,
          );
          expect(result.unit, 'l');
          expect(result.value, closeTo(0.946, 0.01));
        });

        test('converts ounces to grams', () {
          final result = service.convertToSystem(
            value: 4,
            fromUnit: 'oz',
            targetSystem: ConversionMode.metric,
          );
          expect(result.unit, 'g');
          expect(result.value, closeTo(113.4, 0.1));
        });

        test('converts pounds to kg for large amounts', () {
          final result = service.convertToSystem(
            value: 2,
            fromUnit: 'lb',
            targetSystem: ConversionMode.metric,
          );
          expect(result.unit, 'kg');
          expect(result.value, closeTo(0.907, 0.01));
        });

        test('keeps small weights in grams not kg', () {
          final result = service.convertToSystem(
            value: 100,
            fromUnit: 'g',
            targetSystem: ConversionMode.metric,
          );
          expect(result.unit, 'g');
          expect(result.value, 100);
        });
      });

      group('imperial conversion', () {
        test('converts ml to cups for moderate amounts', () {
          final result = service.convertToSystem(
            value: 250,
            fromUnit: 'ml',
            targetSystem: ConversionMode.imperial,
          );
          expect(result.unit, 'cup');
          expect(result.value, closeTo(1.057, 0.01));
        });

        test('converts ml to tbsp for small amounts', () {
          final result = service.convertToSystem(
            value: 30,
            fromUnit: 'ml',
            targetSystem: ConversionMode.imperial,
          );
          expect(result.unit, 'tbsp');
          expect(result.value, closeTo(2.03, 0.1));
        });

        test('converts grams to ounces for small weights', () {
          final result = service.convertToSystem(
            value: 50,
            fromUnit: 'g',
            targetSystem: ConversionMode.imperial,
          );
          expect(result.unit, 'oz');
          expect(result.value, closeTo(1.76, 0.1));
        });

        test('converts kg to pounds', () {
          final result = service.convertToSystem(
            value: 1,
            fromUnit: 'kg',
            targetSystem: ConversionMode.imperial,
          );
          expect(result.unit, 'lb');
          expect(result.value, closeTo(2.205, 0.01));
        });
      });

      group('non-convertible units', () {
        test('count units pass through unchanged', () {
          final result = service.convertToSystem(
            value: 3,
            fromUnit: 'cloves',
            targetSystem: ConversionMode.metric,
          );
          expect(result.value, 3);
          expect(result.unit, 'cloves');
        });

        test('approximate terms pass through unchanged', () {
          final result = service.convertToSystem(
            value: 1,
            fromUnit: 'pinch',
            targetSystem: ConversionMode.metric,
          );
          expect(result.value, 1);
          expect(result.unit, 'pinch');
        });

        test('unknown units pass through unchanged', () {
          final result = service.convertToSystem(
            value: 2,
            fromUnit: 'blorp',
            targetSystem: ConversionMode.metric,
          );
          expect(result.value, 2);
          expect(result.unit, 'blorp');
        });
      });
    });

    group('ConversionResult.format', () {
      test('formats whole numbers without decimals', () {
        const result = ConversionResult(value: 2, unit: 'cup', canonicalUnit: 'cup');
        expect(result.format(), '2 cup');
      });

      test('formats fractions correctly', () {
        const result = ConversionResult(value: 0.5, unit: 'cup', canonicalUnit: 'cup');
        expect(result.format(), '1/2 cup');
      });

      test('formats mixed fractions correctly', () {
        const result = ConversionResult(value: 1.5, unit: 'cup', canonicalUnit: 'cup');
        expect(result.format(), '1 1/2 cup');
      });

      test('formats quarter fractions', () {
        const result = ConversionResult(value: 0.25, unit: 'cup', canonicalUnit: 'cup');
        expect(result.format(), '1/4 cup');
      });

      test('formats third fractions', () {
        const result = ConversionResult(value: 0.333, unit: 'cup', canonicalUnit: 'cup');
        expect(result.format(), '1/3 cup');
      });

      test('formats two-thirds fractions', () {
        const result = ConversionResult(value: 0.667, unit: 'cup', canonicalUnit: 'cup');
        expect(result.format(), '2/3 cup');
      });

      test('formats decimals when fraction not close', () {
        const result = ConversionResult(value: 1.73, unit: 'cup', canonicalUnit: 'cup');
        expect(result.format(), '1.73 cup');
      });

      test('formats without fractions when specified', () {
        const result = ConversionResult(value: 0.5, unit: 'cup', canonicalUnit: 'cup');
        expect(result.format(preferFractions: false), '0.5 cup');
      });
    });
  });
}
