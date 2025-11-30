/// The type of scaling being applied
enum ScaleType {
  amount,      // Direct multiplier (0.25x - 10x)
  servings,    // Based on recipe servings
  ingredient,  // Based on a specific ingredient's target amount
}

/// The unit system for conversion
enum ConversionMode {
  original,    // Keep as written
  imperial,    // Convert to imperial (cups, oz, lb)
  metric,      // Convert to metric (ml, g, kg)
}

/// Unit measurement type categories
enum UnitType {
  volume,      // cups, ml, liters, tbsp, tsp
  weight,      // g, kg, oz, lb
  count,       // pieces, slices, cloves
  approximate, // pinch, dash, to taste
  unknown,     // unrecognized units
}

/// State for scaling/conversion preferences for a specific recipe
class ScaleConvertState {
  final ScaleType scaleType;
  final double scaleFactor;
  final String? selectedIngredientId;
  final double? targetIngredientAmount;
  final String? targetIngredientUnit;
  final ConversionMode conversionMode;

  const ScaleConvertState({
    this.scaleType = ScaleType.amount,
    this.scaleFactor = 1.0,
    this.selectedIngredientId,
    this.targetIngredientAmount,
    this.targetIngredientUnit,
    this.conversionMode = ConversionMode.original,
  });

  /// Whether scaling is active (not at default 1x)
  bool get isScalingActive => scaleFactor != 1.0;

  /// Whether conversion is active (not original)
  bool get isConversionActive => conversionMode != ConversionMode.original;

  /// Whether any transformation is active
  bool get isTransformActive => isScalingActive || isConversionActive;

  /// Reset to default state
  static const ScaleConvertState defaultState = ScaleConvertState();

  ScaleConvertState copyWith({
    ScaleType? scaleType,
    double? scaleFactor,
    String? selectedIngredientId,
    double? targetIngredientAmount,
    String? targetIngredientUnit,
    ConversionMode? conversionMode,
    bool clearSelectedIngredient = false,
    bool clearTargetAmount = false,
  }) {
    return ScaleConvertState(
      scaleType: scaleType ?? this.scaleType,
      scaleFactor: scaleFactor ?? this.scaleFactor,
      selectedIngredientId: clearSelectedIngredient ? null : (selectedIngredientId ?? this.selectedIngredientId),
      targetIngredientAmount: clearTargetAmount ? null : (targetIngredientAmount ?? this.targetIngredientAmount),
      targetIngredientUnit: clearTargetAmount ? null : (targetIngredientUnit ?? this.targetIngredientUnit),
      conversionMode: conversionMode ?? this.conversionMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'scaleType': scaleType.name,
    'scaleFactor': scaleFactor,
    'selectedIngredientId': selectedIngredientId,
    'targetIngredientAmount': targetIngredientAmount,
    'targetIngredientUnit': targetIngredientUnit,
    'conversionMode': conversionMode.name,
  };

  factory ScaleConvertState.fromJson(Map<String, dynamic> json) {
    return ScaleConvertState(
      scaleType: ScaleType.values.firstWhere(
        (e) => e.name == json['scaleType'],
        orElse: () => ScaleType.amount,
      ),
      scaleFactor: (json['scaleFactor'] as num?)?.toDouble() ?? 1.0,
      selectedIngredientId: json['selectedIngredientId'] as String?,
      targetIngredientAmount: (json['targetIngredientAmount'] as num?)?.toDouble(),
      targetIngredientUnit: json['targetIngredientUnit'] as String?,
      conversionMode: ConversionMode.values.firstWhere(
        (e) => e.name == json['conversionMode'],
        orElse: () => ConversionMode.original,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScaleConvertState &&
          runtimeType == other.runtimeType &&
          scaleType == other.scaleType &&
          scaleFactor == other.scaleFactor &&
          selectedIngredientId == other.selectedIngredientId &&
          targetIngredientAmount == other.targetIngredientAmount &&
          targetIngredientUnit == other.targetIngredientUnit &&
          conversionMode == other.conversionMode;

  @override
  int get hashCode =>
      scaleType.hashCode ^
      scaleFactor.hashCode ^
      selectedIngredientId.hashCode ^
      targetIngredientAmount.hashCode ^
      targetIngredientUnit.hashCode ^
      conversionMode.hashCode;
}

/// Parsed quantity from an ingredient string
class ParsedQuantity {
  final double value;
  final double? rangeMax;         // For ranges like "2-3 cups", this is 3
  final String unit;              // Raw unit text (e.g., "cups", "g")
  final String canonicalUnit;     // Normalized unit (e.g., "cup", "gram")
  final UnitType unitType;
  final int startIndex;
  final int endIndex;
  final String originalText;

  const ParsedQuantity({
    required this.value,
    this.rangeMax,
    required this.unit,
    required this.canonicalUnit,
    required this.unitType,
    required this.startIndex,
    required this.endIndex,
    required this.originalText,
  });

  /// Whether this is a range quantity (e.g., "2-3 cups")
  bool get isRange => rangeMax != null;

  /// Whether this quantity can be converted between unit systems
  bool get isConvertible => unitType == UnitType.volume || unitType == UnitType.weight;

  /// Whether this quantity should be scaled
  bool get isScalable => unitType != UnitType.approximate;
}

/// Complete parse result for an ingredient with enhanced data
class EnhancedParseResult {
  final String originalText;
  final List<ParsedQuantity> quantities;
  final String ingredientName;    // Cleaned name without quantities
  final String? note;             // Any note/modifier detected

  const EnhancedParseResult({
    required this.originalText,
    required this.quantities,
    required this.ingredientName,
    this.note,
  });

  /// Whether any quantities were found
  bool get hasQuantities => quantities.isNotEmpty;

  /// The primary (first) quantity if available
  ParsedQuantity? get primaryQuantity => quantities.isNotEmpty ? quantities.first : null;
}

/// Result of a unit conversion
class ConversionResult {
  final double value;
  final String unit;
  final String canonicalUnit;
  final bool isApproximate;

  const ConversionResult({
    required this.value,
    required this.unit,
    required this.canonicalUnit,
    this.isApproximate = false,
  });

  /// Format the conversion result as a string
  String format({bool preferFractions = true}) {
    final formattedValue = _formatNumber(value, preferFractions: preferFractions);
    return '$formattedValue $unit';
  }

  static String _formatNumber(double value, {bool preferFractions = true}) {
    // Check if it's a whole number
    if (value == value.truncate()) {
      return value.toInt().toString();
    }

    if (!preferFractions) {
      // Return decimal with reasonable precision
      if (value < 10) {
        return value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
      }
      return value.toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '');
    }

    // Check for common fractions
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

    // Check for mixed fractions if value > 1
    if (value > 1) {
      final whole = value.truncate();
      final remainder = value - whole;

      for (final (decimal, fraction) in fractions) {
        if ((remainder - decimal).abs() < 0.02) {
          return '$whole $fraction';
        }
      }
    }

    // Check for simple fractions
    for (final (decimal, fraction) in fractions) {
      if ((value - decimal).abs() < 0.02) {
        return fraction;
      }
    }

    // Return as decimal
    if (value < 10) {
      return value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    }
    return value.toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '');
  }
}

/// Represents a transformed ingredient ready for display
class TransformedIngredient {
  final String originalText;
  final String displayText;
  final List<QuantityDisplay> quantities;
  final bool wasScaled;
  final bool wasConverted;

  const TransformedIngredient({
    required this.originalText,
    required this.displayText,
    required this.quantities,
    this.wasScaled = false,
    this.wasConverted = false,
  });

  /// Create an unchanged result (no transformation applied)
  factory TransformedIngredient.unchanged(String text, List<QuantityDisplay> quantities) {
    return TransformedIngredient(
      originalText: text,
      displayText: text,
      quantities: quantities,
      wasScaled: false,
      wasConverted: false,
    );
  }
}

/// Represents a quantity span for display (with position info for RichText)
class QuantityDisplay {
  final int start;
  final int end;
  final String text;

  const QuantityDisplay({
    required this.start,
    required this.end,
    required this.text,
  });
}
