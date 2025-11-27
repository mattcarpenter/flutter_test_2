import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/app_settings.dart';

import '../../../services/logging/app_logger.dart';

/// Service for persisting app settings to a JSON file
class SettingsStorageService {
  static const String _fileName = 'app_settings.json';

  File? _cachedFile;

  /// Get the settings file, creating directories if needed
  Future<File> get _settingsFile async {
    if (_cachedFile != null) return _cachedFile!;

    final directory = await getApplicationDocumentsDirectory();
    _cachedFile = File('${directory.path}/$_fileName');
    return _cachedFile!;
  }

  /// Load settings from JSON file, returning defaults if file doesn't exist
  Future<AppSettings> loadSettings() async {
    try {
      final file = await _settingsFile;

      if (!await file.exists()) {
        return const AppSettings();
      }

      final contents = await file.readAsString();
      if (contents.isEmpty) {
        return const AppSettings();
      }

      final json = jsonDecode(contents) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (e) {
      // If there's any error parsing, return defaults
      AppLogger.error('Error loading settings', e);
      return const AppSettings();
    }
  }

  /// Save settings to JSON file with atomic write
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final file = await _settingsFile;

      // Create parent directories if they don't exist
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      // Write to temp file first, then rename for atomic operation
      final tempFile = File('${file.path}.tmp');
      final jsonString = const JsonEncoder.withIndent('  ').convert(settings.toJson());
      await tempFile.writeAsString(jsonString);
      await tempFile.rename(file.path);
    } catch (e) {
      AppLogger.error('Error saving settings', e);
      rethrow;
    }
  }

  /// Delete settings file (for testing/reset)
  Future<void> deleteSettings() async {
    try {
      final file = await _settingsFile;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      AppLogger.error('Error deleting settings', e);
    }
  }
}
