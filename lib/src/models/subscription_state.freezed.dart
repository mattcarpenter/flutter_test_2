// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubscriptionState {
  bool get hasPlus;
  bool get isLoading;
  bool get isRestoring;
  bool get isShowingPaywall;

  /// Temporary optimistic access granted immediately after purchase/restore,
  /// before the database has synced. Cleared when database confirms.
  bool get optimisticHasPlus;
  String? get error;
  DateTime? get lastChecked;
  Map<String, bool>? get entitlements;
  Map<String, dynamic>? get subscriptionMetadata;

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SubscriptionStateCopyWith<SubscriptionState> get copyWith =>
      _$SubscriptionStateCopyWithImpl<SubscriptionState>(
          this as SubscriptionState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SubscriptionState &&
            (identical(other.hasPlus, hasPlus) || other.hasPlus == hasPlus) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isRestoring, isRestoring) ||
                other.isRestoring == isRestoring) &&
            (identical(other.isShowingPaywall, isShowingPaywall) ||
                other.isShowingPaywall == isShowingPaywall) &&
            (identical(other.optimisticHasPlus, optimisticHasPlus) ||
                other.optimisticHasPlus == optimisticHasPlus) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.lastChecked, lastChecked) ||
                other.lastChecked == lastChecked) &&
            const DeepCollectionEquality()
                .equals(other.entitlements, entitlements) &&
            const DeepCollectionEquality()
                .equals(other.subscriptionMetadata, subscriptionMetadata));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      hasPlus,
      isLoading,
      isRestoring,
      isShowingPaywall,
      optimisticHasPlus,
      error,
      lastChecked,
      const DeepCollectionEquality().hash(entitlements),
      const DeepCollectionEquality().hash(subscriptionMetadata));

  @override
  String toString() {
    return 'SubscriptionState(hasPlus: $hasPlus, isLoading: $isLoading, isRestoring: $isRestoring, isShowingPaywall: $isShowingPaywall, optimisticHasPlus: $optimisticHasPlus, error: $error, lastChecked: $lastChecked, entitlements: $entitlements, subscriptionMetadata: $subscriptionMetadata)';
  }
}

/// @nodoc
abstract mixin class $SubscriptionStateCopyWith<$Res> {
  factory $SubscriptionStateCopyWith(
          SubscriptionState value, $Res Function(SubscriptionState) _then) =
      _$SubscriptionStateCopyWithImpl;
  @useResult
  $Res call(
      {bool hasPlus,
      bool isLoading,
      bool isRestoring,
      bool isShowingPaywall,
      bool optimisticHasPlus,
      String? error,
      DateTime? lastChecked,
      Map<String, bool>? entitlements,
      Map<String, dynamic>? subscriptionMetadata});
}

/// @nodoc
class _$SubscriptionStateCopyWithImpl<$Res>
    implements $SubscriptionStateCopyWith<$Res> {
  _$SubscriptionStateCopyWithImpl(this._self, this._then);

  final SubscriptionState _self;
  final $Res Function(SubscriptionState) _then;

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hasPlus = null,
    Object? isLoading = null,
    Object? isRestoring = null,
    Object? isShowingPaywall = null,
    Object? optimisticHasPlus = null,
    Object? error = freezed,
    Object? lastChecked = freezed,
    Object? entitlements = freezed,
    Object? subscriptionMetadata = freezed,
  }) {
    return _then(_self.copyWith(
      hasPlus: null == hasPlus
          ? _self.hasPlus
          : hasPlus // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isRestoring: null == isRestoring
          ? _self.isRestoring
          : isRestoring // ignore: cast_nullable_to_non_nullable
              as bool,
      isShowingPaywall: null == isShowingPaywall
          ? _self.isShowingPaywall
          : isShowingPaywall // ignore: cast_nullable_to_non_nullable
              as bool,
      optimisticHasPlus: null == optimisticHasPlus
          ? _self.optimisticHasPlus
          : optimisticHasPlus // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      lastChecked: freezed == lastChecked
          ? _self.lastChecked
          : lastChecked // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      entitlements: freezed == entitlements
          ? _self.entitlements
          : entitlements // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>?,
      subscriptionMetadata: freezed == subscriptionMetadata
          ? _self.subscriptionMetadata
          : subscriptionMetadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc

class _SubscriptionState extends SubscriptionState {
  const _SubscriptionState(
      {this.hasPlus = false,
      this.isLoading = false,
      this.isRestoring = false,
      this.isShowingPaywall = false,
      this.optimisticHasPlus = false,
      this.error,
      this.lastChecked,
      final Map<String, bool>? entitlements,
      final Map<String, dynamic>? subscriptionMetadata})
      : _entitlements = entitlements,
        _subscriptionMetadata = subscriptionMetadata,
        super._();

  @override
  @JsonKey()
  final bool hasPlus;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isRestoring;
  @override
  @JsonKey()
  final bool isShowingPaywall;

  /// Temporary optimistic access granted immediately after purchase/restore,
  /// before the database has synced. Cleared when database confirms.
  @override
  @JsonKey()
  final bool optimisticHasPlus;
  @override
  final String? error;
  @override
  final DateTime? lastChecked;
  final Map<String, bool>? _entitlements;
  @override
  Map<String, bool>? get entitlements {
    final value = _entitlements;
    if (value == null) return null;
    if (_entitlements is EqualUnmodifiableMapView) return _entitlements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final Map<String, dynamic>? _subscriptionMetadata;
  @override
  Map<String, dynamic>? get subscriptionMetadata {
    final value = _subscriptionMetadata;
    if (value == null) return null;
    if (_subscriptionMetadata is EqualUnmodifiableMapView)
      return _subscriptionMetadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SubscriptionStateCopyWith<_SubscriptionState> get copyWith =>
      __$SubscriptionStateCopyWithImpl<_SubscriptionState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SubscriptionState &&
            (identical(other.hasPlus, hasPlus) || other.hasPlus == hasPlus) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isRestoring, isRestoring) ||
                other.isRestoring == isRestoring) &&
            (identical(other.isShowingPaywall, isShowingPaywall) ||
                other.isShowingPaywall == isShowingPaywall) &&
            (identical(other.optimisticHasPlus, optimisticHasPlus) ||
                other.optimisticHasPlus == optimisticHasPlus) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.lastChecked, lastChecked) ||
                other.lastChecked == lastChecked) &&
            const DeepCollectionEquality()
                .equals(other._entitlements, _entitlements) &&
            const DeepCollectionEquality()
                .equals(other._subscriptionMetadata, _subscriptionMetadata));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      hasPlus,
      isLoading,
      isRestoring,
      isShowingPaywall,
      optimisticHasPlus,
      error,
      lastChecked,
      const DeepCollectionEquality().hash(_entitlements),
      const DeepCollectionEquality().hash(_subscriptionMetadata));

  @override
  String toString() {
    return 'SubscriptionState(hasPlus: $hasPlus, isLoading: $isLoading, isRestoring: $isRestoring, isShowingPaywall: $isShowingPaywall, optimisticHasPlus: $optimisticHasPlus, error: $error, lastChecked: $lastChecked, entitlements: $entitlements, subscriptionMetadata: $subscriptionMetadata)';
  }
}

/// @nodoc
abstract mixin class _$SubscriptionStateCopyWith<$Res>
    implements $SubscriptionStateCopyWith<$Res> {
  factory _$SubscriptionStateCopyWith(
          _SubscriptionState value, $Res Function(_SubscriptionState) _then) =
      __$SubscriptionStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool hasPlus,
      bool isLoading,
      bool isRestoring,
      bool isShowingPaywall,
      bool optimisticHasPlus,
      String? error,
      DateTime? lastChecked,
      Map<String, bool>? entitlements,
      Map<String, dynamic>? subscriptionMetadata});
}

/// @nodoc
class __$SubscriptionStateCopyWithImpl<$Res>
    implements _$SubscriptionStateCopyWith<$Res> {
  __$SubscriptionStateCopyWithImpl(this._self, this._then);

  final _SubscriptionState _self;
  final $Res Function(_SubscriptionState) _then;

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? hasPlus = null,
    Object? isLoading = null,
    Object? isRestoring = null,
    Object? isShowingPaywall = null,
    Object? optimisticHasPlus = null,
    Object? error = freezed,
    Object? lastChecked = freezed,
    Object? entitlements = freezed,
    Object? subscriptionMetadata = freezed,
  }) {
    return _then(_SubscriptionState(
      hasPlus: null == hasPlus
          ? _self.hasPlus
          : hasPlus // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isRestoring: null == isRestoring
          ? _self.isRestoring
          : isRestoring // ignore: cast_nullable_to_non_nullable
              as bool,
      isShowingPaywall: null == isShowingPaywall
          ? _self.isShowingPaywall
          : isShowingPaywall // ignore: cast_nullable_to_non_nullable
              as bool,
      optimisticHasPlus: null == optimisticHasPlus
          ? _self.optimisticHasPlus
          : optimisticHasPlus // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      lastChecked: freezed == lastChecked
          ? _self.lastChecked
          : lastChecked // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      entitlements: freezed == entitlements
          ? _self._entitlements
          : entitlements // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>?,
      subscriptionMetadata: freezed == subscriptionMetadata
          ? _self._subscriptionMetadata
          : subscriptionMetadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
mixin _$PaywallContext {
  String get source;
  String? get redirectPath;
  Map<String, dynamic>? get parameters;
  DateTime? get timestamp;

  /// Create a copy of PaywallContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PaywallContextCopyWith<PaywallContext> get copyWith =>
      _$PaywallContextCopyWithImpl<PaywallContext>(
          this as PaywallContext, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PaywallContext &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.redirectPath, redirectPath) ||
                other.redirectPath == redirectPath) &&
            const DeepCollectionEquality()
                .equals(other.parameters, parameters) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(runtimeType, source, redirectPath,
      const DeepCollectionEquality().hash(parameters), timestamp);

  @override
  String toString() {
    return 'PaywallContext(source: $source, redirectPath: $redirectPath, parameters: $parameters, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class $PaywallContextCopyWith<$Res> {
  factory $PaywallContextCopyWith(
          PaywallContext value, $Res Function(PaywallContext) _then) =
      _$PaywallContextCopyWithImpl;
  @useResult
  $Res call(
      {String source,
      String? redirectPath,
      Map<String, dynamic>? parameters,
      DateTime? timestamp});
}

/// @nodoc
class _$PaywallContextCopyWithImpl<$Res>
    implements $PaywallContextCopyWith<$Res> {
  _$PaywallContextCopyWithImpl(this._self, this._then);

  final PaywallContext _self;
  final $Res Function(PaywallContext) _then;

  /// Create a copy of PaywallContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = null,
    Object? redirectPath = freezed,
    Object? parameters = freezed,
    Object? timestamp = freezed,
  }) {
    return _then(_self.copyWith(
      source: null == source
          ? _self.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      redirectPath: freezed == redirectPath
          ? _self.redirectPath
          : redirectPath // ignore: cast_nullable_to_non_nullable
              as String?,
      parameters: freezed == parameters
          ? _self.parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      timestamp: freezed == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _PaywallContext extends PaywallContext {
  const _PaywallContext(
      {required this.source,
      this.redirectPath,
      final Map<String, dynamic>? parameters,
      this.timestamp})
      : _parameters = parameters,
        super._();

  @override
  final String source;
  @override
  final String? redirectPath;
  final Map<String, dynamic>? _parameters;
  @override
  Map<String, dynamic>? get parameters {
    final value = _parameters;
    if (value == null) return null;
    if (_parameters is EqualUnmodifiableMapView) return _parameters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime? timestamp;

  /// Create a copy of PaywallContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PaywallContextCopyWith<_PaywallContext> get copyWith =>
      __$PaywallContextCopyWithImpl<_PaywallContext>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PaywallContext &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.redirectPath, redirectPath) ||
                other.redirectPath == redirectPath) &&
            const DeepCollectionEquality()
                .equals(other._parameters, _parameters) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(runtimeType, source, redirectPath,
      const DeepCollectionEquality().hash(_parameters), timestamp);

  @override
  String toString() {
    return 'PaywallContext(source: $source, redirectPath: $redirectPath, parameters: $parameters, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class _$PaywallContextCopyWith<$Res>
    implements $PaywallContextCopyWith<$Res> {
  factory _$PaywallContextCopyWith(
          _PaywallContext value, $Res Function(_PaywallContext) _then) =
      __$PaywallContextCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String source,
      String? redirectPath,
      Map<String, dynamic>? parameters,
      DateTime? timestamp});
}

/// @nodoc
class __$PaywallContextCopyWithImpl<$Res>
    implements _$PaywallContextCopyWith<$Res> {
  __$PaywallContextCopyWithImpl(this._self, this._then);

  final _PaywallContext _self;
  final $Res Function(_PaywallContext) _then;

  /// Create a copy of PaywallContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? source = null,
    Object? redirectPath = freezed,
    Object? parameters = freezed,
    Object? timestamp = freezed,
  }) {
    return _then(_PaywallContext(
      source: null == source
          ? _self.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      redirectPath: freezed == redirectPath
          ? _self.redirectPath
          : redirectPath // ignore: cast_nullable_to_non_nullable
              as String?,
      parameters: freezed == parameters
          ? _self._parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      timestamp: freezed == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
