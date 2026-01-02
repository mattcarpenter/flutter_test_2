import 'package:flutter/widgets.dart';
import '../localization/l10n_extension.dart';

/// Utility for formatting duration values consistently across the app
class DurationFormatter {
  /// Formats a duration in minutes into a human-readable string (non-localized)
  ///
  /// Examples:
  /// - 30 minutes -> "30 min"
  /// - 60 minutes -> "1 hr"
  /// - 90 minutes -> "1h 30m"
  ///
  /// For UI display, prefer [formatMinutesLocalized] which uses proper translations.
  static String formatMinutes(int totalMinutes) {
    if (totalMinutes <= 0) return '';

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) {
      return '$totalMinutes min';
    } else if (minutes == 0) {
      return '$hours hr';
    } else {
      return '${hours}h ${minutes}m';
    }
  }

  /// Formats a duration in minutes into a localized human-readable string
  ///
  /// Examples (English):
  /// - 30 minutes -> "30 min"
  /// - 60 minutes -> "1 hr"
  /// - 90 minutes -> "1h 30m"
  ///
  /// Examples (Japanese):
  /// - 30 minutes -> "30分"
  /// - 60 minutes -> "1時間"
  /// - 90 minutes -> "1時間30分"
  static String formatMinutesLocalized(int totalMinutes, BuildContext context) {
    if (totalMinutes <= 0) return '';

    final l10n = context.l10n;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) {
      return l10n.durationMinutesShort(totalMinutes);
    } else if (minutes == 0) {
      return l10n.durationHoursShort(hours);
    } else {
      return l10n.durationHoursMinutesShort(hours, minutes);
    }
  }

  /// Formats a Duration object into a human-readable string
  static String formatDuration(Duration duration) {
    if (duration == Duration.zero) return '';
    return formatMinutes(duration.inMinutes);
  }

  /// Formats a Duration object into a localized human-readable string
  static String formatDurationLocalized(Duration duration, BuildContext context) {
    if (duration == Duration.zero) return '';
    return formatMinutesLocalized(duration.inMinutes, context);
  }
}