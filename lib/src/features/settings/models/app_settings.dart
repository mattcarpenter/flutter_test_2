import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

/// Main app settings model stored in JSON file
@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(1) int version,
    @Default('recipes') String homeScreen,
    @Default(LayoutSettings()) LayoutSettings layout,
    @Default(AppearanceSettings()) AppearanceSettings appearance,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}

/// Layout-related settings for recipes page
@freezed
abstract class LayoutSettings with _$LayoutSettings {
  const factory LayoutSettings({
    @Default('all') String showFolders, // 'all' or 'firstN'
    @Default(6) int showFoldersCount, // N when showFolders is 'firstN'
    @Default('alphabetical_asc') String folderSortOption,
    @Default([]) List<String> customFolderOrder,
  }) = _LayoutSettings;

  factory LayoutSettings.fromJson(Map<String, dynamic> json) =>
      _$LayoutSettingsFromJson(json);
}

/// Appearance-related settings
@freezed
abstract class AppearanceSettings with _$AppearanceSettings {
  const factory AppearanceSettings({
    @Default('auto') String themeMode, // 'light', 'dark', 'auto'
    @Default('medium') String recipeFontSize, // 'small', 'medium', 'large'
  }) = _AppearanceSettings;

  factory AppearanceSettings.fromJson(Map<String, dynamic> json) =>
      _$AppearanceSettingsFromJson(json);
}

/// Helper extension for theme mode conversion
extension ThemeModeString on String {
  bool get isLight => this == 'light';
  bool get isDark => this == 'dark';
  bool get isAuto => this == 'auto';
}

/// Helper extension for font size
extension FontSizeString on String {
  double get scaleFactor => switch (this) {
        'small' => 0.85,
        'large' => 1.15,
        _ => 1.0, // medium
      };
}
