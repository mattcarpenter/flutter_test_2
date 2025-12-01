import '../features/recipes/models/scale_convert_state.dart';
import 'ingredient_parser_service.dart';
import 'unit_conversion_service.dart';

/// Service that orchestrates parsing, scaling, and conversion of ingredients.
///
/// This service applies transformations at display time, keeping the original
/// data unchanged while producing transformed display text.
class IngredientTransformService {
  final IngredientParserService _parser;
  final UnitConversionService _converter;

  IngredientTransformService({
    IngredientParserService? parser,
    UnitConversionService? converter,
  })  : _parser = parser ?? IngredientParserService(),
        _converter = converter ?? UnitConversionService();

  /// Transform a single ingredient string with scaling and conversion.
  TransformedIngredient transform({
    required String originalText,
    required ScaleConvertState state,
  }) {
    // Early exit if no transformation needed
    if (!state.isTransformActive) {
      return _noTransform(originalText);
    }

    // Parse the ingredient to get quantity data
    final parsed = _parser.parseEnhanced(originalText, conversionService: _converter);

    if (!parsed.hasQuantities) {
      // No quantities found - handle bare ingredients for scaling
      return _transformBareIngredient(originalText, state);
    }

    // Build the transformed text by processing each quantity
    String displayText = originalText;
    final quantities = <QuantityDisplay>[];

    // Process quantities in reverse order to preserve indices
    for (int i = parsed.quantities.length - 1; i >= 0; i--) {
      final quantity = parsed.quantities[i];
      final transformedQuantity = _transformQuantity(quantity, state);

      // Replace the original quantity text with transformed text
      displayText = displayText.substring(0, quantity.startIndex) +
          transformedQuantity +
          displayText.substring(quantity.endIndex);
    }

    // Build quantity displays for highlighting (process in forward order)
    int currentOffset = 0;
    for (int i = 0; i < parsed.quantities.length; i++) {
      final quantity = parsed.quantities[i];
      final transformedQuantity = _transformQuantity(quantity, state);

      final newStart = quantity.startIndex + currentOffset;
      final newEnd = newStart + transformedQuantity.length;

      quantities.add(QuantityDisplay(
        start: newStart,
        end: newEnd,
        text: transformedQuantity,
      ));

      currentOffset += (transformedQuantity.length - (quantity.endIndex - quantity.startIndex));
    }

    return TransformedIngredient(
      originalText: originalText,
      displayText: displayText,
      quantities: quantities,
      wasScaled: state.isScalingActive,
      wasConverted: state.isConversionActive,
    );
  }

  /// Transform a quantity with scaling and/or conversion.
  String _transformQuantity(ParsedQuantity quantity, ScaleConvertState state) {
    double value = quantity.value;
    double? rangeMax = quantity.rangeMax;
    String unit = quantity.unit;

    // Step 1: Apply scaling if active
    if (state.isScalingActive && quantity.isScalable) {
      value = value * state.scaleFactor;
      if (rangeMax != null) {
        rangeMax = rangeMax * state.scaleFactor;
      }
    }

    // Step 2: Apply conversion if active
    if (state.isConversionActive && quantity.isConvertible) {
      final conversionResult = _converter.convertToSystem(
        value: value,
        fromUnit: quantity.canonicalUnit.isNotEmpty ? quantity.canonicalUnit : unit,
        targetSystem: state.conversionMode,
      );

      value = conversionResult.value;
      unit = conversionResult.unit;

      // Also convert range max if present
      if (rangeMax != null) {
        final rangeResult = _converter.convertToSystem(
          value: rangeMax,
          fromUnit: quantity.canonicalUnit.isNotEmpty ? quantity.canonicalUnit : quantity.unit,
          targetSystem: state.conversionMode,
        );
        rangeMax = rangeResult.value;
      }
    }

    // Step 3: Format the result
    return _formatQuantity(value, rangeMax, unit);
  }

  /// Format a quantity as a readable string.
  /// Uses unit-based formatting: metric units use decimals, others use fractions.
  String _formatQuantity(double value, double? rangeMax, String unit) {
    final useDecimal = _isMetricUnit(unit);
    final granularity = _getFractionGranularity(unit);

    final formattedValue = useDecimal
        ? _formatAsDecimal(value)
        : _formatAsFraction(value, granularity);

    if (rangeMax != null) {
      final formattedMax = useDecimal
          ? _formatAsDecimal(rangeMax)
          : _formatAsFraction(rangeMax, granularity);
      return unit.isNotEmpty
          ? '$formattedValue-$formattedMax $unit'
          : '$formattedValue-$formattedMax';
    }

    return unit.isNotEmpty ? '$formattedValue $unit' : formattedValue;
  }

  /// Check if a unit is metric (should use decimal formatting).
  bool _isMetricUnit(String unit) {
    final lower = unit.toLowerCase();
    const metricUnits = {
      // Weight
      'g', 'gram', 'grams',
      'kg', 'kilogram', 'kilograms',
      'mg', 'milligram', 'milligrams',
      // Volume
      'ml', 'milliliter', 'milliliters', 'millilitre', 'millilitres',
      'l', 'liter', 'liters', 'litre', 'litres',
      'cl', 'centiliter', 'centiliters',
      'dl', 'deciliter', 'deciliters',
    };
    return metricUnits.contains(lower);
  }

  /// Get the fraction granularity for a unit.
  /// All units use 1/8 granularity for finer scaling control.
  double _getFractionGranularity(String unit) {
    return 0.125;
  }

  /// Format a number as decimal, rounded to tenths.
  /// For large values (>=100), rounds to whole numbers.
  String _formatAsDecimal(double value) {
    // Whole numbers
    if (value == value.truncate()) {
      return value.toInt().toString();
    }

    // Large values: round to whole
    if (value >= 100) {
      return value.round().toString();
    }

    // Round to tenths
    final rounded = (value * 10).round() / 10;
    if (rounded == rounded.truncate()) {
      return rounded.toInt().toString();
    }
    return rounded.toStringAsFixed(1);
  }

  /// Format a number as a fraction, rounded to the given granularity.
  /// Thirds (1/3, 2/3) are preserved before rounding since they don't
  /// align with 1/8 granularity but are common in cooking.
  String _formatAsFraction(double value, double granularity) {
    // Check for thirds BEFORE rounding (they don't align with 1/8)
    final whole = value.truncate();
    final fractional = value - whole;
    final thirdsMatch = _matchThirds(fractional);
    if (thirdsMatch != null) {
      if (whole == 0) {
        return thirdsMatch;
      }
      return '$whole $thirdsMatch';
    }

    // Round to nearest granularity
    double rounded = (value / granularity).round() * granularity;

    // Don't round to 0 for small positive values
    if (rounded == 0 && value > 0) {
      rounded = granularity;
    }

    // Whole numbers
    if (rounded == rounded.truncate()) {
      return rounded.toInt().toString();
    }

    final roundedWhole = rounded.truncate();
    final roundedFractional = rounded - roundedWhole;

    // Convert fractional part to fraction string
    final fractionStr = _decimalToFraction(roundedFractional);

    if (roundedWhole == 0) {
      return fractionStr.isNotEmpty ? fractionStr : '0';
    } else if (fractionStr.isEmpty) {
      return roundedWhole.toString();
    } else {
      return '$roundedWhole $fractionStr';
    }
  }

  /// Check if a fractional value is close to 1/3 or 2/3.
  /// Returns the fraction string if matched, null otherwise.
  String? _matchThirds(double fractional) {
    const tolerance = 0.02;
    if ((fractional - 0.333).abs() < tolerance ||
        (fractional - 0.334).abs() < tolerance) {
      return '1/3';
    }
    if ((fractional - 0.666).abs() < tolerance ||
        (fractional - 0.667).abs() < tolerance) {
      return '2/3';
    }
    return null;
  }

  /// Convert a decimal (0-1) to its fraction string representation.
  String _decimalToFraction(double decimal) {
    if (decimal == 0) return '';

    // Common fractions with tolerance for rounding errors
    const fractions = [
      (0.125, '1/8'),
      (0.25, '1/4'),
      (0.333, '1/3'),
      (0.375, '3/8'),
      (0.5, '1/2'),
      (0.625, '5/8'),
      (0.666, '2/3'),
      (0.667, '2/3'),
      (0.75, '3/4'),
      (0.875, '7/8'),
    ];

    for (final (value, fraction) in fractions) {
      if ((decimal - value).abs() < 0.02) {
        return fraction;
      }
    }

    // Fallback: shouldn't happen if rounded to proper granularity
    return '';
  }

  /// Create a no-transform result (passthrough).
  TransformedIngredient _noTransform(String originalText) {
    final parsed = _parser.parseEnhanced(originalText, conversionService: _converter);
    final quantities = parsed.quantities
        .map((q) => QuantityDisplay(
              start: q.startIndex,
              end: q.endIndex,
              text: q.originalText,
            ))
        .toList();

    return TransformedIngredient.unchanged(originalText, quantities);
  }

  /// Transform a bare ingredient (no quantity) by prepending the scale factor.
  ///
  /// For ingredients like "Carrot" with no quantity, we treat them as 1 unit.
  /// When scaled, we prepend the formatted scale factor:
  /// - "Carrot" × 2x → "2 Carrot"
  /// - "Carrot" × 0.5x → "1/2 Carrot"
  ///
  /// Note: Conversion is not applicable to bare ingredients.
  /// Note: Ingredients with approximate terms (like "to taste") are not scaled.
  TransformedIngredient _transformBareIngredient(
    String originalText,
    ScaleConvertState state,
  ) {
    // Skip empty or whitespace-only text
    if (originalText.trim().isEmpty) {
      return TransformedIngredient.unchanged(originalText, []);
    }

    // Skip ingredients with approximate terms (pinch, to taste, etc.)
    if (_converter.containsApproximateTerm(originalText)) {
      return TransformedIngredient.unchanged(originalText, []);
    }

    // Only scaling applies to bare ingredients (not conversion)
    if (!state.isScalingActive) {
      // Only conversion is active, but that doesn't apply to bare ingredients
      return TransformedIngredient.unchanged(originalText, []);
    }

    // Format the scale factor as the quantity
    final scaleFactor = state.scaleFactor;
    final formattedQuantity = _formatAsFraction(scaleFactor, 0.125);

    // Prepend the formatted quantity to the original text
    final displayText = '$formattedQuantity $originalText';

    // The quantity spans from the start to just before the space
    final quantityEnd = formattedQuantity.length;
    final quantities = [
      QuantityDisplay(
        start: 0,
        end: quantityEnd,
        text: formattedQuantity,
      ),
    ];

    return TransformedIngredient(
      originalText: originalText,
      displayText: displayText,
      quantities: quantities,
      wasScaled: true,
      wasConverted: false,
    );
  }

  /// Transform a list of ingredients.
  ///
  /// Takes a list of ingredient name strings and returns transformed results.
  List<TransformedIngredient> transformAll({
    required List<String> ingredientNames,
    required ScaleConvertState state,
  }) {
    return ingredientNames
        .map((name) => transform(originalText: name, state: state))
        .toList();
  }

  /// Calculate the scale factor needed to scale a source ingredient
  /// to a target amount.
  ///
  /// Returns null if the calculation cannot be performed (e.g., incompatible
  /// units, no quantity found in source).
  double? calculateIngredientScaleFactor({
    required String sourceIngredientText,
    required double targetAmount,
    required String targetUnit,
  }) {
    final parsed = _parser.parseEnhanced(sourceIngredientText, conversionService: _converter);

    if (!parsed.hasQuantities) {
      return null; // Can't calculate without a source quantity
    }

    final sourceQuantity = parsed.primaryQuantity!;
    double sourceValue = sourceQuantity.value;
    String sourceUnit = sourceQuantity.canonicalUnit.isNotEmpty
        ? sourceQuantity.canonicalUnit
        : sourceQuantity.unit;

    // Normalize target unit
    String normalizedTargetUnit = _converter.getCanonicalUnit(targetUnit);

    // Check if units are compatible
    if (sourceUnit.toLowerCase() == normalizedTargetUnit.toLowerCase()) {
      // Same unit - simple division
      return targetAmount / sourceValue;
    }

    // Check if units are convertible
    if (_converter.areUnitsConvertible(sourceUnit, targetUnit)) {
      // Convert source to target unit
      final converted = _converter.convert(
        value: sourceValue,
        fromUnit: sourceUnit,
        toUnit: normalizedTargetUnit,
      );

      if (converted != null) {
        return targetAmount / converted.value;
      }
    }

    // Units are not compatible
    return null;
  }

  /// Get a suggested slider range for ingredient-based scaling.
  ///
  /// Returns (min, max, default) values for the slider based on the
  /// source ingredient's quantity.
  ///
  /// For bare ingredients without quantities (e.g., "Carrot"), returns a
  /// default range based on treating the ingredient as 1 unit.
  ///
  /// Returns null for empty/whitespace strings.
  (double min, double max, double defaultValue)? getIngredientSliderRange({
    required String sourceIngredientText,
  }) {
    // Return null for empty or whitespace-only text
    if (sourceIngredientText.trim().isEmpty) {
      return null;
    }

    final parsed = _parser.parseEnhanced(sourceIngredientText, conversionService: _converter);

    if (!parsed.hasQuantities) {
      // Bare ingredient - treat as 1 unit
      // Range: 0.25 to 10, default 1
      return (0.25, 10.0, 1.0);
    }

    final sourceValue = parsed.primaryQuantity!.value;

    // Suggest a range from 10% to 500% of the original amount
    return (
      sourceValue * 0.1,
      sourceValue * 5.0,
      sourceValue,
    );
  }
}
