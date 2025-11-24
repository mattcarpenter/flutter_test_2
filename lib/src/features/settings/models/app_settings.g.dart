// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => _AppSettings(
      version: (json['version'] as num?)?.toInt() ?? 1,
      homeScreen: json['homeScreen'] as String? ?? 'recipes',
      layout: json['layout'] == null
          ? const LayoutSettings()
          : LayoutSettings.fromJson(json['layout'] as Map<String, dynamic>),
      appearance: json['appearance'] == null
          ? const AppearanceSettings()
          : AppearanceSettings.fromJson(
              json['appearance'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{
      'version': instance.version,
      'homeScreen': instance.homeScreen,
      'layout': instance.layout,
      'appearance': instance.appearance,
    };

_LayoutSettings _$LayoutSettingsFromJson(Map<String, dynamic> json) =>
    _LayoutSettings(
      showFolders: json['showFolders'] as String? ?? 'all',
      showFoldersCount: (json['showFoldersCount'] as num?)?.toInt() ?? 6,
      folderSortOption:
          json['folderSortOption'] as String? ?? 'alphabetical_asc',
      customFolderOrder: (json['customFolderOrder'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$LayoutSettingsToJson(_LayoutSettings instance) =>
    <String, dynamic>{
      'showFolders': instance.showFolders,
      'showFoldersCount': instance.showFoldersCount,
      'folderSortOption': instance.folderSortOption,
      'customFolderOrder': instance.customFolderOrder,
    };

_AppearanceSettings _$AppearanceSettingsFromJson(Map<String, dynamic> json) =>
    _AppearanceSettings(
      themeMode: json['themeMode'] as String? ?? 'auto',
      recipeFontSize: json['recipeFontSize'] as String? ?? 'medium',
    );

Map<String, dynamic> _$AppearanceSettingsToJson(_AppearanceSettings instance) =>
    <String, dynamic>{
      'themeMode': instance.themeMode,
      'recipeFontSize': instance.recipeFontSize,
    };
