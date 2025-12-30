import '../features/recipes/models/scale_convert_state.dart';

/// Service for converting between different measurement units.
///
/// Units are treated as distinct entities - e.g., `cup` (US ~237ml) and
/// `カップ` (Japanese 200ml) are different units, not translations.
class UnitConversionService {
  UnitConversionService();

  // ============================================================
  // VOLUME CONVERSIONS (Base: milliliter)
  // ============================================================

  static const Map<String, double> _volumeToMl = {
    // Metric
    'ml': 1.0,
    'milliliter': 1.0,
    'milliliters': 1.0,
    'millilitre': 1.0,
    'millilitres': 1.0,
    'l': 1000.0,
    'liter': 1000.0,
    'liters': 1000.0,
    'litre': 1000.0,
    'litres': 1000.0,

    // US Volume
    'tsp': 4.929,
    'teaspoon': 4.929,
    'teaspoons': 4.929,
    'tbsp': 14.787,
    'tablespoon': 14.787,
    'tablespoons': 14.787,
    'fl oz': 29.574,
    'fluid ounce': 29.574,
    'fluid ounces': 29.574,
    'cup': 236.588,
    'cups': 236.588,
    'c': 236.588,
    'pint': 473.176,
    'pints': 473.176,
    'pt': 473.176,
    'quart': 946.353,
    'quarts': 946.353,
    'qt': 946.353,
    'gallon': 3785.41,
    'gallons': 3785.41,
    'gal': 3785.41,

    // Japanese Volume (distinct units, not translations)
    'カップ': 200.0,        // Japanese cup
    '大さじ': 15.0,         // Japanese tablespoon
    '小さじ': 5.0,          // Japanese teaspoon
    '合': 180.0,           // Traditional rice measure
    '升': 1800.0,          // 10 合
    '勺': 18.0,            // 1/10 合
    'cc': 1.0,             // Common in Japanese recipes
  };

  // ============================================================
  // WEIGHT CONVERSIONS (Base: gram)
  // ============================================================

  static const Map<String, double> _weightToGram = {
    // Metric
    'mg': 0.001,
    'milligram': 0.001,
    'milligrams': 0.001,
    'g': 1.0,
    'gram': 1.0,
    'grams': 1.0,
    'kg': 1000.0,
    'kilogram': 1000.0,
    'kilograms': 1000.0,
    'kilo': 1000.0,
    'kilos': 1000.0,

    // Imperial
    'oz': 28.3495,
    'ounce': 28.3495,
    'ounces': 28.3495,
    'lb': 453.592,
    'lbs': 453.592,
    'pound': 453.592,
    'pounds': 453.592,

    // Japanese Weight
    'グラム': 1.0,
    'キログラム': 1000.0,
    'キロ': 1000.0,
  };

  // ============================================================
  // COUNT UNITS (not convertible between systems)
  // ============================================================

  static const Set<String> _countUnits = {
    // English
    'piece', 'pieces', 'pc', 'pcs',
    'slice', 'slices',
    'clove', 'cloves',
    'head', 'heads',
    'bunch', 'bunches',
    'sprig', 'sprigs',
    'stalk', 'stalks',
    'stick', 'sticks',
    'can', 'cans',
    'jar', 'jars',
    'package', 'packages', 'pkg', 'pkgs',
    'bag', 'bags',
    'box', 'boxes',
    'bottle', 'bottles',
    'leaf', 'leaves',
    'strip', 'strips',
    'sheet', 'sheets',
    'ear', 'ears',  // corn

    // Japanese count units
    '個', '本', '枚', '匹', '丁', '切れ', '片', '粒', '玉', '束',
    '袋', 'パック', '缶', '瓶',
    '人分', '杯',
  };

  // ============================================================
  // APPROXIMATE UNITS (not scalable or convertible)
  // ============================================================

  static const Set<String> _approximateTerms = {
    // English
    'pinch', 'pinches',
    'dash', 'dashes',
    'handful', 'handfuls',
    'splash', 'splashes',
    'drop', 'drops',
    'to taste',
    'as needed',
    'some',

    // Japanese
    'つまみ', 'ひとつまみ',
    '適量', '少々', '少量', '適宜',
  };

  // ============================================================
  // CANONICAL UNIT MAPPINGS
  // ============================================================

  static const Map<String, String> _canonicalUnits = {
    // Volume - Metric
    'ml': 'ml', 'milliliter': 'ml', 'milliliters': 'ml', 'millilitre': 'ml', 'millilitres': 'ml',
    'l': 'l', 'liter': 'l', 'liters': 'l', 'litre': 'l', 'litres': 'l',
    'cc': 'ml',

    // Volume - US
    'tsp': 'tsp', 'teaspoon': 'tsp', 'teaspoons': 'tsp', 't': 'tsp',
    'tbsp': 'tbsp', 'tablespoon': 'tbsp', 'tablespoons': 'tbsp', 'tbs': 'tbsp', 'T': 'tbsp',
    'fl oz': 'fl oz', 'fluid ounce': 'fl oz', 'fluid ounces': 'fl oz',
    'cup': 'cup', 'cups': 'cup', 'c': 'cup', 'C': 'cup',
    'pint': 'pint', 'pints': 'pint', 'pt': 'pint',
    'quart': 'quart', 'quarts': 'quart', 'qt': 'quart',
    'gallon': 'gallon', 'gallons': 'gallon', 'gal': 'gallon',

    // Volume - Japanese
    'カップ': 'カップ',
    '大さじ': '大さじ',
    '小さじ': '小さじ',
    '合': '合',
    '升': '升',
    '勺': '勺',

    // Weight - Metric
    'mg': 'mg', 'milligram': 'mg', 'milligrams': 'mg',
    'g': 'g', 'gram': 'g', 'grams': 'g', 'gr': 'g',
    'kg': 'kg', 'kilogram': 'kg', 'kilograms': 'kg', 'kilo': 'kg', 'kilos': 'kg',

    // Weight - Imperial
    'oz': 'oz', 'ounce': 'oz', 'ounces': 'oz',
    'lb': 'lb', 'lbs': 'lb', 'pound': 'lb', 'pounds': 'lb',

    // Weight - Japanese
    'グラム': 'g',
    'キログラム': 'kg',
    'キロ': 'kg',

    // Count units (map to themselves)
    'piece': 'piece', 'pieces': 'piece', 'pc': 'piece', 'pcs': 'piece',
    'slice': 'slice', 'slices': 'slice',
    'clove': 'clove', 'cloves': 'clove',
    'head': 'head', 'heads': 'head',
    'bunch': 'bunch', 'bunches': 'bunch',
    'sprig': 'sprig', 'sprigs': 'sprig',
    'stalk': 'stalk', 'stalks': 'stalk',
    'stick': 'stick', 'sticks': 'stick',
    'can': 'can', 'cans': 'can',
    'jar': 'jar', 'jars': 'jar',
    'package': 'package', 'packages': 'package', 'pkg': 'package', 'pkgs': 'package',
    'leaf': 'leaf', 'leaves': 'leaf',
  };

  // ============================================================
  // PREFERRED UNITS BY SYSTEM
  // ============================================================

  /// Preferred volume units for imperial system (in order of preference for display)
  static const List<(String unit, double mlThreshold)> _imperialVolumePreference = [
    ('gallon', 3000),   // Use gallon if >= 3L
    ('quart', 800),     // Use quart if >= 800ml
    ('pint', 400),      // Use pint if >= 400ml
    ('cup', 60),        // Use cup if >= 60ml (1/4 cup)
    ('tbsp', 10),       // Use tbsp if >= 10ml
    ('tsp', 0),         // Use tsp for small amounts
  ];

  /// Preferred volume units for metric system
  static const List<(String unit, double mlThreshold)> _metricVolumePreference = [
    ('l', 500),         // Use liters if >= 500ml
    ('ml', 0),          // Use ml for smaller amounts
  ];

  /// Preferred weight units for imperial system
  static const List<(String unit, double gramThreshold)> _imperialWeightPreference = [
    ('lb', 200),        // Use pounds if >= 200g
    ('oz', 0),          // Use ounces for smaller amounts
  ];

  /// Preferred weight units for metric system
  static const List<(String unit, double gramThreshold)> _metricWeightPreference = [
    ('kg', 500),        // Use kg if >= 500g
    ('g', 0),           // Use g for smaller amounts
  ];

  // ============================================================
  // PUBLIC API
  // ============================================================

  /// Get the unit type for a given unit string
  UnitType getUnitType(String unit) {
    final lowerUnit = unit.toLowerCase().trim();

    // Check volume units
    if (_volumeToMl.containsKey(lowerUnit) || _volumeToMl.containsKey(unit)) {
      return UnitType.volume;
    }

    // Check weight units
    if (_weightToGram.containsKey(lowerUnit) || _weightToGram.containsKey(unit)) {
      return UnitType.weight;
    }

    // Check count units
    if (_countUnits.contains(lowerUnit) || _countUnits.contains(unit)) {
      return UnitType.count;
    }

    // Check approximate terms
    if (_approximateTerms.contains(lowerUnit) || _approximateTerms.contains(unit)) {
      return UnitType.approximate;
    }

    return UnitType.unknown;
  }

  /// Get the canonical form of a unit
  String getCanonicalUnit(String unit) {
    final lowerUnit = unit.toLowerCase().trim();
    return _canonicalUnits[lowerUnit] ?? _canonicalUnits[unit] ?? unit;
  }

  /// Check if a unit is an approximate term (pinch, dash, to taste, etc.)
  bool isApproximateTerm(String unit) {
    final lowerUnit = unit.toLowerCase().trim();
    return _approximateTerms.contains(lowerUnit) || _approximateTerms.contains(unit);
  }

  /// Check if text contains any approximate terms.
  /// This checks for approximate terms anywhere in the text, not just as a unit.
  bool containsApproximateTerm(String text) {
    final lowerText = text.toLowerCase();
    for (final term in _approximateTerms) {
      if (lowerText.contains(term.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  /// Check if two units can be converted between each other
  bool areUnitsConvertible(String unit1, String unit2) {
    final type1 = getUnitType(unit1);
    final type2 = getUnitType(unit2);

    // Can only convert within same type, and only volume/weight
    if (type1 != type2) return false;
    return type1 == UnitType.volume || type1 == UnitType.weight;
  }

  /// Convert a value from one unit to another
  ConversionResult? convert({
    required double value,
    required String fromUnit,
    required String toUnit,
  }) {
    final fromType = getUnitType(fromUnit);
    final toType = getUnitType(toUnit);

    if (fromType != toType) return null;

    if (fromType == UnitType.volume) {
      return _convertVolume(value, fromUnit, toUnit);
    } else if (fromType == UnitType.weight) {
      return _convertWeight(value, fromUnit, toUnit);
    }

    // Count/approximate units can't be converted
    return null;
  }

  /// Convert to the best unit in a target measurement system
  ConversionResult convertToSystem({
    required double value,
    required String fromUnit,
    required ConversionMode targetSystem,
  }) {
    // If original mode, return unchanged
    if (targetSystem == ConversionMode.original) {
      return ConversionResult(
        value: value,
        unit: fromUnit,
        canonicalUnit: getCanonicalUnit(fromUnit),
      );
    }

    final unitType = getUnitType(fromUnit);

    // Non-convertible units pass through unchanged
    if (unitType == UnitType.count ||
        unitType == UnitType.approximate ||
        unitType == UnitType.unknown) {
      return ConversionResult(
        value: value,
        unit: fromUnit,
        canonicalUnit: getCanonicalUnit(fromUnit),
      );
    }

    if (unitType == UnitType.volume) {
      return _convertVolumeToSystem(value, fromUnit, targetSystem);
    } else {
      return _convertWeightToSystem(value, fromUnit, targetSystem);
    }
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  ConversionResult? _convertVolume(double value, String fromUnit, String toUnit) {
    final fromMl = _getVolumeInMl(fromUnit);
    final toMl = _getVolumeInMl(toUnit);

    if (fromMl == null || toMl == null) return null;

    final valueInMl = value * fromMl;
    final convertedValue = valueInMl / toMl;

    return ConversionResult(
      value: convertedValue,
      unit: toUnit,
      canonicalUnit: getCanonicalUnit(toUnit),
    );
  }

  ConversionResult? _convertWeight(double value, String fromUnit, String toUnit) {
    final fromGram = _getWeightInGram(fromUnit);
    final toGram = _getWeightInGram(toUnit);

    if (fromGram == null || toGram == null) return null;

    final valueInGram = value * fromGram;
    final convertedValue = valueInGram / toGram;

    return ConversionResult(
      value: convertedValue,
      unit: toUnit,
      canonicalUnit: getCanonicalUnit(toUnit),
    );
  }

  ConversionResult _convertVolumeToSystem(
    double value,
    String fromUnit,
    ConversionMode targetSystem,
  ) {
    final fromMl = _getVolumeInMl(fromUnit);
    if (fromMl == null) {
      return ConversionResult(
        value: value,
        unit: fromUnit,
        canonicalUnit: getCanonicalUnit(fromUnit),
      );
    }

    final valueInMl = value * fromMl;

    // Select preference list based on target system
    final preferences = targetSystem == ConversionMode.imperial
        ? _imperialVolumePreference
        : _metricVolumePreference;

    // Find the best unit based on thresholds
    for (final (unit, threshold) in preferences) {
      if (valueInMl >= threshold) {
        final targetMl = _getVolumeInMl(unit)!;
        final convertedValue = valueInMl / targetMl;
        return ConversionResult(
          value: convertedValue,
          unit: unit,
          canonicalUnit: getCanonicalUnit(unit),
        );
      }
    }

    // Fallback to smallest unit
    final (unit, _) = preferences.last;
    final targetMl = _getVolumeInMl(unit)!;
    return ConversionResult(
      value: valueInMl / targetMl,
      unit: unit,
      canonicalUnit: getCanonicalUnit(unit),
    );
  }

  ConversionResult _convertWeightToSystem(
    double value,
    String fromUnit,
    ConversionMode targetSystem,
  ) {
    final fromGram = _getWeightInGram(fromUnit);
    if (fromGram == null) {
      return ConversionResult(
        value: value,
        unit: fromUnit,
        canonicalUnit: getCanonicalUnit(fromUnit),
      );
    }

    final valueInGram = value * fromGram;

    // Select preference list based on target system
    final preferences = targetSystem == ConversionMode.imperial
        ? _imperialWeightPreference
        : _metricWeightPreference;

    // Find the best unit based on thresholds
    for (final (unit, threshold) in preferences) {
      if (valueInGram >= threshold) {
        final targetGram = _getWeightInGram(unit)!;
        final convertedValue = valueInGram / targetGram;
        return ConversionResult(
          value: convertedValue,
          unit: unit,
          canonicalUnit: getCanonicalUnit(unit),
        );
      }
    }

    // Fallback to smallest unit
    final (unit, _) = preferences.last;
    final targetGram = _getWeightInGram(unit)!;
    return ConversionResult(
      value: valueInGram / targetGram,
      unit: unit,
      canonicalUnit: getCanonicalUnit(unit),
    );
  }

  double? _getVolumeInMl(String unit) {
    final lowerUnit = unit.toLowerCase().trim();
    return _volumeToMl[lowerUnit] ?? _volumeToMl[unit];
  }

  double? _getWeightInGram(String unit) {
    final lowerUnit = unit.toLowerCase().trim();
    return _weightToGram[lowerUnit] ?? _weightToGram[unit];
  }
}
