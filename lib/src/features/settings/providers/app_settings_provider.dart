import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/settings_storage_service.dart';

/// Provider for the settings storage service
final settingsStorageServiceProvider = Provider<SettingsStorageService>((ref) {
  return SettingsStorageService();
});

/// State for the settings notifier
class AppSettingsState {
  final AppSettings settings;
  final bool isLoading;
  final Object? error;

  const AppSettingsState({
    required this.settings,
    this.isLoading = false,
    this.error,
  });

  AppSettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
    Object? error,
  }) {
    return AppSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Main settings notifier using StateNotifier pattern
class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  final SettingsStorageService _storageService;
  bool _preloaded = false;

  AppSettingsNotifier(this._storageService)
      : super(const AppSettingsState(
          settings: AppSettings(),
          isLoading: true,
        )) {
    // Only load if not preloaded (preloaded via setPreloadedSettings in main.dart)
    Future.microtask(() {
      if (!_preloaded) {
        _loadSettings();
      }
    });
  }

  /// Set pre-loaded settings (called from main.dart before app starts)
  void setPreloadedSettings(AppSettings settings) {
    _preloaded = true;
    state = AppSettingsState(settings: settings, isLoading: false);
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _storageService.loadSettings();
      state = AppSettingsState(settings: settings, isLoading: false);
    } catch (e) {
      state = AppSettingsState(
        settings: const AppSettings(),
        isLoading: false,
        error: e,
      );
    }
  }

  Future<void> _saveSettings(AppSettings settings) async {
    state = state.copyWith(settings: settings);
    await _storageService.saveSettings(settings);
  }

  // ─────────────────────────────────────────────────────────────
  // Home Screen Setting
  // ─────────────────────────────────────────────────────────────

  Future<void> setHomeScreen(String value) async {
    final updated = state.settings.copyWith(homeScreen: value);
    await _saveSettings(updated);
  }

  // ─────────────────────────────────────────────────────────────
  // Theme Mode Setting
  // ─────────────────────────────────────────────────────────────

  Future<void> setThemeMode(String value) async {
    final updated = state.settings.copyWith(
      appearance: state.settings.appearance.copyWith(themeMode: value),
    );
    await _saveSettings(updated);
  }

  // ─────────────────────────────────────────────────────────────
  // Recipe Font Size Setting
  // ─────────────────────────────────────────────────────────────

  Future<void> setRecipeFontSize(String value) async {
    final updated = state.settings.copyWith(
      appearance: state.settings.appearance.copyWith(recipeFontSize: value),
    );
    await _saveSettings(updated);
  }

  // ─────────────────────────────────────────────────────────────
  // Show Folders Setting
  // ─────────────────────────────────────────────────────────────

  Future<void> setShowFolders(String value) async {
    final updated = state.settings.copyWith(
      layout: state.settings.layout.copyWith(showFolders: value),
    );
    await _saveSettings(updated);
  }

  Future<void> setShowFoldersCount(int value) async {
    final updated = state.settings.copyWith(
      layout: state.settings.layout.copyWith(showFoldersCount: value),
    );
    await _saveSettings(updated);
  }

  // ─────────────────────────────────────────────────────────────
  // Folder Sort Setting
  // ─────────────────────────────────────────────────────────────

  Future<void> setFolderSortOption(String value) async {
    final updated = state.settings.copyWith(
      layout: state.settings.layout.copyWith(folderSortOption: value),
    );
    await _saveSettings(updated);
  }

  Future<void> setCustomFolderOrder(List<String> order) async {
    final updated = state.settings.copyWith(
      layout: state.settings.layout.copyWith(customFolderOrder: order),
    );
    await _saveSettings(updated);
  }

  /// Update both sort option and custom order at once
  Future<void> setFolderSortWithOrder(String sortOption, List<String> order) async {
    final updated = state.settings.copyWith(
      layout: state.settings.layout.copyWith(
        folderSortOption: sortOption,
        customFolderOrder: order,
      ),
    );
    await _saveSettings(updated);
  }
}

/// Main settings provider
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  final storageService = ref.watch(settingsStorageServiceProvider);
  return AppSettingsNotifier(storageService);
});

// ─────────────────────────────────────────────────────────────
// Derived Providers for Easy Access
// ─────────────────────────────────────────────────────────────

/// Current theme mode as Flutter ThemeMode enum
final appThemeModeProvider = Provider<ThemeMode>((ref) {
  final settingsState = ref.watch(appSettingsProvider);
  return switch (settingsState.settings.appearance.themeMode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});

/// Current theme mode as string
final themeModeStringProvider = Provider<String>((ref) {
  final settingsState = ref.watch(appSettingsProvider);
  return settingsState.settings.appearance.themeMode;
});

/// Current home screen setting
final homeScreenProvider = Provider<String>((ref) {
  final settingsState = ref.watch(appSettingsProvider);
  return settingsState.settings.homeScreen;
});

/// Show folders setting ('all' or 'firstN')
final showFoldersProvider = Provider<String>((ref) {
  final settingsState = ref.watch(appSettingsProvider);
  return settingsState.settings.layout.showFolders;
});

/// Number of folders to show when showFolders is 'firstN'
final showFoldersCountProvider = Provider<int>((ref) {
  final settingsState = ref.watch(appSettingsProvider);
  return settingsState.settings.layout.showFoldersCount;
});

/// Current folder sort option
final folderSortOptionProvider = Provider<String>((ref) {
  final settingsState = ref.watch(appSettingsProvider);
  return settingsState.settings.layout.folderSortOption;
});

/// Custom folder order (list of folder IDs)
final customFolderOrderProvider = Provider<List<String>>((ref) {
  final settingsState = ref.watch(appSettingsProvider);
  return settingsState.settings.layout.customFolderOrder;
});

/// Recipe font size setting
final recipeFontSizeProvider = Provider<String>((ref) {
  final settingsState = ref.watch(appSettingsProvider);
  return settingsState.settings.appearance.recipeFontSize;
});

/// Recipe font scale factor (0.85, 1.0, or 1.15)
final recipeFontScaleProvider = Provider<double>((ref) {
  final fontSize = ref.watch(recipeFontSizeProvider);
  return fontSize.scaleFactor;
});

/// Settings loading state
final settingsLoadingProvider = Provider<bool>((ref) {
  final settingsState = ref.watch(appSettingsProvider);
  return settingsState.isLoading;
});
