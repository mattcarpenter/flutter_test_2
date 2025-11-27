import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'app_logger.dart';

/// Service for exporting and managing log files.
class LogExportService {
  LogExportService._();

  /// Get the log file. Returns null if logging not initialized or file doesn't exist.
  static Future<File?> getLogFile() async {
    // Use the file from AppLogger if available
    if (AppLogger.logFile != null && await AppLogger.logFile!.exists()) {
      return AppLogger.logFile;
    }

    // Fallback: try to find it manually
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_logs.txt');
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      AppLogger.error('Failed to get log file', e);
    }

    return null;
  }

  /// Get the size of the log file in bytes.
  static Future<int> getLogFileSize() async {
    final file = await getLogFile();
    if (file == null) return 0;

    try {
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  /// Get a human-readable file size string.
  static Future<String> getLogFileSizeFormatted() async {
    final bytes = await getLogFileSize();
    if (bytes == 0) return 'No logs';

    const kb = 1024;
    const mb = kb * 1024;

    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(1)} MB';
    } else if (bytes >= kb) {
      return '${(bytes / kb).toStringAsFixed(1)} KB';
    } else {
      return '$bytes bytes';
    }
  }

  /// Share the log file via the system share sheet.
  ///
  /// [sharePositionOrigin] is required on iPad/macOS for the share popover anchor.
  /// Returns null if no logs exist, true if shared successfully, false if dismissed/cancelled.
  static Future<bool?> shareLogs({Rect? sharePositionOrigin}) async {
    final file = await getLogFile();
    if (file == null) {
      AppLogger.warning('No log file to share');
      return null; // No logs exist
    }

    try {
      AppLogger.info('Sharing log file');

      final result = await Share.shareXFiles(
        [XFile(file.path)],
        sharePositionOrigin: sharePositionOrigin,
      );

      return result.status == ShareResultStatus.success;
    } catch (e, stack) {
      AppLogger.error('Failed to share logs', e, stack);
      return null;
    }
  }

  /// Read the log file contents as a string.
  static Future<String?> readLogs() async {
    final file = await getLogFile();
    if (file == null) return null;

    try {
      return await file.readAsString();
    } catch (e) {
      AppLogger.error('Failed to read log file', e);
      return null;
    }
  }

  /// Clear all logs.
  static Future<bool> clearLogs() async {
    final file = await getLogFile();
    if (file == null) return false;

    try {
      AppLogger.info('Clearing log file');
      await file.writeAsString('');
      AppLogger.info('Log file cleared');
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to clear logs', e, stack);
      return false;
    }
  }
}
