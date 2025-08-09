// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'household_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HouseholdState {
  HouseholdEntry? get currentHousehold;
  List<HouseholdMember> get members;
  List<HouseholdInvite> get outgoingInvites;
  List<HouseholdInvite> get incomingInvites;
  bool get isLoading;
  String? get error;
  bool get isCreatingInvite;
  bool get isLeavingHousehold;

  /// Create a copy of HouseholdState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HouseholdStateCopyWith<HouseholdState> get copyWith =>
      _$HouseholdStateCopyWithImpl<HouseholdState>(
          this as HouseholdState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HouseholdState &&
            const DeepCollectionEquality()
                .equals(other.currentHousehold, currentHousehold) &&
            const DeepCollectionEquality().equals(other.members, members) &&
            const DeepCollectionEquality()
                .equals(other.outgoingInvites, outgoingInvites) &&
            const DeepCollectionEquality()
                .equals(other.incomingInvites, incomingInvites) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isCreatingInvite, isCreatingInvite) ||
                other.isCreatingInvite == isCreatingInvite) &&
            (identical(other.isLeavingHousehold, isLeavingHousehold) ||
                other.isLeavingHousehold == isLeavingHousehold));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(currentHousehold),
      const DeepCollectionEquality().hash(members),
      const DeepCollectionEquality().hash(outgoingInvites),
      const DeepCollectionEquality().hash(incomingInvites),
      isLoading,
      error,
      isCreatingInvite,
      isLeavingHousehold);

  @override
  String toString() {
    return 'HouseholdState(currentHousehold: $currentHousehold, members: $members, outgoingInvites: $outgoingInvites, incomingInvites: $incomingInvites, isLoading: $isLoading, error: $error, isCreatingInvite: $isCreatingInvite, isLeavingHousehold: $isLeavingHousehold)';
  }
}

/// @nodoc
abstract mixin class $HouseholdStateCopyWith<$Res> {
  factory $HouseholdStateCopyWith(
          HouseholdState value, $Res Function(HouseholdState) _then) =
      _$HouseholdStateCopyWithImpl;
  @useResult
  $Res call(
      {HouseholdEntry? currentHousehold,
      List<HouseholdMember> members,
      List<HouseholdInvite> outgoingInvites,
      List<HouseholdInvite> incomingInvites,
      bool isLoading,
      String? error,
      bool isCreatingInvite,
      bool isLeavingHousehold});
}

/// @nodoc
class _$HouseholdStateCopyWithImpl<$Res>
    implements $HouseholdStateCopyWith<$Res> {
  _$HouseholdStateCopyWithImpl(this._self, this._then);

  final HouseholdState _self;
  final $Res Function(HouseholdState) _then;

  /// Create a copy of HouseholdState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentHousehold = freezed,
    Object? members = null,
    Object? outgoingInvites = null,
    Object? incomingInvites = null,
    Object? isLoading = null,
    Object? error = freezed,
    Object? isCreatingInvite = null,
    Object? isLeavingHousehold = null,
  }) {
    return _then(_self.copyWith(
      currentHousehold: freezed == currentHousehold
          ? _self.currentHousehold
          : currentHousehold // ignore: cast_nullable_to_non_nullable
              as HouseholdEntry?,
      members: null == members
          ? _self.members
          : members // ignore: cast_nullable_to_non_nullable
              as List<HouseholdMember>,
      outgoingInvites: null == outgoingInvites
          ? _self.outgoingInvites
          : outgoingInvites // ignore: cast_nullable_to_non_nullable
              as List<HouseholdInvite>,
      incomingInvites: null == incomingInvites
          ? _self.incomingInvites
          : incomingInvites // ignore: cast_nullable_to_non_nullable
              as List<HouseholdInvite>,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isCreatingInvite: null == isCreatingInvite
          ? _self.isCreatingInvite
          : isCreatingInvite // ignore: cast_nullable_to_non_nullable
              as bool,
      isLeavingHousehold: null == isLeavingHousehold
          ? _self.isLeavingHousehold
          : isLeavingHousehold // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _HouseholdState extends HouseholdState {
  const _HouseholdState(
      {this.currentHousehold,
      final List<HouseholdMember> members = const [],
      final List<HouseholdInvite> outgoingInvites = const [],
      final List<HouseholdInvite> incomingInvites = const [],
      this.isLoading = false,
      this.error,
      this.isCreatingInvite = false,
      this.isLeavingHousehold = false})
      : _members = members,
        _outgoingInvites = outgoingInvites,
        _incomingInvites = incomingInvites,
        super._();

  @override
  final HouseholdEntry? currentHousehold;
  final List<HouseholdMember> _members;
  @override
  @JsonKey()
  List<HouseholdMember> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  final List<HouseholdInvite> _outgoingInvites;
  @override
  @JsonKey()
  List<HouseholdInvite> get outgoingInvites {
    if (_outgoingInvites is EqualUnmodifiableListView) return _outgoingInvites;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_outgoingInvites);
  }

  final List<HouseholdInvite> _incomingInvites;
  @override
  @JsonKey()
  List<HouseholdInvite> get incomingInvites {
    if (_incomingInvites is EqualUnmodifiableListView) return _incomingInvites;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_incomingInvites);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;
  @override
  @JsonKey()
  final bool isCreatingInvite;
  @override
  @JsonKey()
  final bool isLeavingHousehold;

  /// Create a copy of HouseholdState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HouseholdStateCopyWith<_HouseholdState> get copyWith =>
      __$HouseholdStateCopyWithImpl<_HouseholdState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HouseholdState &&
            const DeepCollectionEquality()
                .equals(other.currentHousehold, currentHousehold) &&
            const DeepCollectionEquality().equals(other._members, _members) &&
            const DeepCollectionEquality()
                .equals(other._outgoingInvites, _outgoingInvites) &&
            const DeepCollectionEquality()
                .equals(other._incomingInvites, _incomingInvites) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isCreatingInvite, isCreatingInvite) ||
                other.isCreatingInvite == isCreatingInvite) &&
            (identical(other.isLeavingHousehold, isLeavingHousehold) ||
                other.isLeavingHousehold == isLeavingHousehold));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(currentHousehold),
      const DeepCollectionEquality().hash(_members),
      const DeepCollectionEquality().hash(_outgoingInvites),
      const DeepCollectionEquality().hash(_incomingInvites),
      isLoading,
      error,
      isCreatingInvite,
      isLeavingHousehold);

  @override
  String toString() {
    return 'HouseholdState(currentHousehold: $currentHousehold, members: $members, outgoingInvites: $outgoingInvites, incomingInvites: $incomingInvites, isLoading: $isLoading, error: $error, isCreatingInvite: $isCreatingInvite, isLeavingHousehold: $isLeavingHousehold)';
  }
}

/// @nodoc
abstract mixin class _$HouseholdStateCopyWith<$Res>
    implements $HouseholdStateCopyWith<$Res> {
  factory _$HouseholdStateCopyWith(
          _HouseholdState value, $Res Function(_HouseholdState) _then) =
      __$HouseholdStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {HouseholdEntry? currentHousehold,
      List<HouseholdMember> members,
      List<HouseholdInvite> outgoingInvites,
      List<HouseholdInvite> incomingInvites,
      bool isLoading,
      String? error,
      bool isCreatingInvite,
      bool isLeavingHousehold});
}

/// @nodoc
class __$HouseholdStateCopyWithImpl<$Res>
    implements _$HouseholdStateCopyWith<$Res> {
  __$HouseholdStateCopyWithImpl(this._self, this._then);

  final _HouseholdState _self;
  final $Res Function(_HouseholdState) _then;

  /// Create a copy of HouseholdState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? currentHousehold = freezed,
    Object? members = null,
    Object? outgoingInvites = null,
    Object? incomingInvites = null,
    Object? isLoading = null,
    Object? error = freezed,
    Object? isCreatingInvite = null,
    Object? isLeavingHousehold = null,
  }) {
    return _then(_HouseholdState(
      currentHousehold: freezed == currentHousehold
          ? _self.currentHousehold
          : currentHousehold // ignore: cast_nullable_to_non_nullable
              as HouseholdEntry?,
      members: null == members
          ? _self._members
          : members // ignore: cast_nullable_to_non_nullable
              as List<HouseholdMember>,
      outgoingInvites: null == outgoingInvites
          ? _self._outgoingInvites
          : outgoingInvites // ignore: cast_nullable_to_non_nullable
              as List<HouseholdInvite>,
      incomingInvites: null == incomingInvites
          ? _self._incomingInvites
          : incomingInvites // ignore: cast_nullable_to_non_nullable
              as List<HouseholdInvite>,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isCreatingInvite: null == isCreatingInvite
          ? _self.isCreatingInvite
          : isCreatingInvite // ignore: cast_nullable_to_non_nullable
              as bool,
      isLeavingHousehold: null == isLeavingHousehold
          ? _self.isLeavingHousehold
          : isLeavingHousehold // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
