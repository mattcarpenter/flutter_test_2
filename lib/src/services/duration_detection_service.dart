import '../services/logging/app_logger.dart';

/// Represents a detected duration in text with its position and value
class DetectedDuration {
  /// Position where the duration starts in the original string
  final int startIndex;

  /// Position where the duration ends in the original string
  final int endIndex;

  /// The original matched text (e.g., "25 minutes", "1時間30分")
  final String matchedText;

  /// The parsed duration value (lower bound for ranges)
  final Duration duration;

  /// For range durations like "10-15 minutes", stores the upper bound
  final Duration? rangeMax;

  const DetectedDuration({
    required this.startIndex,
    required this.endIndex,
    required this.matchedText,
    required this.duration,
    this.rangeMax,
  });

  bool get isRange => rangeMax != null;

  @override
  String toString() {
    if (isRange) {
      return 'DetectedDuration(startIndex: $startIndex, endIndex: $endIndex, '
          'matchedText: "$matchedText", duration: $duration, rangeMax: $rangeMax)';
    }
    return 'DetectedDuration(startIndex: $startIndex, endIndex: $endIndex, '
        'matchedText: "$matchedText", duration: $duration)';
  }
}

/// Service for detecting and parsing duration expressions in text.
/// Supports both English and Japanese time expressions.
class DurationDetectionService {
  /// Detects all duration expressions in the given text.
  /// Returns a list of [DetectedDuration] objects sorted by startIndex.
  ///
  /// Supported English patterns:
  /// - Combined: "1 hour 30 minutes", "1 hour and 30 minutes", "2 hrs 15 mins"
  /// - Hours: "2 hours", "1 hour", "3 hrs", "1 hr"
  /// - Minutes with range: "10-15 minutes", "10 to 15 minutes"
  /// - Minutes: "25 minutes", "5 min", "30 mins"
  /// - Hyphenated adjective: "25-minute", "10-min"
  /// - Seconds: "30 seconds", "45 sec"
  ///
  /// Supported Japanese patterns:
  /// - Combined: "1時間30分"
  /// - Hours: "2時間"
  /// - Minutes: "30分", "5分間"
  /// - Seconds: "30秒"
  /// - Kanji numbers: 一=1, 二=2, 三=3, etc.
  List<DetectedDuration> detectDurations(String text) {
    if (text.trim().isEmpty) {
      return [];
    }

    final matches = <_DurationMatch>[];

    // Process patterns in priority order (combined before single units)
    // to ensure longer, more specific patterns are matched first

    // 1. English combined patterns (e.g., "1 hour 30 minutes")
    matches.addAll(_findEnglishCombinedDurations(text));

    // 2. Japanese combined patterns (e.g., "1時間30分")
    matches.addAll(_findJapaneseCombinedDurations(text));

    // 3. English range patterns (e.g., "10-15 minutes")
    matches.addAll(_findEnglishRangeDurations(text));

    // 4. English single unit patterns (hours, minutes, seconds)
    matches.addAll(_findEnglishSingleUnitDurations(text));

    // 5. English hyphenated adjective patterns (e.g., "25-minute")
    matches.addAll(_findEnglishHyphenatedDurations(text));

    // 6. Japanese single unit patterns (時間, 分, 秒)
    matches.addAll(_findJapaneseSingleUnitDurations(text));

    // Remove overlapping matches (keep first occurrence)
    final nonOverlapping = _removeOverlaps(matches);

    // Sort by start index
    nonOverlapping.sort((a, b) => a.startIndex.compareTo(b.startIndex));

    // Convert to DetectedDuration objects
    return nonOverlapping.map((match) => DetectedDuration(
      startIndex: match.startIndex,
      endIndex: match.endIndex,
      matchedText: match.matchedText,
      duration: match.duration,
      rangeMax: match.rangeMax,
    )).toList();
  }

  /// Quick check if text contains any duration expressions
  bool hasDurations(String text) {
    return detectDurations(text).isNotEmpty;
  }

  // ============================================================
  // ENGLISH PATTERN DETECTION
  // ============================================================

  List<_DurationMatch> _findEnglishCombinedDurations(String text) {
    final matches = <_DurationMatch>[];

    // Pattern: "1 hour 30 minutes", "1 hour and 30 minutes", "2 hrs 15 mins"
    final pattern = RegExp(
      r'(\d+)\s*(hours?|hrs?|h)\s*(?:and\s+)?(\d+)\s*(minutes?|mins?|m)\b',
      caseSensitive: false,
    );

    for (final match in pattern.allMatches(text)) {
      final hours = int.tryParse(match.group(1)!);
      final minutes = int.tryParse(match.group(3)!);

      if (hours != null && minutes != null) {
        matches.add(_DurationMatch(
          startIndex: match.start,
          endIndex: match.end,
          matchedText: match.group(0)!,
          duration: Duration(hours: hours, minutes: minutes),
        ));
      }
    }

    return matches;
  }

  List<_DurationMatch> _findEnglishRangeDurations(String text) {
    final matches = <_DurationMatch>[];

    // Pattern: "10-15 minutes", "10 to 15 minutes", "2-3 hours"
    final pattern = RegExp(
      r'(\d+)\s*(?:-|–|to)\s*(\d+)\s*(hours?|hrs?|h|minutes?|mins?|m|seconds?|secs?|s)\b',
      caseSensitive: false,
    );

    for (final match in pattern.allMatches(text)) {
      final min = int.tryParse(match.group(1)!);
      final max = int.tryParse(match.group(2)!);
      final unit = match.group(3)!.toLowerCase();

      if (min != null && max != null) {
        final Duration minDuration;
        final Duration maxDuration;

        if (unit.startsWith('h')) {
          minDuration = Duration(hours: min);
          maxDuration = Duration(hours: max);
        } else if (unit.startsWith('s')) {
          minDuration = Duration(seconds: min);
          maxDuration = Duration(seconds: max);
        } else {
          minDuration = Duration(minutes: min);
          maxDuration = Duration(minutes: max);
        }

        matches.add(_DurationMatch(
          startIndex: match.start,
          endIndex: match.end,
          matchedText: match.group(0)!,
          duration: minDuration,
          rangeMax: maxDuration,
        ));
      }
    }

    return matches;
  }

  List<_DurationMatch> _findEnglishSingleUnitDurations(String text) {
    final matches = <_DurationMatch>[];

    // Pattern: "2 hours", "25 minutes", "30 seconds"
    final pattern = RegExp(
      r'(\d+)\s*(hours?|hrs?|h|minutes?|mins?|m|seconds?|secs?|s)\b',
      caseSensitive: false,
    );

    for (final match in pattern.allMatches(text)) {
      final value = int.tryParse(match.group(1)!);
      final unit = match.group(2)!.toLowerCase();

      if (value != null) {
        final Duration duration;

        if (unit.startsWith('h')) {
          duration = Duration(hours: value);
        } else if (unit.startsWith('s')) {
          duration = Duration(seconds: value);
        } else {
          duration = Duration(minutes: value);
        }

        matches.add(_DurationMatch(
          startIndex: match.start,
          endIndex: match.end,
          matchedText: match.group(0)!,
          duration: duration,
        ));
      }
    }

    return matches;
  }

  List<_DurationMatch> _findEnglishHyphenatedDurations(String text) {
    final matches = <_DurationMatch>[];

    // Pattern: "25-minute", "10-min", "2-hour"
    final pattern = RegExp(
      r'(\d+)-(hours?|hrs?|h|minutes?|mins?|m|seconds?|secs?|s)\b',
      caseSensitive: false,
    );

    for (final match in pattern.allMatches(text)) {
      final value = int.tryParse(match.group(1)!);
      final unit = match.group(2)!.toLowerCase();

      if (value != null) {
        final Duration duration;

        if (unit.startsWith('h')) {
          duration = Duration(hours: value);
        } else if (unit.startsWith('s')) {
          duration = Duration(seconds: value);
        } else {
          duration = Duration(minutes: value);
        }

        matches.add(_DurationMatch(
          startIndex: match.start,
          endIndex: match.end,
          matchedText: match.group(0)!,
          duration: duration,
        ));
      }
    }

    return matches;
  }

  // ============================================================
  // JAPANESE PATTERN DETECTION
  // ============================================================

  List<_DurationMatch> _findJapaneseCombinedDurations(String text) {
    final matches = <_DurationMatch>[];

    // Pattern: "1時間30分", "2時間15分"
    final pattern = RegExp(
      r'([一二三四五六七八九十百千\d]+)時間([一二三四五六七八九十百千\d]+)分',
    );

    for (final match in pattern.allMatches(text)) {
      final hours = _parseJapaneseNumber(match.group(1)!);
      final minutes = _parseJapaneseNumber(match.group(2)!);

      if (hours != null && minutes != null) {
        matches.add(_DurationMatch(
          startIndex: match.start,
          endIndex: match.end,
          matchedText: match.group(0)!,
          duration: Duration(hours: hours, minutes: minutes),
        ));
      }
    }

    return matches;
  }

  List<_DurationMatch> _findJapaneseSingleUnitDurations(String text) {
    final matches = <_DurationMatch>[];

    // Pattern: "2時間", "30分", "5分間", "30秒"
    final patterns = [
      RegExp(r'([一二三四五六七八九十百千\d]+)時間'),  // Hours
      RegExp(r'([一二三四五六七八九十百千\d]+)分間?'), // Minutes (with optional 間)
      RegExp(r'([一二三四五六七八九十百千\d]+)秒'),   // Seconds
    ];

    for (var i = 0; i < patterns.length; i++) {
      final pattern = patterns[i];

      for (final match in pattern.allMatches(text)) {
        final value = _parseJapaneseNumber(match.group(1)!);

        if (value != null) {
          final Duration duration;

          if (i == 0) {
            duration = Duration(hours: value);
          } else if (i == 1) {
            duration = Duration(minutes: value);
          } else {
            duration = Duration(seconds: value);
          }

          matches.add(_DurationMatch(
            startIndex: match.start,
            endIndex: match.end,
            matchedText: match.group(0)!,
            duration: duration,
          ));
        }
      }
    }

    return matches;
  }

  // ============================================================
  // JAPANESE NUMBER PARSING
  // ============================================================

  /// Parses Japanese numbers (both Kanji and Arabic numerals)
  /// Supports: 一=1, 二=2, 三=3, 四=4, 五=5, 六=6, 七=7, 八=8, 九=9, 十=10
  /// Also handles: 十一=11, 十二=12, ... 二十=20, 三十=30, etc.
  int? _parseJapaneseNumber(String input) {
    if (input.trim().isEmpty) return null;

    // Handle Arabic numerals
    final arabicNumber = int.tryParse(input);
    if (arabicNumber != null) return arabicNumber;

    // Handle Kanji numbers
    const kanjiDigits = {
      '一': 1, '二': 2, '三': 3, '四': 4, '五': 5,
      '六': 6, '七': 7, '八': 8, '九': 9,
    };

    // Simple single digit kanji
    if (kanjiDigits.containsKey(input)) {
      return kanjiDigits[input];
    }

    // Handle 十 (10)
    if (input == '十') return 10;

    // Handle 十一 through 十九 (11-19)
    if (input.startsWith('十') && input.length == 2) {
      final secondChar = input[1];
      if (kanjiDigits.containsKey(secondChar)) {
        return 10 + kanjiDigits[secondChar]!;
      }
    }

    // Handle 二十, 三十, etc. (20, 30, ...)
    if (input.endsWith('十') && input.length == 2) {
      final firstChar = input[0];
      if (kanjiDigits.containsKey(firstChar)) {
        return kanjiDigits[firstChar]! * 10;
      }
    }

    // Handle 二十一, 三十五, etc. (21, 35, ...)
    if (input.length == 3 && input[1] == '十') {
      final firstChar = input[0];
      final thirdChar = input[2];
      if (kanjiDigits.containsKey(firstChar) && kanjiDigits.containsKey(thirdChar)) {
        return kanjiDigits[firstChar]! * 10 + kanjiDigits[thirdChar]!;
      }
    }

    // Handle 百 (100) and multiples
    if (input == '百') return 100;
    if (input.contains('百')) {
      // Simple cases: 二百 = 200, 五百 = 500
      if (input.length == 2 && input.endsWith('百')) {
        final firstChar = input[0];
        if (kanjiDigits.containsKey(firstChar)) {
          return kanjiDigits[firstChar]! * 100;
        }
      }
    }

    // Handle 千 (1000) and multiples
    if (input == '千') return 1000;
    if (input.contains('千')) {
      // Simple cases: 二千 = 2000, 五千 = 5000
      if (input.length == 2 && input.endsWith('千')) {
        final firstChar = input[0];
        if (kanjiDigits.containsKey(firstChar)) {
          return kanjiDigits[firstChar]! * 1000;
        }
      }
    }

    AppLogger.debug('Unable to parse Japanese number: $input');
    return null;
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Removes overlapping matches, keeping the first occurrence
  List<_DurationMatch> _removeOverlaps(List<_DurationMatch> matches) {
    if (matches.isEmpty) return matches;

    // Sort by start index first
    final sorted = List<_DurationMatch>.from(matches)
      ..sort((a, b) => a.startIndex.compareTo(b.startIndex));

    final nonOverlapping = <_DurationMatch>[];

    for (final match in sorted) {
      bool overlaps = false;

      for (final existing in nonOverlapping) {
        // Check if ranges overlap
        if (match.startIndex < existing.endIndex &&
            match.endIndex > existing.startIndex) {
          overlaps = true;
          break;
        }
      }

      if (!overlaps) {
        nonOverlapping.add(match);
      }
    }

    return nonOverlapping;
  }
}

/// Internal class for tracking duration matches during detection
class _DurationMatch {
  final int startIndex;
  final int endIndex;
  final String matchedText;
  final Duration duration;
  final Duration? rangeMax;

  const _DurationMatch({
    required this.startIndex,
    required this.endIndex,
    required this.matchedText,
    required this.duration,
    this.rangeMax,
  });
}
