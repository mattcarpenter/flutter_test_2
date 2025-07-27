/// Service for parsing ingredient strings to identify quantities and units
/// for visual highlighting and future scaling features.
class IngredientParserService {
  final RegexBuilder _regexBuilder;
  
  IngredientParserService({
    List<UnitDefinition>? customUnits,
  }) : _regexBuilder = RegexBuilder(customUnits ?? IngredientParserConfig.englishUnits);
  
  /// Parses an ingredient string and returns quantity spans and clean name
  IngredientParseResult parse(String input) {
    if (input.trim().isEmpty) {
      return IngredientParseResult(
        originalText: input,
        quantities: [],
        cleanName: '',
      );
    }
    
    final quantities = <QuantitySpan>[];
    var remainingText = input;
    
    // Find all quantity matches
    final allMatches = <_QuantityMatch>[];
    
    // Check for ranges first (they contain more specific patterns)
    allMatches.addAll(_findRanges(input));
    
    // Then check for single quantities
    allMatches.addAll(_findSingleQuantities(input, allMatches));
    
    // Check for approximate quantities
    allMatches.addAll(_findApproximateQuantities(input, allMatches));
    
    // Sort by start position
    allMatches.sort((a, b) => a.start.compareTo(b.start));
    
    // Convert to QuantitySpan objects
    for (final match in allMatches) {
      quantities.add(QuantitySpan(
        start: match.start,
        end: match.end,
        text: match.text,
      ));
    }
    
    // Extract clean ingredient name by removing all matched quantities
    String cleanName = input;
    for (final span in quantities.reversed) {
      cleanName = cleanName.replaceRange(span.start, span.end, ' ');
    }
    
    // Clean up the name
    cleanName = cleanName
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^\s*,\s*'), '')
        .replaceAll(RegExp(r'^\s*\+\s*'), '')
        .replaceAll(RegExp(r'^\s*of\s+', caseSensitive: false), '')
        .trim();
    
    return IngredientParseResult(
      originalText: input,
      quantities: quantities,
      cleanName: cleanName,
    );
  }
  
  List<_QuantityMatch> _findRanges(String input) {
    final matches = <_QuantityMatch>[];
    
    // Match patterns like "2-3 cups" or "1 to 2 tablespoons"
    final rangeMatches = _regexBuilder.rangePattern.allMatches(input);
    for (final match in rangeMatches) {
      matches.add(_QuantityMatch(
        start: match.start,
        end: match.end,
        text: match.group(0)!,
      ));
    }
    
    return matches;
  }
  
  List<_QuantityMatch> _findSingleQuantities(String input, List<_QuantityMatch> existingMatches) {
    final matches = <_QuantityMatch>[];
    
    // Find all single quantity matches
    final quantityMatches = _regexBuilder.quantityPattern.allMatches(input);
    
    for (final match in quantityMatches) {
      // Skip if this position is already covered by a range
      bool overlaps = false;
      for (final existing in existingMatches) {
        if (match.start >= existing.start && match.start < existing.end) {
          overlaps = true;
          break;
        }
      }
      
      if (!overlaps) {
        matches.add(_QuantityMatch(
          start: match.start,
          end: match.end,
          text: match.group(0)!,
        ));
      }
    }
    
    return matches;
  }
  
  List<_QuantityMatch> _findApproximateQuantities(String input, List<_QuantityMatch> existingMatches) {
    final matches = <_QuantityMatch>[];
    
    // Match approximate quantities
    final approxMatches = _regexBuilder.approximatePattern.allMatches(input);
    
    for (final match in approxMatches) {
      // Skip if this position is already covered
      bool overlaps = false;
      for (final existing in existingMatches) {
        if (match.start >= existing.start && match.start < existing.end) {
          overlaps = true;
          break;
        }
      }
      
      if (!overlaps) {
        matches.add(_QuantityMatch(
          start: match.start,
          end: match.end,
          text: match.group(0)!,
        ));
      }
    }
    
    return matches;
  }
}

/// Helper class for internal match tracking
class _QuantityMatch {
  final int start;
  final int end;
  final String text;
  
  _QuantityMatch({
    required this.start,
    required this.end,
    required this.text,
  });
}

/// Result of parsing an ingredient string
class IngredientParseResult {
  final String originalText;
  final List<QuantitySpan> quantities;
  final String cleanName;
  
  IngredientParseResult({
    required this.originalText,
    required this.quantities,
    required this.cleanName,
  });
}

/// Represents a quantity found in the ingredient string
class QuantitySpan {
  final int start;
  final int end;
  final String text;
  
  QuantitySpan({
    required this.start,
    required this.end,
    required this.text,
  });
}

/// Definition of a unit and its variations
class UnitDefinition {
  final String canonical;
  final List<String> variations;
  
  const UnitDefinition({
    required this.canonical,
    required this.variations,
  });
}

/// Configuration for ingredient parsing
class IngredientParserConfig {
  static const List<UnitDefinition> englishUnits = [
    // Volume - Cups
    UnitDefinition(
      canonical: 'cup',
      variations: ['cup', 'cups', 'c', 'C'],
    ),
    UnitDefinition(
      canonical: 'tablespoon',
      variations: ['tablespoon', 'tablespoons', 'tbsp', 'Tbsp', 'TBSP', 'T', 'tbs', 'tbls'],
    ),
    UnitDefinition(
      canonical: 'teaspoon',
      variations: ['teaspoon', 'teaspoons', 'tsp', 'Tsp', 'TSP', 't'],
    ),
    
    // Volume - Metric
    UnitDefinition(
      canonical: 'liter',
      variations: ['liter', 'liters', 'litre', 'litres', 'l', 'L'],
    ),
    UnitDefinition(
      canonical: 'milliliter',
      variations: ['milliliter', 'milliliters', 'millilitre', 'millilitres', 'ml', 'mL', 'ML'],
    ),
    
    // Volume - Other
    UnitDefinition(
      canonical: 'fluid ounce',
      variations: ['fluid ounce', 'fluid ounces', 'fl oz', 'fl. oz.', 'fl oz.', 'fl.oz.'],
    ),
    UnitDefinition(
      canonical: 'pint',
      variations: ['pint', 'pints', 'pt'],
    ),
    UnitDefinition(
      canonical: 'quart',
      variations: ['quart', 'quarts', 'qt'],
    ),
    UnitDefinition(
      canonical: 'gallon',
      variations: ['gallon', 'gallons', 'gal'],
    ),
    
    // Weight - Imperial
    UnitDefinition(
      canonical: 'pound',
      variations: ['pound', 'pounds', 'lb', 'lbs', 'lb.', 'lbs.', '#'],
    ),
    UnitDefinition(
      canonical: 'ounce',
      variations: ['ounce', 'ounces', 'oz', 'oz.'],
    ),
    
    // Weight - Metric
    UnitDefinition(
      canonical: 'gram',
      variations: ['gram', 'grams', 'g', 'gr'],
    ),
    UnitDefinition(
      canonical: 'kilogram',
      variations: ['kilogram', 'kilograms', 'kg', 'kilo', 'kilos'],
    ),
    UnitDefinition(
      canonical: 'milligram',
      variations: ['milligram', 'milligrams', 'mg'],
    ),
    
    // Count/Pieces
    UnitDefinition(
      canonical: 'piece',
      variations: ['piece', 'pieces', 'pc', 'pcs'],
    ),
    UnitDefinition(
      canonical: 'clove',
      variations: ['clove', 'cloves'],
    ),
    UnitDefinition(
      canonical: 'slice',
      variations: ['slice', 'slices'],
    ),
    UnitDefinition(
      canonical: 'can',
      variations: ['can', 'cans'],
    ),
    UnitDefinition(
      canonical: 'jar',
      variations: ['jar', 'jars'],
    ),
    UnitDefinition(
      canonical: 'package',
      variations: ['package', 'packages', 'pkg', 'pkgs'],
    ),
    UnitDefinition(
      canonical: 'bunch',
      variations: ['bunch', 'bunches'],
    ),
    UnitDefinition(
      canonical: 'stick',
      variations: ['stick', 'sticks'],
    ),
    
    // Approximate
    UnitDefinition(
      canonical: 'pinch',
      variations: ['pinch', 'pinches'],
    ),
    UnitDefinition(
      canonical: 'dash',
      variations: ['dash', 'dashes'],
    ),
    UnitDefinition(
      canonical: 'handful',
      variations: ['handful', 'handfuls'],
    ),
    UnitDefinition(
      canonical: 'splash',
      variations: ['splash', 'splashes'],
    ),
    UnitDefinition(
      canonical: 'drop',
      variations: ['drop', 'drops'],
    ),
  ];
  
  static const List<String> approximateTerms = [
    'to taste',
    'as needed',
    'as required',
    'for dusting',
    'for garnish',
    'for serving',
    'optional',
    'or more',
    'or less',
    'approximately',
    'about',
    'around',
    'roughly',
  ];
}

/// Builds regex patterns from unit definitions
class RegexBuilder {
  late final RegExp quantityPattern;
  late final RegExp rangePattern;
  late final RegExp approximatePattern;
  
  RegexBuilder(List<UnitDefinition> units) {
    // Build unit variations pattern - sort by length (longest first)
    final allVariations = units
        .expand((u) => u.variations)
        .map((v) => RegExp.escape(v))
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    
    final unitsPattern = '(' + allVariations.join('|') + ')';
    
    // Fraction pattern: handles 1/2, 1 1/2, etc.
    const fractionPart = r'(?:\d+\s+)?(?:\d+/\d+)';
    const decimalPart = r'\d+(?:\.\d+)?';
    const numberPattern = '(?:$fractionPart|$decimalPart)';
    
    // Single quantity pattern - with optional space between number and unit
    // Updated to better handle word boundaries and spaces
    quantityPattern = RegExp(
      numberPattern + r'\s*' + unitsPattern + r'(?=\s|,|$|\))',
      caseSensitive: false,
    );
    
    // Range pattern - "2-3 cups" or "1 to 2 tablespoons"
    rangePattern = RegExp(
      numberPattern + r'\s*(?:-|–|to)\s*' + numberPattern + r'\s*' + unitsPattern + r'(?=\s|,|$|\))',
      caseSensitive: false,
    );
    
    // Approximate terms pattern
    final approxTerms = IngredientParserConfig.approximateTerms
        .map((t) => RegExp.escape(t))
        .join('|');
    
    approximatePattern = RegExp(
      r'(?:^|\s)(' + approxTerms + r')(?:\s|,|$)',
      caseSensitive: false,
    );
  }
}

/// Extension to handle scaling of ingredient strings
extension IngredientScaling on String {
  String scaleIngredient(double scale, IngredientParserService parser) {
    final parsed = parser.parse(this);
    if (parsed.quantities.isEmpty) {
      return this;
    }
    
    var scaled = this;
    
    // Process in reverse order to preserve indices
    for (final span in parsed.quantities.reversed) {
      final scaledText = _scaleQuantityText(span.text, scale);
      scaled = scaled.replaceRange(span.start, span.end, scaledText);
    }
    
    return scaled;
  }
  
  String _scaleQuantityText(String quantityText, double scale) {
    // Handle ranges like "2-3 cups"
    final rangeMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:-|–|to)\s*(\d+(?:\.\d+)?)(\s*.*)').firstMatch(quantityText);
    if (rangeMatch != null) {
      final min = double.parse(rangeMatch.group(1)!);
      final max = double.parse(rangeMatch.group(2)!);
      final remainder = rangeMatch.group(3)!;
      
      final scaledMin = _formatNumber(min * scale);
      final scaledMax = _formatNumber(max * scale);
      
      return '$scaledMin-$scaledMax$remainder';
    }
    
    // Handle fractions like "1 1/2 cups"
    final mixedFractionMatch = RegExp(r'(\d+)\s+(\d+)/(\d+)(\s*.*)').firstMatch(quantityText);
    if (mixedFractionMatch != null) {
      final whole = int.parse(mixedFractionMatch.group(1)!);
      final numerator = int.parse(mixedFractionMatch.group(2)!);
      final denominator = int.parse(mixedFractionMatch.group(3)!);
      final remainder = mixedFractionMatch.group(4)!;
      
      final value = whole + numerator / denominator;
      final scaledValue = value * scale;
      
      return _formatNumber(scaledValue) + remainder;
    }
    
    // Handle simple fractions like "1/2 cup"
    final fractionMatch = RegExp(r'(\d+)/(\d+)(\s*.*)').firstMatch(quantityText);
    if (fractionMatch != null) {
      final numerator = int.parse(fractionMatch.group(1)!);
      final denominator = int.parse(fractionMatch.group(2)!);
      final remainder = fractionMatch.group(3)!;
      
      final value = numerator / denominator;
      final scaledValue = value * scale;
      
      return _formatNumber(scaledValue) + remainder;
    }
    
    // Handle decimals and whole numbers
    final numberMatch = RegExp(r'(\d+(?:\.\d+)?)(\s*.*)').firstMatch(quantityText);
    if (numberMatch != null) {
      final value = double.parse(numberMatch.group(1)!);
      final remainder = numberMatch.group(2)!;
      
      final scaledValue = value * scale;
      return _formatNumber(scaledValue) + remainder;
    }
    
    // Can't scale this (e.g., "to taste")
    return quantityText;
  }
  
  String _formatNumber(double value) {
    // Convert to nice fractions when possible
    if (value == value.truncate()) {
      return value.toInt().toString();
    }
    
    // Check for common fractions
    final fractions = [
      (0.25, '1/4'),
      (0.33, '1/3'),
      (0.5, '1/2'),
      (0.66, '2/3'),
      (0.67, '2/3'),
      (0.75, '3/4'),
    ];
    
    // Check for mixed fractions first if value > 1
    if (value > 1) {
      final whole = value.truncate();
      final remainder = value - whole;
      
      for (final (decimal, fraction) in fractions) {
        if ((remainder - decimal).abs() < 0.01) {
          return '$whole $fraction';
        }
      }
    }
    
    // Check for simple fractions
    for (final (decimal, fraction) in fractions) {
      if ((value - decimal).abs() < 0.01) {
        return fraction;
      }
    }
    
    // Return as decimal, but remove unnecessary decimals
    if (value == value.toInt().toDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }
}