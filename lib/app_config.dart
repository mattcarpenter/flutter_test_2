import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;

class AppConfig {
  // Production fallback values - used when .env file is not available (like in production builds)
  static const String _prodSupabaseUrl = 'https://ekodhfnrvdovejiblnwe.supabase.co';
  static const String _prodSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVrb2RoZm5ydmRvdmVqaWJsbndlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzgyMjQ1ODcsImV4cCI6MjA1MzgwMDU4N30.ZlLSvOd4fgmGCmUqxwsFwA7ceSH80slwtf17Zq2fas0';
  static const String _prodPowersyncUrl = 'https://67b91959ee50386f3169557f.powersync.journeyapps.com';
  static const String _prodSupabaseStorageBucket = '';
  //static const String _prodIngredientApiUrl = 'http://192.168.2.150:3000';
  static const String _prodIngredientApiUrl = 'http://localhost:3000';

  static bool _isInitialized = false;
  static bool _isTestMode = false;

  // Initialize by loading the appropriate .env file if in development
  static Future<void> initialize({bool isTest = false}) async {
    debugPrint('Initializing appconfig...');
    _isTestMode = isTest;

    try {
      if (isTest) {
        final envFilePath = p.join(Directory.current.path, '.env.test');
        await dotenv.load(fileName: envFilePath);
      };
      _isInitialized = true;
    } catch (e) {
      debugPrint("Error loading environment: $e");
      // Continue with hardcoded values
      _isInitialized = true; // Still mark as initialized to use fallbacks
    }
    debugPrint('AppConfig initialized.');
  }

  // Getters that try env vars first, then fall back to hardcoded production values
  static String get supabaseUrl {
    _ensureInitialized();
    return _getEnvValue('SUPABASE_URL', _prodSupabaseUrl) ?? '';
  }

  static String get supabaseAnonKey {
    _ensureInitialized();
    return _getEnvValue('SUPABASE_ANON_KEY', _prodSupabaseAnonKey) ?? '';
  }

  static String get powersyncUrl {
    _ensureInitialized();
    return _getEnvValue('POWERSYNC_URL', _prodPowersyncUrl) ?? '';
  }

  static String get supabaseStorageBucket {
    _ensureInitialized();
    return _getEnvValue('SUPABASE_STORAGE_BUCKET', _prodSupabaseStorageBucket) ?? '';
  }

  static String get ingredientApiUrl {
    _ensureInitialized();
    return _getEnvValue('INGREDIENT_API_URL', _prodIngredientApiUrl) ?? '';
  }

  // Helper to ensure initialization
  static void _ensureInitialized() {
    if (!_isInitialized) {
      debugPrint("Warning: AppConfig.initialize() was not called. Using production values.");
      _isInitialized = true;
    }
  }

  // Safe helper to get environment values with fallback
  static String? _getEnvValue(String key, String? fallback) {
    try {
      final value = dotenv.env[key];
      return (value != null && value.isNotEmpty) ? value : fallback;
    } catch (e) {
      return fallback;
    }
  }
}
