import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:logging/logging.dart' as logging;
import 'package:path_provider/path_provider.dart';

import 'rolling_file_output.dart';
import 'log_sanitizer.dart';

/// Application-wide logger service.
///
/// Initialize once at app startup:
/// ```dart
/// await AppLogger.init();
/// ```
///
/// Then use throughout the app:
/// ```dart
/// AppLogger.d('Debug message');
/// AppLogger.i('Info message');
/// AppLogger.e('Error occurred', error, stackTrace);
/// ```
class AppLogger {
  AppLogger._();

  static Logger? _logger;
  static RollingFileOutput? _fileOutput;
  static File? _logFile;
  static StreamSubscription<logging.LogRecord>? _loggingSubscription;

  /// Whether the logger has been initialized.
  static bool get isInitialized => _logger != null;

  /// The log file path (available after initialization).
  static File? get logFile => _logFile;

  /// Initialize the logger. Call once at app startup.
  ///
  /// [fileLevel] - Minimum level to write to file (default: debug)
  /// [maxFileSizeBytes] - Max log file size before truncation (default: 2MB)
  static Future<void> init({
    Level fileLevel = Level.debug,
    int maxFileSizeBytes = 2 * 1024 * 1024,
  }) async {
    if (_logger != null) {
      warning('AppLogger.init() called multiple times');
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      _logFile = File('${dir.path}/app_logs.txt');

      _fileOutput = RollingFileOutput(
        file: _logFile!,
        maxFileSize: maxFileSizeBytes,
        minLevel: fileLevel,
      );

      // Build list of outputs
      final outputs = <LogOutput>[];

      // Console output only in debug mode
      if (kDebugMode) {
        outputs.add(ConsoleOutput());
      }

      // Always add file output
      outputs.add(_fileOutput!);

      _logger = Logger(
        filter: ProductionFilter(), // Logs all levels
        printer: _AppLogPrinter(),
        output: MultiOutput(outputs),
        level: kDebugMode ? Level.trace : Level.debug,
      );

      _setupErrorHandlers();
      _bridgeDartLogging();

      info('Logger initialized');
    } catch (e, stack) {
      // Fallback to basic console logging if file setup fails
      debugPrint('Failed to initialize AppLogger: $e\n$stack');

      _logger = Logger(
        filter: DevelopmentFilter(),
        printer: PrettyPrinter(),
        output: ConsoleOutput(),
      );
    }
  }

  /// Set up global error handlers to capture uncaught errors.
  static void _setupErrorHandlers() {
    // Flutter framework errors (widget build errors, etc.)
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      error(
        'Flutter error: ${details.exceptionAsString()}',
        details.exception,
        details.stack,
      );
      // Call original handler (shows red error screen in debug)
      originalOnError?.call(details);
    };

    // Platform/async errors not caught by Flutter framework
    final originalPlatformError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (err, stack) {
      error('Uncaught platform error', err, stack);
      // Return true to prevent app crash in release mode
      // But also call original handler if it exists
      originalPlatformError?.call(err, stack);
      return true;
    };
  }

  /// Bridge Dart's `package:logging` to AppLogger.
  /// This captures logs from packages like Supabase, PowerSync, GoRouter.
  static void _bridgeDartLogging() {
    // Enable all log levels from the logging package
    logging.hierarchicalLoggingEnabled = true;
    logging.Logger.root.level = logging.Level.ALL;

    // Cancel any existing subscription
    _loggingSubscription?.cancel();

    // Verbose loggers that should only go to console (trace level), not file.
    // These produce noisy output that's not useful in log files.
    const verboseLoggers = {
      'GoRouter',
    };

    // Listen to all log records and forward to our logger
    _loggingSubscription = logging.Logger.root.onRecord.listen((record) {
      final message = '[${record.loggerName}] ${record.message}';

      // Downgrade verbose loggers to trace (console only, not written to file)
      if (verboseLoggers.contains(record.loggerName)) {
        trace(message);
        return;
      }

      // Map logging levels to our logger levels
      if (record.level >= logging.Level.SEVERE) {
        error(message, record.error, record.stackTrace);
      } else if (record.level >= logging.Level.WARNING) {
        warning(message, record.error, record.stackTrace);
      } else if (record.level >= logging.Level.INFO) {
        info(message);
      } else if (record.level >= logging.Level.CONFIG) {
        debug(message);
      } else {
        trace(message);
      }
    });
  }

  // ============ Logging Methods ============

  /// Log a trace message (most verbose).
  static void trace(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.trace, message, error, stackTrace);
  }

  /// Log a debug message.
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.debug, message, error, stackTrace);
  }

  /// Debounce tracking for repeated logs
  static final Map<String, DateTime> _debounceTimestamps = {};

  /// Log a debug message, but skip if same key was logged recently.
  /// Use [key] to group related messages (e.g., recipe ID).
  /// Default debounce is 2 seconds.
  static void debugDebounced(
    String message, {
    String? key,
    Duration debounce = const Duration(seconds: 2),
  }) {
    final logKey = key ?? message;
    final now = DateTime.now();
    final lastTime = _debounceTimestamps[logKey];

    if (lastTime == null || now.difference(lastTime) > debounce) {
      _debounceTimestamps[logKey] = now;
      debug(message);
    }
  }

  /// Log an info message.
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.info, message, error, stackTrace);
  }

  /// Log a warning message.
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.warning, message, error, stackTrace);
  }

  /// Log an error message.
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.error, message, error, stackTrace);
  }

  /// Log a fatal message (most severe).
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(Level.fatal, message, error, stackTrace);
  }

  static void _log(
    Level level,
    String message,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    if (_logger == null) {
      // Fallback if not initialized
      debugPrint('[$level] $message${error != null ? '\n$error' : ''}');
      return;
    }

    // Sanitize the message before logging
    final sanitizedMessage = LogSanitizer.sanitize(message);

    _logger!.log(
      level,
      sanitizedMessage,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Custom log printer that formats messages cleanly for both console and file.
class _AppLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final lines = <String>[];

    // Main message
    lines.add(event.message.toString());

    // Error if present
    if (event.error != null) {
      lines.add('  Error: ${event.error}');
    }

    // Stack trace if present (limit depth for readability)
    if (event.stackTrace != null) {
      final stackLines = event.stackTrace.toString().split('\n');
      final limitedStack = stackLines.take(10).join('\n');
      lines.add('  Stack:\n$limitedStack');
      if (stackLines.length > 10) {
        lines.add('  ... ${stackLines.length - 10} more frames');
      }
    }

    return lines;
  }
}
