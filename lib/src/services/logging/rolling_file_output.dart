import 'dart:io';
import 'package:logger/logger.dart';
import 'log_sanitizer.dart';

/// A [LogOutput] that writes to a rolling file with size cap.
/// When the file exceeds [maxFileSize], the oldest 25% is truncated.
class RollingFileOutput extends LogOutput {
  final File file;
  final int maxFileSize;
  final Level minLevel;

  /// Track if we're currently truncating to avoid re-entry.
  bool _isTruncating = false;

  RollingFileOutput({
    required this.file,
    this.maxFileSize = 2 * 1024 * 1024, // 2MB default
    this.minLevel = Level.debug,
  });

  @override
  void output(OutputEvent event) {
    // Filter by minimum level
    if (event.level.index < minLevel.index) {
      return;
    }

    final buffer = StringBuffer();
    final timestamp = DateTime.now().toIso8601String();
    final levelName = _levelName(event.level);

    for (final line in event.lines) {
      // Sanitize each line before writing
      final sanitizedLine = LogSanitizer.sanitize(line);
      buffer.writeln('$timestamp [$levelName] $sanitizedLine');
    }

    _appendToFile(buffer.toString());
  }

  void _appendToFile(String content) {
    try {
      // Ensure parent directory exists
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }

      // Append to file
      file.writeAsStringSync(content, mode: FileMode.append, flush: true);

      // Check if truncation needed
      _truncateIfNeeded();
    } catch (e) {
      // Silently fail - we don't want logging to crash the app
    }
  }

  void _truncateIfNeeded() {
    if (_isTruncating) return;

    try {
      if (!file.existsSync()) return;

      final fileSize = file.lengthSync();
      if (fileSize <= maxFileSize) return;

      _isTruncating = true;

      // Read content and keep last 75%
      final content = file.readAsStringSync();
      final truncateAt = (content.length * 0.25).toInt();

      // Find the next newline after truncate point to avoid cutting mid-line
      var cutPoint = content.indexOf('\n', truncateAt);
      if (cutPoint == -1) cutPoint = truncateAt;

      final newContent = content.substring(cutPoint + 1);

      // Add marker indicating truncation occurred
      final truncationMarker =
          '--- Log truncated at ${DateTime.now().toIso8601String()} ---\n';

      file.writeAsStringSync(truncationMarker + newContent, flush: true);
    } catch (e) {
      // Silently fail
    } finally {
      _isTruncating = false;
    }
  }

  String _levelName(Level level) {
    return switch (level) {
      Level.trace => 'TRACE',
      Level.debug => 'DEBUG',
      Level.info => 'INFO',
      Level.warning => 'WARN',
      Level.error => 'ERROR',
      Level.fatal => 'FATAL',
      _ => 'LOG',
    };
  }

  @override
  Future<void> destroy() async {
    // Nothing to clean up
  }
}
