/// Utility for formatting duration values consistently across the app
class DurationFormatter {
  /// Formats a duration in minutes into a human-readable string
  /// 
  /// Examples:
  /// - 30 minutes -> "30 min"
  /// - 60 minutes -> "1 hr"
  /// - 90 minutes -> "1h 30m"
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

  /// Formats a Duration object into a human-readable string
  static String formatDuration(Duration duration) {
    if (duration == Duration.zero) return '';
    return formatMinutes(duration.inMinutes);
  }
}