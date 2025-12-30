import '../features/recipes/models/scale_convert_state.dart';
import 'unit_conversion_service.dart';

/// Supported languages for ingredient parsing
enum Language {
  english,
  japanese,
}

/// Normalizes full-width characters to their ASCII equivalents.
/// This is essential for parsing Japanese text that often uses full-width numbers.
String _normalizeFullWidth(String input) {
  final buffer = StringBuffer();
  for (final codeUnit in input.runes) {
    // Full-width digits ０-９ (U+FF10-U+FF19) -> 0-9
    if (codeUnit >= 0xFF10 && codeUnit <= 0xFF19) {
      buffer.writeCharCode(codeUnit - 0xFF10 + 0x30);
    }
    // Full-width slash ／ (U+FF0F) -> /
    else if (codeUnit == 0xFF0F) {
      buffer.write('/');
    }
    // Full-width period ． (U+FF0E) -> .
    else if (codeUnit == 0xFF0E) {
      buffer.write('.');
    }
    // Wave dash 〜 (U+301C) -> -
    else if (codeUnit == 0x301C) {
      buffer.write('-');
    }
    // Fullwidth tilde ～ (U+FF5E) -> -
    else if (codeUnit == 0xFF5E) {
      buffer.write('-');
    }
    // Japanese zero 〇 (U+3007) -> 0
    else if (codeUnit == 0x3007) {
      buffer.write('0');
    }
    else {
      buffer.writeCharCode(codeUnit);
    }
  }
  return buffer.toString();
}

/// Service for parsing ingredient strings to identify quantities and units
/// for visual highlighting and future scaling features.
class IngredientParserService {
  final Language primaryLanguage;
  final Map<Language, RegexBuilder> _builders;
  
  IngredientParserService({
    this.primaryLanguage = Language.english,
    Map<Language, List<UnitDefinition>>? customUnits,
  }) : _builders = {
    for (final language in Language.values)
      language: RegexBuilder(
        language,
        customUnits?[language] ?? IngredientParserConfig.getUnitsForLanguage(language),
      ),
  };
  
  /// Detects the language of the input text based on character patterns
  Language detectLanguage(String input) {
    // Japanese characters (Hiragana: 3040-309F, Katakana: 30A0-30FF, Kanji: 4E00-9FAF)
    if (RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]').hasMatch(input)) {
      return Language.japanese;
    }
    return Language.english; // Default fallback
  }
  
  /// Parses an ingredient string and returns quantity spans and clean name
  IngredientParseResult parse(String input) {
    if (input.trim().isEmpty) {
      return IngredientParseResult(
        originalText: input,
        quantities: [],
        cleanName: '',
      );
    }

    // Normalize full-width characters to ASCII equivalents for consistent parsing
    // This converts ０-９ -> 0-9, ／ -> /, ． -> ., 〜/～ -> -, 〇 -> 0
    final normalizedInput = _normalizeFullWidth(input);

    // Auto-detect language from character patterns
    final detectedLanguage = detectLanguage(normalizedInput);

    // Try detected language first
    final result = _parseWithLanguage(normalizedInput, detectedLanguage, input);
    if (result.quantities.isNotEmpty) {
      return result;
    }

    // Fallback to primary language if nothing found and languages differ
    if (detectedLanguage != primaryLanguage) {
      return _parseWithLanguage(normalizedInput, primaryLanguage, input);
    }

    return result; // Return empty result if both attempts failed
  }
  
  /// Parses input using a specific language's patterns.
  /// [input] is the normalized text used for pattern matching.
  /// [originalInput] is the original text, used for the result's originalText
  /// and for extracting the matched text with original characters preserved.
  IngredientParseResult _parseWithLanguage(String input, Language language, [String? originalInput]) {
    final regexBuilder = _builders[language]!;
    final quantities = <QuantitySpan>[];
    final original = originalInput ?? input;

    // Find all quantity matches
    final allMatches = <_QuantityMatch>[];

    // Check for unit-before-number patterns first (Japanese: 大さじ3)
    if (language == Language.japanese) {
      allMatches.addAll(_findUnitBeforeNumber(input, regexBuilder));
    }

    // Check for ranges (they contain more specific patterns)
    allMatches.addAll(_findRanges(input, regexBuilder));

    // Then check for single quantities
    allMatches.addAll(_findSingleQuantities(input, allMatches, regexBuilder));

    // Check for approximate quantities
    allMatches.addAll(_findApproximateQuantities(input, allMatches, regexBuilder));

    // Check for bare numbers at the start (e.g. "1 onion", "2 eggs")
    allMatches.addAll(_findBareNumbers(input, allMatches, language));

    // Sort by start position
    allMatches.sort((a, b) => a.start.compareTo(b.start));

    // Convert to QuantitySpan objects, using original text for the span text
    for (final match in allMatches) {
      quantities.add(QuantitySpan(
        start: match.start,
        end: match.end,
        text: original.substring(match.start, match.end),
      ));
    }

    // Extract clean ingredient name by removing all matched quantities
    String cleanName = original;
    for (final span in quantities.reversed) {
      cleanName = cleanName.replaceRange(span.start, span.end, ' ');
    }

    // Clean up the name (language-specific cleaning)
    cleanName = _cleanIngredientName(cleanName, language);

    return IngredientParseResult(
      originalText: original,
      quantities: quantities,
      cleanName: cleanName,
    );
  }
  
  /// Cleans ingredient name with language-specific rules
  String _cleanIngredientName(String name, Language language) {
    name = name.replaceAll(RegExp(r'\s+'), ' ');

    switch (language) {
      case Language.english:
        return name
            .replaceAll(RegExp(r'^\s*,\s*'), '')
            .replaceAll(RegExp(r'^\s*\+\s*'), '')
            .replaceAll(RegExp(r'^\s*of\s+', caseSensitive: false), '')
            .trim();
      case Language.japanese:
        // Japanese-specific cleaning rules
        return name
            .replaceAll(RegExp(r'^\s*、\s*'), '') // Japanese comma
            .replaceAll(RegExp(r'^\s*の\s*'), '') // Japanese possessive particle
            .trim();
    }
  }

  // ============================================================
  // ENHANCED PARSING WITH NUMERIC VALUES AND UNIT TYPES
  // ============================================================

  /// Parses an ingredient string and returns enhanced quantity data with
  /// numeric values, unit types, and canonical units.
  EnhancedParseResult parseEnhanced(String input, {UnitConversionService? conversionService}) {
    final basicResult = parse(input);
    final converter = conversionService ?? UnitConversionService();

    if (basicResult.quantities.isEmpty) {
      return EnhancedParseResult(
        originalText: input,
        quantities: [],
        ingredientName: basicResult.cleanName,
      );
    }

    final enhancedQuantities = <ParsedQuantity>[];

    for (final span in basicResult.quantities) {
      final parsed = _parseQuantityText(span.text, converter);
      if (parsed != null) {
        enhancedQuantities.add(ParsedQuantity(
          value: parsed.value,
          rangeMax: parsed.rangeMax,
          unit: parsed.unit,
          canonicalUnit: parsed.canonicalUnit,
          unitType: parsed.unitType,
          startIndex: span.start,
          endIndex: span.end,
          originalText: span.text,
        ));
      }
    }

    return EnhancedParseResult(
      originalText: input,
      quantities: enhancedQuantities,
      ingredientName: basicResult.cleanName,
    );
  }

  /// Parses a quantity text string (e.g., "2 cups", "1/2 tsp") and extracts
  /// numeric value, unit, and unit type.
  _ParsedQuantityData? _parseQuantityText(String text, UnitConversionService converter) {
    // Normalize full-width characters to ASCII for consistent parsing
    final normalizedText = _normalizeFullWidth(text);

    // Try unit-before-number patterns first (Japanese: 大さじ3, 小さじ1/2)
    final unitBeforeResult = _parseUnitBeforeNumber(normalizedText, converter);
    if (unitBeforeResult != null) {
      return unitBeforeResult;
    }

    // Handle ranges like "2-3 cups"
    final rangeMatch = RegExp(r'^(\d+(?:\.\d+)?)\s*(?:-|–|to)\s*(\d+(?:\.\d+)?)\s*(.+)$').firstMatch(normalizedText);
    if (rangeMatch != null) {
      final minValue = double.tryParse(rangeMatch.group(1)!);
      final maxValue = double.tryParse(rangeMatch.group(2)!);
      final unitText = rangeMatch.group(3)!.trim();
      if (minValue != null && maxValue != null) {
        return _ParsedQuantityData(
          value: minValue,
          rangeMax: maxValue,
          unit: unitText,
          canonicalUnit: converter.getCanonicalUnit(unitText),
          unitType: converter.getUnitType(unitText),
        );
      }
    }

    // Handle mixed fractions like "1 1/2 cups"
    final mixedFractionMatch = RegExp(r'^(\d+)\s+(\d+)/(\d+)\s*(.*)$').firstMatch(normalizedText);
    if (mixedFractionMatch != null) {
      final whole = int.tryParse(mixedFractionMatch.group(1)!);
      final numerator = int.tryParse(mixedFractionMatch.group(2)!);
      final denominator = int.tryParse(mixedFractionMatch.group(3)!);
      final unitText = mixedFractionMatch.group(4)!.trim();
      if (whole != null && numerator != null && denominator != null && denominator != 0) {
        final value = whole + numerator / denominator;
        return _ParsedQuantityData(
          value: value,
          unit: unitText,
          canonicalUnit: converter.getCanonicalUnit(unitText),
          unitType: unitText.isEmpty ? UnitType.count : converter.getUnitType(unitText),
        );
      }
    }

    // Handle simple fractions like "1/2 cup"
    final fractionMatch = RegExp(r'^(\d+)/(\d+)\s*(.*)$').firstMatch(normalizedText);
    if (fractionMatch != null) {
      final numerator = int.tryParse(fractionMatch.group(1)!);
      final denominator = int.tryParse(fractionMatch.group(2)!);
      final unitText = fractionMatch.group(3)!.trim();
      if (numerator != null && denominator != null && denominator != 0) {
        final value = numerator / denominator;
        return _ParsedQuantityData(
          value: value,
          unit: unitText,
          canonicalUnit: converter.getCanonicalUnit(unitText),
          unitType: unitText.isEmpty ? UnitType.count : converter.getUnitType(unitText),
        );
      }
    }

    // Handle Unicode fractions like "½ cup" or "1½ cups"
    final unicodeFractionMatch = RegExp(r'^(\d+\s*)?([½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞半])\s*(.*)$').firstMatch(normalizedText);
    if (unicodeFractionMatch != null) {
      final wholeStr = unicodeFractionMatch.group(1)?.trim();
      final fractionChar = unicodeFractionMatch.group(2)!;
      final unitText = unicodeFractionMatch.group(3)!.trim();

      final whole = (wholeStr != null && wholeStr.isNotEmpty) ? double.tryParse(wholeStr) ?? 0.0 : 0.0;
      final fractionValue = _unicodeFractionToDecimal(fractionChar);
      final value = whole + fractionValue;

      return _ParsedQuantityData(
        value: value,
        unit: unitText,
        canonicalUnit: converter.getCanonicalUnit(unitText),
        unitType: unitText.isEmpty ? UnitType.count : converter.getUnitType(unitText),
      );
    }

    // Handle Japanese numbers with optional half (including compound numbers like 十二, 二十三, 百, 千)
    final japaneseNumberMatch = RegExp(r'^([一二三四五六七八九十百千]+(?:半)?|\d+半|半)\s*(.*)$').firstMatch(normalizedText);
    if (japaneseNumberMatch != null) {
      final numberPart = japaneseNumberMatch.group(1)!;
      final unitText = japaneseNumberMatch.group(2)!.trim();
      final value = _parseJapaneseNumber(numberPart);
      if (value != null) {
        return _ParsedQuantityData(
          value: value,
          unit: unitText,
          canonicalUnit: converter.getCanonicalUnit(unitText),
          unitType: unitText.isEmpty ? UnitType.count : converter.getUnitType(unitText),
        );
      }
    }

    // Handle decimals and whole numbers like "2 cups" or "1.5 tbsp"
    final numberMatch = RegExp(r'^(\d+(?:\.\d+)?)\s*(.*)$').firstMatch(normalizedText);
    if (numberMatch != null) {
      final value = double.tryParse(numberMatch.group(1)!);
      final unitText = numberMatch.group(2)!.trim();
      if (value != null) {
        return _ParsedQuantityData(
          value: value,
          unit: unitText,
          canonicalUnit: converter.getCanonicalUnit(unitText),
          unitType: unitText.isEmpty ? UnitType.count : converter.getUnitType(unitText),
        );
      }
    }

    // Handle bare numbers (no unit) like just "2" at start
    final bareNumberMatch = RegExp(r'^(\d+)$').firstMatch(normalizedText.trim());
    if (bareNumberMatch != null) {
      final value = double.tryParse(bareNumberMatch.group(1)!);
      if (value != null) {
        return _ParsedQuantityData(
          value: value,
          unit: '',
          canonicalUnit: '',
          unitType: UnitType.count,
        );
      }
    }

    return null;
  }

  /// Parses unit-before-number patterns like 大さじ3, 小さじ1/2, 大さじ1-2
  _ParsedQuantityData? _parseUnitBeforeNumber(String text, UnitConversionService converter) {
    // Units that can appear before numbers in Japanese
    const unitBeforeNumberUnits = ['大さじ', '大匙', 'おおさじ', '小さじ', '小匙', 'こさじ', 'カップ'];

    for (final unit in unitBeforeNumberUnits) {
      if (!text.startsWith(unit)) continue;

      final remainder = text.substring(unit.length);
      if (remainder.isEmpty) continue;

      // Try range: 大さじ1-2
      final rangeMatch = RegExp(r'^(\d+(?:\.\d+)?)\s*(?:-|–|to)\s*(\d+(?:\.\d+)?)([弱強])?$').firstMatch(remainder);
      if (rangeMatch != null) {
        final minValue = double.tryParse(rangeMatch.group(1)!);
        final maxValue = double.tryParse(rangeMatch.group(2)!);
        if (minValue != null && maxValue != null) {
          return _ParsedQuantityData(
            value: minValue,
            rangeMax: maxValue,
            unit: unit,
            canonicalUnit: converter.getCanonicalUnit(unit),
            unitType: converter.getUnitType(unit),
          );
        }
      }

      // Try mixed fraction: 大さじ1 1/2
      final mixedFractionMatch = RegExp(r'^(\d+)\s+(\d+)/(\d+)([弱強])?$').firstMatch(remainder);
      if (mixedFractionMatch != null) {
        final whole = int.tryParse(mixedFractionMatch.group(1)!);
        final numerator = int.tryParse(mixedFractionMatch.group(2)!);
        final denominator = int.tryParse(mixedFractionMatch.group(3)!);
        if (whole != null && numerator != null && denominator != null && denominator != 0) {
          final value = whole + numerator / denominator;
          return _ParsedQuantityData(
            value: value,
            unit: unit,
            canonicalUnit: converter.getCanonicalUnit(unit),
            unitType: converter.getUnitType(unit),
          );
        }
      }

      // Try simple fraction: 大さじ1/2
      final fractionMatch = RegExp(r'^(\d+)/(\d+)([弱強])?$').firstMatch(remainder);
      if (fractionMatch != null) {
        final numerator = int.tryParse(fractionMatch.group(1)!);
        final denominator = int.tryParse(fractionMatch.group(2)!);
        if (numerator != null && denominator != null && denominator != 0) {
          final value = numerator / denominator;
          return _ParsedQuantityData(
            value: value,
            unit: unit,
            canonicalUnit: converter.getCanonicalUnit(unit),
            unitType: converter.getUnitType(unit),
          );
        }
      }

      // Try unicode fraction: 大さじ½
      final unicodeFractionMatch = RegExp(r'^(\d*\s*)?([½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞半])([弱強])?$').firstMatch(remainder);
      if (unicodeFractionMatch != null) {
        final wholeStr = unicodeFractionMatch.group(1)?.trim();
        final fractionChar = unicodeFractionMatch.group(2)!;
        final whole = (wholeStr != null && wholeStr.isNotEmpty) ? double.tryParse(wholeStr) ?? 0.0 : 0.0;
        final fractionValue = _unicodeFractionToDecimal(fractionChar);
        final value = whole + fractionValue;
        return _ParsedQuantityData(
          value: value,
          unit: unit,
          canonicalUnit: converter.getCanonicalUnit(unit),
          unitType: converter.getUnitType(unit),
        );
      }

      // Try Kanji number: 大さじ二
      final kanjiMatch = RegExp(r'^([一二三四五六七八九十百千]+(?:半)?|半)([弱強])?$').firstMatch(remainder);
      if (kanjiMatch != null) {
        final numberPart = kanjiMatch.group(1)!;
        final value = _parseJapaneseNumber(numberPart);
        if (value != null) {
          return _ParsedQuantityData(
            value: value,
            unit: unit,
            canonicalUnit: converter.getCanonicalUnit(unit),
            unitType: converter.getUnitType(unit),
          );
        }
      }

      // Try decimal/whole number: 大さじ3, 大さじ1.5
      final numberMatch = RegExp(r'^(\d+(?:\.\d+)?)([弱強])?$').firstMatch(remainder);
      if (numberMatch != null) {
        final value = double.tryParse(numberMatch.group(1)!);
        if (value != null) {
          return _ParsedQuantityData(
            value: value,
            unit: unit,
            canonicalUnit: converter.getCanonicalUnit(unit),
            unitType: converter.getUnitType(unit),
          );
        }
      }
    }

    return null;
  }

  /// Converts Unicode fraction characters to decimal values
  static double _unicodeFractionToDecimal(String char) {
    const fractionMap = {
      '½': 0.5,
      '⅓': 1/3,
      '⅔': 2/3,
      '¼': 0.25,
      '¾': 0.75,
      '⅕': 0.2,
      '⅖': 0.4,
      '⅗': 0.6,
      '⅘': 0.8,
      '⅙': 1/6,
      '⅚': 5/6,
      '⅛': 0.125,
      '⅜': 0.375,
      '⅝': 0.625,
      '⅞': 0.875,
      '半': 0.5,
    };
    return fractionMap[char] ?? 0.0;
  }

  /// Parses Japanese numbers (Kanji and Arabic) with half support.
  /// Handles compound Kanji numbers like 十二 (12), 二十 (20), 二十三 (23),
  /// 百 (100), 千 (1000), and combinations with 半.
  static double? _parseJapaneseNumber(String input) {
    if (input.trim().isEmpty) return null;

    // Handle pure "半" (half)
    if (input == '半') return 0.5;

    // Handle Arabic numbers with half: "2半" → 2.5
    final arabicHalfMatch = RegExp(r'(\d+(?:\.\d+)?)半').firstMatch(input);
    if (arabicHalfMatch != null) {
      final number = double.tryParse(arabicHalfMatch.group(1)!);
      return number != null ? number + 0.5 : null;
    }

    // Handle pure Arabic numbers
    final arabicMatch = RegExp(r'^\d+(?:\.\d+)?$').firstMatch(input);
    if (arabicMatch != null) {
      return double.tryParse(input);
    }

    // Handle Kanji numbers with optional half suffix
    final hasHalf = input.endsWith('半');
    final kanjiPart = hasHalf ? input.substring(0, input.length - 1) : input;

    final kanjiValue = _parseKanjiNumber(kanjiPart);
    if (kanjiValue != null) {
      return hasHalf ? kanjiValue + 0.5 : kanjiValue;
    }

    return null;
  }

  /// Parses pure Kanji numbers including compound numbers.
  /// Supports: 一-九, 十, 十一-十九, 二十-九十, 二十一-九十九, 百, 千
  static double? _parseKanjiNumber(String input) {
    if (input.isEmpty) return null;

    const kanjiDigits = {
      '一': 1, '二': 2, '三': 3, '四': 4, '五': 5,
      '六': 6, '七': 7, '八': 8, '九': 9,
    };

    // Simple single digit kanji
    if (kanjiDigits.containsKey(input)) {
      return kanjiDigits[input]!.toDouble();
    }

    // Handle 十 (10)
    if (input == '十') return 10.0;

    // Handle 十一 through 十九 (11-19)
    if (input.startsWith('十') && input.length == 2) {
      final secondChar = input[1];
      if (kanjiDigits.containsKey(secondChar)) {
        return (10 + kanjiDigits[secondChar]!).toDouble();
      }
    }

    // Handle 二十, 三十, etc. (20, 30, ...)
    if (input.endsWith('十') && input.length == 2) {
      final firstChar = input[0];
      if (kanjiDigits.containsKey(firstChar)) {
        return (kanjiDigits[firstChar]! * 10).toDouble();
      }
    }

    // Handle 二十一, 三十五, etc. (21, 35, ...)
    if (input.length == 3 && input[1] == '十') {
      final firstChar = input[0];
      final thirdChar = input[2];
      if (kanjiDigits.containsKey(firstChar) && kanjiDigits.containsKey(thirdChar)) {
        return (kanjiDigits[firstChar]! * 10 + kanjiDigits[thirdChar]!).toDouble();
      }
    }

    // Handle 百 (100) and multiples
    if (input == '百') return 100.0;
    if (input.contains('百')) {
      // Simple cases: 二百 = 200, 五百 = 500
      if (input.length == 2 && input.endsWith('百')) {
        final firstChar = input[0];
        if (kanjiDigits.containsKey(firstChar)) {
          return (kanjiDigits[firstChar]! * 100).toDouble();
        }
      }
      // Handle 百五十 = 150, etc (百 + tens)
      if (input.startsWith('百') && input.length >= 2) {
        final remainder = input.substring(1);
        final remainderValue = _parseKanjiNumber(remainder);
        if (remainderValue != null) {
          return 100 + remainderValue;
        }
      }
      // Handle 二百五十 = 250, etc (hundreds + tens)
      if (input.length >= 3) {
        final hundredsIdx = input.indexOf('百');
        if (hundredsIdx > 0) {
          final hundredsChar = input.substring(0, hundredsIdx);
          if (kanjiDigits.containsKey(hundredsChar)) {
            final hundreds = kanjiDigits[hundredsChar]! * 100;
            final remainder = input.substring(hundredsIdx + 1);
            if (remainder.isEmpty) {
              return hundreds.toDouble();
            }
            final remainderValue = _parseKanjiNumber(remainder);
            if (remainderValue != null) {
              return hundreds + remainderValue;
            }
          }
        }
      }
    }

    // Handle 千 (1000) and multiples
    if (input == '千') return 1000.0;
    if (input.contains('千')) {
      // Simple cases: 二千 = 2000, 五千 = 5000
      if (input.length == 2 && input.endsWith('千')) {
        final firstChar = input[0];
        if (kanjiDigits.containsKey(firstChar)) {
          return (kanjiDigits[firstChar]! * 1000).toDouble();
        }
      }
    }

    return null;
  }
  
  List<_QuantityMatch> _findRanges(String input, RegexBuilder regexBuilder) {
    final matches = <_QuantityMatch>[];
    
    // Match patterns like "2-3 cups" or "1 to 2 tablespoons"
    final rangeMatches = regexBuilder.rangePattern.allMatches(input);
    for (final match in rangeMatches) {
      matches.add(_QuantityMatch(
        start: match.start,
        end: match.end,
        text: match.group(0)!,
      ));
    }
    
    return matches;
  }
  
  List<_QuantityMatch> _findSingleQuantities(String input, List<_QuantityMatch> existingMatches, RegexBuilder regexBuilder) {
    final matches = <_QuantityMatch>[];
    
    // Find all single quantity matches
    final quantityMatches = regexBuilder.quantityPattern.allMatches(input);
    
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
  
  List<_QuantityMatch> _findApproximateQuantities(String input, List<_QuantityMatch> existingMatches, RegexBuilder regexBuilder) {
    final matches = <_QuantityMatch>[];
    
    // Match approximate quantities
    final approxMatches = regexBuilder.approximatePattern.allMatches(input);
    
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
  
  List<_QuantityMatch> _findBareNumbers(String input, List<_QuantityMatch> existingMatches, Language language) {
    final matches = <_QuantityMatch>[];
    
    // Language-specific bare number patterns
    RegExp bareNumberPattern;
    
    switch (language) {
      case Language.english:
        // Match bare numbers at the start: "1 onion", "2 eggs", "1/2 avocado", "½ cup"
        const unicodeFractions = r'[½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]';
        bareNumberPattern = RegExp('^(?:(?:\\d+\\s+)?(?:\\d+/\\d+|\\d+)|(?:\\d+\\s*)?$unicodeFractions)(?=\\s+[a-zA-Z])');
        break;
      case Language.japanese:
        // Japanese bare numbers: "1個", "2本", "半分", kanji numbers
        // Exclude cases where the number is followed by a unit (カップ, 大さじ, etc.)
        const kanjiNumbers = r'[一二三四五六七八九十百千]+';
        const unicodeFractions = r'[½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]';
        // Negative lookahead to exclude known units
        const japaneseUnits = r'(?!カップ|大さじ|小さじ|ml|リットル|グラム|キログラム|個|本|枚|匹|丁|切れ|片|粒|玉|束|合|升|勺|人分|杯|袋|パック|つまみ)';
        bareNumberPattern = RegExp('(?:^|(?<=\\s))(?:(?:\\d+(?:\\.\\d+)?|$kanjiNumbers)(?:半)?|$unicodeFractions|半)(?=[\\u3040-\\u309F\\u30A0-\\u30FF\\u4E00-\\u9FAF])$japaneseUnits');
        break;
    }
    
    final allMatches = bareNumberPattern.allMatches(input);
    for (final match in allMatches) {
      // Check if this position is already covered by existing matches
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
          text: match.group(0)!.trim(),
        ));
      }
    }
    
    return matches;
  }

  /// Finds unit-before-number patterns common in Japanese (e.g., 大さじ3, 小さじ1/2)
  List<_QuantityMatch> _findUnitBeforeNumber(String input, RegexBuilder regexBuilder) {
    final matches = <_QuantityMatch>[];

    // Get Japanese units that commonly appear before numbers
    const unitBeforeNumberUnits = [
      '大さじ', '大匙', 'おおさじ',
      '小さじ', '小匙', 'こさじ',
      'カップ',
    ];

    // Build pattern: unit followed by number (with optional fractions, ranges)
    // Supports: 大さじ3, 大さじ1/2, 大さじ1.5, 大さじ1-2, 大さじ二, 大さじ1弱, 大さじ1強
    final unitsPattern = unitBeforeNumberUnits.map((u) => RegExp.escape(u)).join('|');
    const kanjiNumbers = '[一二三四五六七八九十百千]+';
    const unicodeFractions = '[½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]';

    // Pattern for ranges: 大さじ1-2, 大さじ1〜2 (already normalized to -)
    final rangePattern = RegExp(
      '($unitsPattern)'
      '(\\d+(?:\\.\\d+)?|$kanjiNumbers)'
      '\\s*(?:-|–|to)\\s*'
      '(\\d+(?:\\.\\d+)?|$kanjiNumbers)'
      '([弱強])?',
    );

    for (final match in rangePattern.allMatches(input)) {
      matches.add(_QuantityMatch(
        start: match.start,
        end: match.end,
        text: match.group(0)!,
      ));
    }

    // Pattern for fractions: 大さじ1/2, 大さじ1 1/2, 大さじ½
    final fractionPattern = RegExp(
      '($unitsPattern)'
      '(?:(\\d+)\\s+)?(\\d+)/(\\d+)'
      '([弱強])?',
    );

    for (final match in fractionPattern.allMatches(input)) {
      // Skip if overlaps with existing range match
      bool overlaps = matches.any((m) =>
        match.start >= m.start && match.start < m.end);
      if (!overlaps) {
        matches.add(_QuantityMatch(
          start: match.start,
          end: match.end,
          text: match.group(0)!,
        ));
      }
    }

    // Pattern for unicode fractions: 大さじ½, 大さじ1½
    final unicodeFractionPattern = RegExp(
      '($unitsPattern)'
      '(?:(\\d+)\\s*)?($unicodeFractions)'
      '([弱強])?',
    );

    for (final match in unicodeFractionPattern.allMatches(input)) {
      bool overlaps = matches.any((m) =>
        match.start >= m.start && match.start < m.end);
      if (!overlaps) {
        matches.add(_QuantityMatch(
          start: match.start,
          end: match.end,
          text: match.group(0)!,
        ));
      }
    }

    // Pattern for single numbers: 大さじ3, 大さじ二, 大さじ1.5, 大さじ1弱
    final singlePattern = RegExp(
      '($unitsPattern)'
      '(\\d+(?:\\.\\d+)?|$kanjiNumbers(?:半)?|半)'
      '([弱強])?',
    );

    for (final match in singlePattern.allMatches(input)) {
      // Skip if overlaps with existing matches
      bool overlaps = matches.any((m) =>
        match.start >= m.start && match.start < m.end);
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

/// Helper class for parsed quantity data (internal use)
class _ParsedQuantityData {
  final double value;
  final double? rangeMax;
  final String unit;
  final String canonicalUnit;
  final UnitType unitType;

  _ParsedQuantityData({
    required this.value,
    this.rangeMax,
    required this.unit,
    required this.canonicalUnit,
    required this.unitType,
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
  /// Returns unit definitions for the specified language
  static List<UnitDefinition> getUnitsForLanguage(Language language) {
    switch (language) {
      case Language.english:
        return englishUnits;
      case Language.japanese:
        return japaneseUnits;
    }
  }
  
  /// Returns approximate terms for the specified language
  static List<String> getApproximateTermsForLanguage(Language language) {
    switch (language) {
      case Language.english:
        return englishApproximateTerms;
      case Language.japanese:
        return japaneseApproximateTerms;
    }
  }
  
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
  
  static const List<String> englishApproximateTerms = [
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
  
  static const List<UnitDefinition> japaneseUnits = [
    // Volume
    UnitDefinition(
      canonical: 'カップ',
      variations: ['カップ', 'cup', 'C'],
    ),
    UnitDefinition(
      canonical: '大さじ',
      variations: ['大さじ', '大匙', 'おおさじ', 'tbsp', 'Tbsp'],
    ),
    UnitDefinition(
      canonical: '小さじ',
      variations: ['小さじ', '小匙', 'こさじ', 'tsp', 'Tsp'],
    ),
    UnitDefinition(
      canonical: 'ml',
      variations: ['ml', 'mL', 'ML', 'ミリリットル', 'cc'],
    ),
    UnitDefinition(
      canonical: 'リットル',
      variations: ['リットル', 'リッター', 'l', 'L'],
    ),
    
    // Weight
    UnitDefinition(
      canonical: 'グラム',
      variations: ['グラム', 'g', 'G'],
    ),
    UnitDefinition(
      canonical: 'キログラム',
      variations: ['キログラム', 'キロ', 'kg', 'Kg'],
    ),
    
    // Count/Pieces  
    UnitDefinition(
      canonical: '個',
      variations: ['個', 'こ'],
    ),
    UnitDefinition(
      canonical: '本',
      variations: ['本', 'ほん'],
    ),
    UnitDefinition(
      canonical: '枚',
      variations: ['枚', 'まい'],
    ),
    UnitDefinition(
      canonical: '匹',
      variations: ['匹', 'ひき'],
    ),
    UnitDefinition(
      canonical: '丁',
      variations: ['丁', 'ちょう'],
    ),
    UnitDefinition(
      canonical: '切れ',
      variations: ['切れ', 'きれ'],
    ),
    UnitDefinition(
      canonical: '片',
      variations: ['片', 'かけ', 'へん'],  // Slice/piece for garlic, ginger
    ),
    UnitDefinition(
      canonical: '粒',
      variations: ['粒', 'つぶ'],
    ),
    UnitDefinition(
      canonical: '玉',
      variations: ['玉', 'たま'],
    ),
    UnitDefinition(
      canonical: '束',
      variations: ['束', 'たば'],
    ),
    
    // Traditional measures
    UnitDefinition(
      canonical: '合',
      variations: ['合', 'ごう'],
    ),
    UnitDefinition(
      canonical: '升',
      variations: ['升', 'しょう'],
    ),
    UnitDefinition(
      canonical: '勺',
      variations: ['勺', 'しゃく'],
    ),
    
    // Portions
    UnitDefinition(
      canonical: '人分',
      variations: ['人分', 'にんぶん'],
    ),
    UnitDefinition(
      canonical: '杯',
      variations: ['杯', 'はい', 'ぱい'],
    ),
    UnitDefinition(
      canonical: '袋',
      variations: ['袋', 'ふくろ'],
    ),
    UnitDefinition(
      canonical: 'パック',
      variations: ['パック', 'pack'],
    ),
    
    // Approximate
    UnitDefinition(
      canonical: 'つまみ',
      variations: ['つまみ', 'ひとつまみ'],
    ),
  ];
  
  static const List<String> japaneseApproximateTerms = [
    '適量',
    '少々',
    'ひとつまみ',
    'ふたつまみ',
    'お好みで',
    'お好み',
    '好みで',
    '味を見て',
    '様子を見て',
    '少量',
    '適宜',
    'ほんの少し',
    '大体',
    '約',
    'くらい',
    'ぐらい',
    '程度',
    '多め',
    '少なめ',
    '弱',   // Scant (e.g., 大さじ1弱 - scant tablespoon)
    '強',   // Heaping (e.g., 大さじ1強 - heaping tablespoon)
  ];
}

/// Builds regex patterns from unit definitions
class RegexBuilder {
  late final RegExp quantityPattern;
  late final RegExp rangePattern;
  late final RegExp approximatePattern;
  
  RegexBuilder(Language language, List<UnitDefinition> units) {
    // Build unit variations pattern - sort by length (longest first)
    final allVariations = units
        .expand((u) => u.variations)
        .map((v) => RegExp.escape(v))
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    
    final unitsPattern = '(${allVariations.join('|')})';
    
    // Number pattern: handles fractions, decimals, and language-specific numbers
    const regularFractionPart = r'(?:\d+\s+)?(?:\d+/\d+)';
    const unicodeFractionPart = '(?:\\d+\\s*)?[½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]';
    const decimalPart = r'\d+(?:\.\d+)?';
    
    // Add language-specific number patterns
    String numberPattern;
    if (language == Language.japanese) {
      // Include Kanji numbers and standalone/combined "半" for Japanese
      const kanjiNumbers = r'[一二三四五六七八九十百千]+';
      const japaneseNumberPart = '(?:(?:$kanjiNumbers|\\d+)(?:半)?|半)';
      numberPattern = '(?:$regularFractionPart|$unicodeFractionPart|$decimalPart|$japaneseNumberPart)';
    } else {
      numberPattern = '(?:$regularFractionPart|$unicodeFractionPart|$decimalPart)';
    }
    
    // Single quantity pattern - with optional space between number and unit
    // Updated to better handle word boundaries and spaces
    // For Japanese, allow Japanese characters after units as well
    // Include both opening and closing parentheses/brackets (quantity may be followed by notes in parens)
    final lookahead = language == Language.japanese
        ? r'(?=\s|,|$|[()（）\[\]【】「」『』〈〉《》]|[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF])'
        : r'(?=\s|,|$|[()\[\]])';
    quantityPattern = RegExp(
      numberPattern + r'\s*' + unitsPattern + lookahead,
      caseSensitive: false,
    );
    
    // Range pattern - "2-3 cups" or "1 to 2 tablespoons"
    rangePattern = RegExp(
      numberPattern + r'\s*(?:-|–|to)\s*' + numberPattern + r'\s*' + unitsPattern + lookahead,
      caseSensitive: false,
    );
    
    // Approximate terms pattern - language-specific boundaries
    final approxTerms = IngredientParserConfig.getApproximateTermsForLanguage(language)
        .map((t) => RegExp.escape(t))
        .join('|');
    
    if (language == Language.japanese) {
      // For Japanese, allow approximate terms after Japanese characters (no space needed)
      // Use positive lookbehind to not include the Japanese character in the match
      approximatePattern = RegExp(
        r'(?<=^|[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF])(' + approxTerms + r')(?:\s|,|$)',
        caseSensitive: false,
      );
    } else {
      // For English, require whitespace or start of string
      approximatePattern = RegExp(
        r'(?:^|\s)(' + approxTerms + r')(?:\s|,|$)',
        caseSensitive: false,
      );
    }
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
  
  static double _unicodeFractionToDecimal(String unicodeFraction) {
    const fractionMap = {
      '½': 0.5,
      '⅓': 1/3,
      '⅔': 2/3,
      '¼': 0.25,
      '¾': 0.75,
      '⅕': 0.2,
      '⅖': 0.4,
      '⅗': 0.6,
      '⅘': 0.8,
      '⅙': 1/6,
      '⅚': 5/6,
      '⅛': 0.125,
      '⅜': 0.375,
      '⅝': 0.625,
      '⅞': 0.875,
      '半': 0.5, // Japanese half
    };
    return fractionMap[unicodeFraction] ?? 0.0;
  }
  
  /// Parses Japanese numbers (Kanji and Arabic) with half support.
  /// Delegates to IngredientParserService._parseJapaneseNumber for consistency.
  static double? _parseJapaneseNumber(String input) {
    return IngredientParserService._parseJapaneseNumber(input);
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
    
    // Handle Unicode fractions like "½ cup" or "1½ cups" or Japanese "半"
    final unicodeFractionMatch = RegExp(r'(\d+\s*)?([½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞半])(\s*.*)').firstMatch(quantityText);
    if (unicodeFractionMatch != null) {
      final wholeStr = unicodeFractionMatch.group(1)?.trim();
      final fractionChar = unicodeFractionMatch.group(2)!;
      final remainder = unicodeFractionMatch.group(3)!;
      
      final whole = wholeStr != null && wholeStr.isNotEmpty ? double.parse(wholeStr) : 0.0;
      final fractionValue = _unicodeFractionToDecimal(fractionChar);
      final totalValue = whole + fractionValue;
      final scaledValue = totalValue * scale;
      
      return _formatNumber(scaledValue) + remainder;
    }
    
    // Handle Japanese numbers with half: "2半個", "三半カップ", or pure "半"
    // Only match if there are Japanese characters or explicit half marker
    final japaneseNumberMatch = RegExp(r'((?:[一二三四五六七八九十]+(?:半)?|\d+半|半))(.*)').firstMatch(quantityText);
    if (japaneseNumberMatch != null) {
      final numberPart = japaneseNumberMatch.group(1)!;
      final remainder = japaneseNumberMatch.group(2)!;
      
      final value = _parseJapaneseNumber(numberPart);
      if (value != null) {
        final scaledValue = value * scale;
        return _formatNumber(scaledValue) + remainder;
      }
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