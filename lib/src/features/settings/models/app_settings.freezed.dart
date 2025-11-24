// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppSettings {
  int get version;
  String get homeScreen;
  LayoutSettings get layout;
  AppearanceSettings get appearance;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AppSettingsCopyWith<AppSettings> get copyWith =>
      _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);

  /// Serializes this AppSettings to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppSettings &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.homeScreen, homeScreen) ||
                other.homeScreen == homeScreen) &&
            (identical(other.layout, layout) || other.layout == layout) &&
            (identical(other.appearance, appearance) ||
                other.appearance == appearance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, version, homeScreen, layout, appearance);

  @override
  String toString() {
    return 'AppSettings(version: $version, homeScreen: $homeScreen, layout: $layout, appearance: $appearance)';
  }
}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res> {
  factory $AppSettingsCopyWith(
          AppSettings value, $Res Function(AppSettings) _then) =
      _$AppSettingsCopyWithImpl;
  @useResult
  $Res call(
      {int version,
      String homeScreen,
      LayoutSettings layout,
      AppearanceSettings appearance});

  $LayoutSettingsCopyWith<$Res> get layout;
  $AppearanceSettingsCopyWith<$Res> get appearance;
}

/// @nodoc
class _$AppSettingsCopyWithImpl<$Res> implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? homeScreen = null,
    Object? layout = null,
    Object? appearance = null,
  }) {
    return _then(_self.copyWith(
      version: null == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      homeScreen: null == homeScreen
          ? _self.homeScreen
          : homeScreen // ignore: cast_nullable_to_non_nullable
              as String,
      layout: null == layout
          ? _self.layout
          : layout // ignore: cast_nullable_to_non_nullable
              as LayoutSettings,
      appearance: null == appearance
          ? _self.appearance
          : appearance // ignore: cast_nullable_to_non_nullable
              as AppearanceSettings,
    ));
  }

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LayoutSettingsCopyWith<$Res> get layout {
    return $LayoutSettingsCopyWith<$Res>(_self.layout, (value) {
      return _then(_self.copyWith(layout: value));
    });
  }

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AppearanceSettingsCopyWith<$Res> get appearance {
    return $AppearanceSettingsCopyWith<$Res>(_self.appearance, (value) {
      return _then(_self.copyWith(appearance: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _AppSettings implements AppSettings {
  const _AppSettings(
      {this.version = 1,
      this.homeScreen = 'recipes',
      this.layout = const LayoutSettings(),
      this.appearance = const AppearanceSettings()});
  factory _AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  @override
  @JsonKey()
  final int version;
  @override
  @JsonKey()
  final String homeScreen;
  @override
  @JsonKey()
  final LayoutSettings layout;
  @override
  @JsonKey()
  final AppearanceSettings appearance;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AppSettingsCopyWith<_AppSettings> get copyWith =>
      __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AppSettingsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AppSettings &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.homeScreen, homeScreen) ||
                other.homeScreen == homeScreen) &&
            (identical(other.layout, layout) || other.layout == layout) &&
            (identical(other.appearance, appearance) ||
                other.appearance == appearance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, version, homeScreen, layout, appearance);

  @override
  String toString() {
    return 'AppSettings(version: $version, homeScreen: $homeScreen, layout: $layout, appearance: $appearance)';
  }
}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res>
    implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(
          _AppSettings value, $Res Function(_AppSettings) _then) =
      __$AppSettingsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int version,
      String homeScreen,
      LayoutSettings layout,
      AppearanceSettings appearance});

  @override
  $LayoutSettingsCopyWith<$Res> get layout;
  @override
  $AppearanceSettingsCopyWith<$Res> get appearance;
}

/// @nodoc
class __$AppSettingsCopyWithImpl<$Res> implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? version = null,
    Object? homeScreen = null,
    Object? layout = null,
    Object? appearance = null,
  }) {
    return _then(_AppSettings(
      version: null == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      homeScreen: null == homeScreen
          ? _self.homeScreen
          : homeScreen // ignore: cast_nullable_to_non_nullable
              as String,
      layout: null == layout
          ? _self.layout
          : layout // ignore: cast_nullable_to_non_nullable
              as LayoutSettings,
      appearance: null == appearance
          ? _self.appearance
          : appearance // ignore: cast_nullable_to_non_nullable
              as AppearanceSettings,
    ));
  }

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LayoutSettingsCopyWith<$Res> get layout {
    return $LayoutSettingsCopyWith<$Res>(_self.layout, (value) {
      return _then(_self.copyWith(layout: value));
    });
  }

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AppearanceSettingsCopyWith<$Res> get appearance {
    return $AppearanceSettingsCopyWith<$Res>(_self.appearance, (value) {
      return _then(_self.copyWith(appearance: value));
    });
  }
}

/// @nodoc
mixin _$LayoutSettings {
  String get showFolders; // 'all' or 'firstN'
  int get showFoldersCount; // N when showFolders is 'firstN'
  String get folderSortOption;
  List<String> get customFolderOrder;

  /// Create a copy of LayoutSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LayoutSettingsCopyWith<LayoutSettings> get copyWith =>
      _$LayoutSettingsCopyWithImpl<LayoutSettings>(
          this as LayoutSettings, _$identity);

  /// Serializes this LayoutSettings to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LayoutSettings &&
            (identical(other.showFolders, showFolders) ||
                other.showFolders == showFolders) &&
            (identical(other.showFoldersCount, showFoldersCount) ||
                other.showFoldersCount == showFoldersCount) &&
            (identical(other.folderSortOption, folderSortOption) ||
                other.folderSortOption == folderSortOption) &&
            const DeepCollectionEquality()
                .equals(other.customFolderOrder, customFolderOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, showFolders, showFoldersCount,
      folderSortOption, const DeepCollectionEquality().hash(customFolderOrder));

  @override
  String toString() {
    return 'LayoutSettings(showFolders: $showFolders, showFoldersCount: $showFoldersCount, folderSortOption: $folderSortOption, customFolderOrder: $customFolderOrder)';
  }
}

/// @nodoc
abstract mixin class $LayoutSettingsCopyWith<$Res> {
  factory $LayoutSettingsCopyWith(
          LayoutSettings value, $Res Function(LayoutSettings) _then) =
      _$LayoutSettingsCopyWithImpl;
  @useResult
  $Res call(
      {String showFolders,
      int showFoldersCount,
      String folderSortOption,
      List<String> customFolderOrder});
}

/// @nodoc
class _$LayoutSettingsCopyWithImpl<$Res>
    implements $LayoutSettingsCopyWith<$Res> {
  _$LayoutSettingsCopyWithImpl(this._self, this._then);

  final LayoutSettings _self;
  final $Res Function(LayoutSettings) _then;

  /// Create a copy of LayoutSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? showFolders = null,
    Object? showFoldersCount = null,
    Object? folderSortOption = null,
    Object? customFolderOrder = null,
  }) {
    return _then(_self.copyWith(
      showFolders: null == showFolders
          ? _self.showFolders
          : showFolders // ignore: cast_nullable_to_non_nullable
              as String,
      showFoldersCount: null == showFoldersCount
          ? _self.showFoldersCount
          : showFoldersCount // ignore: cast_nullable_to_non_nullable
              as int,
      folderSortOption: null == folderSortOption
          ? _self.folderSortOption
          : folderSortOption // ignore: cast_nullable_to_non_nullable
              as String,
      customFolderOrder: null == customFolderOrder
          ? _self.customFolderOrder
          : customFolderOrder // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _LayoutSettings implements LayoutSettings {
  const _LayoutSettings(
      {this.showFolders = 'all',
      this.showFoldersCount = 6,
      this.folderSortOption = 'alphabetical_asc',
      final List<String> customFolderOrder = const []})
      : _customFolderOrder = customFolderOrder;
  factory _LayoutSettings.fromJson(Map<String, dynamic> json) =>
      _$LayoutSettingsFromJson(json);

  @override
  @JsonKey()
  final String showFolders;
// 'all' or 'firstN'
  @override
  @JsonKey()
  final int showFoldersCount;
// N when showFolders is 'firstN'
  @override
  @JsonKey()
  final String folderSortOption;
  final List<String> _customFolderOrder;
  @override
  @JsonKey()
  List<String> get customFolderOrder {
    if (_customFolderOrder is EqualUnmodifiableListView)
      return _customFolderOrder;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_customFolderOrder);
  }

  /// Create a copy of LayoutSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LayoutSettingsCopyWith<_LayoutSettings> get copyWith =>
      __$LayoutSettingsCopyWithImpl<_LayoutSettings>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LayoutSettingsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LayoutSettings &&
            (identical(other.showFolders, showFolders) ||
                other.showFolders == showFolders) &&
            (identical(other.showFoldersCount, showFoldersCount) ||
                other.showFoldersCount == showFoldersCount) &&
            (identical(other.folderSortOption, folderSortOption) ||
                other.folderSortOption == folderSortOption) &&
            const DeepCollectionEquality()
                .equals(other._customFolderOrder, _customFolderOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      showFolders,
      showFoldersCount,
      folderSortOption,
      const DeepCollectionEquality().hash(_customFolderOrder));

  @override
  String toString() {
    return 'LayoutSettings(showFolders: $showFolders, showFoldersCount: $showFoldersCount, folderSortOption: $folderSortOption, customFolderOrder: $customFolderOrder)';
  }
}

/// @nodoc
abstract mixin class _$LayoutSettingsCopyWith<$Res>
    implements $LayoutSettingsCopyWith<$Res> {
  factory _$LayoutSettingsCopyWith(
          _LayoutSettings value, $Res Function(_LayoutSettings) _then) =
      __$LayoutSettingsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String showFolders,
      int showFoldersCount,
      String folderSortOption,
      List<String> customFolderOrder});
}

/// @nodoc
class __$LayoutSettingsCopyWithImpl<$Res>
    implements _$LayoutSettingsCopyWith<$Res> {
  __$LayoutSettingsCopyWithImpl(this._self, this._then);

  final _LayoutSettings _self;
  final $Res Function(_LayoutSettings) _then;

  /// Create a copy of LayoutSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? showFolders = null,
    Object? showFoldersCount = null,
    Object? folderSortOption = null,
    Object? customFolderOrder = null,
  }) {
    return _then(_LayoutSettings(
      showFolders: null == showFolders
          ? _self.showFolders
          : showFolders // ignore: cast_nullable_to_non_nullable
              as String,
      showFoldersCount: null == showFoldersCount
          ? _self.showFoldersCount
          : showFoldersCount // ignore: cast_nullable_to_non_nullable
              as int,
      folderSortOption: null == folderSortOption
          ? _self.folderSortOption
          : folderSortOption // ignore: cast_nullable_to_non_nullable
              as String,
      customFolderOrder: null == customFolderOrder
          ? _self._customFolderOrder
          : customFolderOrder // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
mixin _$AppearanceSettings {
  String get themeMode; // 'light', 'dark', 'auto'
  String get recipeFontSize;

  /// Create a copy of AppearanceSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AppearanceSettingsCopyWith<AppearanceSettings> get copyWith =>
      _$AppearanceSettingsCopyWithImpl<AppearanceSettings>(
          this as AppearanceSettings, _$identity);

  /// Serializes this AppearanceSettings to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppearanceSettings &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode) &&
            (identical(other.recipeFontSize, recipeFontSize) ||
                other.recipeFontSize == recipeFontSize));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, themeMode, recipeFontSize);

  @override
  String toString() {
    return 'AppearanceSettings(themeMode: $themeMode, recipeFontSize: $recipeFontSize)';
  }
}

/// @nodoc
abstract mixin class $AppearanceSettingsCopyWith<$Res> {
  factory $AppearanceSettingsCopyWith(
          AppearanceSettings value, $Res Function(AppearanceSettings) _then) =
      _$AppearanceSettingsCopyWithImpl;
  @useResult
  $Res call({String themeMode, String recipeFontSize});
}

/// @nodoc
class _$AppearanceSettingsCopyWithImpl<$Res>
    implements $AppearanceSettingsCopyWith<$Res> {
  _$AppearanceSettingsCopyWithImpl(this._self, this._then);

  final AppearanceSettings _self;
  final $Res Function(AppearanceSettings) _then;

  /// Create a copy of AppearanceSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? themeMode = null,
    Object? recipeFontSize = null,
  }) {
    return _then(_self.copyWith(
      themeMode: null == themeMode
          ? _self.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as String,
      recipeFontSize: null == recipeFontSize
          ? _self.recipeFontSize
          : recipeFontSize // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _AppearanceSettings implements AppearanceSettings {
  const _AppearanceSettings(
      {this.themeMode = 'auto', this.recipeFontSize = 'medium'});
  factory _AppearanceSettings.fromJson(Map<String, dynamic> json) =>
      _$AppearanceSettingsFromJson(json);

  @override
  @JsonKey()
  final String themeMode;
// 'light', 'dark', 'auto'
  @override
  @JsonKey()
  final String recipeFontSize;

  /// Create a copy of AppearanceSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AppearanceSettingsCopyWith<_AppearanceSettings> get copyWith =>
      __$AppearanceSettingsCopyWithImpl<_AppearanceSettings>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AppearanceSettingsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AppearanceSettings &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode) &&
            (identical(other.recipeFontSize, recipeFontSize) ||
                other.recipeFontSize == recipeFontSize));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, themeMode, recipeFontSize);

  @override
  String toString() {
    return 'AppearanceSettings(themeMode: $themeMode, recipeFontSize: $recipeFontSize)';
  }
}

/// @nodoc
abstract mixin class _$AppearanceSettingsCopyWith<$Res>
    implements $AppearanceSettingsCopyWith<$Res> {
  factory _$AppearanceSettingsCopyWith(
          _AppearanceSettings value, $Res Function(_AppearanceSettings) _then) =
      __$AppearanceSettingsCopyWithImpl;
  @override
  @useResult
  $Res call({String themeMode, String recipeFontSize});
}

/// @nodoc
class __$AppearanceSettingsCopyWithImpl<$Res>
    implements _$AppearanceSettingsCopyWith<$Res> {
  __$AppearanceSettingsCopyWithImpl(this._self, this._then);

  final _AppearanceSettings _self;
  final $Res Function(_AppearanceSettings) _then;

  /// Create a copy of AppearanceSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? themeMode = null,
    Object? recipeFontSize = null,
  }) {
    return _then(_AppearanceSettings(
      themeMode: null == themeMode
          ? _self.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as String,
      recipeFontSize: null == recipeFontSize
          ? _self.recipeFontSize
          : recipeFontSize // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
