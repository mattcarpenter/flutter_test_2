// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'household_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$HouseholdState {
  HouseholdEntry? get currentHousehold => throw _privateConstructorUsedError;
  List<HouseholdMember> get members => throw _privateConstructorUsedError;
  List<HouseholdInvite> get outgoingInvites =>
      throw _privateConstructorUsedError;
  List<HouseholdInvite> get incomingInvites =>
      throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  bool get isCreatingInvite => throw _privateConstructorUsedError;
  bool get isLeavingHousehold => throw _privateConstructorUsedError;

  /// Create a copy of HouseholdState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HouseholdStateCopyWith<HouseholdState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HouseholdStateCopyWith<$Res> {
  factory $HouseholdStateCopyWith(
          HouseholdState value, $Res Function(HouseholdState) then) =
      _$HouseholdStateCopyWithImpl<$Res, HouseholdState>;
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
class _$HouseholdStateCopyWithImpl<$Res, $Val extends HouseholdState>
    implements $HouseholdStateCopyWith<$Res> {
  _$HouseholdStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    return _then(_value.copyWith(
      currentHousehold: freezed == currentHousehold
          ? _value.currentHousehold
          : currentHousehold // ignore: cast_nullable_to_non_nullable
              as HouseholdEntry?,
      members: null == members
          ? _value.members
          : members // ignore: cast_nullable_to_non_nullable
              as List<HouseholdMember>,
      outgoingInvites: null == outgoingInvites
          ? _value.outgoingInvites
          : outgoingInvites // ignore: cast_nullable_to_non_nullable
              as List<HouseholdInvite>,
      incomingInvites: null == incomingInvites
          ? _value.incomingInvites
          : incomingInvites // ignore: cast_nullable_to_non_nullable
              as List<HouseholdInvite>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isCreatingInvite: null == isCreatingInvite
          ? _value.isCreatingInvite
          : isCreatingInvite // ignore: cast_nullable_to_non_nullable
              as bool,
      isLeavingHousehold: null == isLeavingHousehold
          ? _value.isLeavingHousehold
          : isLeavingHousehold // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HouseholdStateImplCopyWith<$Res>
    implements $HouseholdStateCopyWith<$Res> {
  factory _$$HouseholdStateImplCopyWith(_$HouseholdStateImpl value,
          $Res Function(_$HouseholdStateImpl) then) =
      __$$HouseholdStateImplCopyWithImpl<$Res>;
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
class __$$HouseholdStateImplCopyWithImpl<$Res>
    extends _$HouseholdStateCopyWithImpl<$Res, _$HouseholdStateImpl>
    implements _$$HouseholdStateImplCopyWith<$Res> {
  __$$HouseholdStateImplCopyWithImpl(
      _$HouseholdStateImpl _value, $Res Function(_$HouseholdStateImpl) _then)
      : super(_value, _then);

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
    return _then(_$HouseholdStateImpl(
      currentHousehold: freezed == currentHousehold
          ? _value.currentHousehold
          : currentHousehold // ignore: cast_nullable_to_non_nullable
              as HouseholdEntry?,
      members: null == members
          ? _value._members
          : members // ignore: cast_nullable_to_non_nullable
              as List<HouseholdMember>,
      outgoingInvites: null == outgoingInvites
          ? _value._outgoingInvites
          : outgoingInvites // ignore: cast_nullable_to_non_nullable
              as List<HouseholdInvite>,
      incomingInvites: null == incomingInvites
          ? _value._incomingInvites
          : incomingInvites // ignore: cast_nullable_to_non_nullable
              as List<HouseholdInvite>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isCreatingInvite: null == isCreatingInvite
          ? _value.isCreatingInvite
          : isCreatingInvite // ignore: cast_nullable_to_non_nullable
              as bool,
      isLeavingHousehold: null == isLeavingHousehold
          ? _value.isLeavingHousehold
          : isLeavingHousehold // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$HouseholdStateImpl extends _HouseholdState {
  const _$HouseholdStateImpl(
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

  @override
  String toString() {
    return 'HouseholdState(currentHousehold: $currentHousehold, members: $members, outgoingInvites: $outgoingInvites, incomingInvites: $incomingInvites, isLoading: $isLoading, error: $error, isCreatingInvite: $isCreatingInvite, isLeavingHousehold: $isLeavingHousehold)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HouseholdStateImpl &&
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

  /// Create a copy of HouseholdState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HouseholdStateImplCopyWith<_$HouseholdStateImpl> get copyWith =>
      __$$HouseholdStateImplCopyWithImpl<_$HouseholdStateImpl>(
          this, _$identity);
}

abstract class _HouseholdState extends HouseholdState {
  const factory _HouseholdState(
      {final HouseholdEntry? currentHousehold,
      final List<HouseholdMember> members,
      final List<HouseholdInvite> outgoingInvites,
      final List<HouseholdInvite> incomingInvites,
      final bool isLoading,
      final String? error,
      final bool isCreatingInvite,
      final bool isLeavingHousehold}) = _$HouseholdStateImpl;
  const _HouseholdState._() : super._();

  @override
  HouseholdEntry? get currentHousehold;
  @override
  List<HouseholdMember> get members;
  @override
  List<HouseholdInvite> get outgoingInvites;
  @override
  List<HouseholdInvite> get incomingInvites;
  @override
  bool get isLoading;
  @override
  String? get error;
  @override
  bool get isCreatingInvite;
  @override
  bool get isLeavingHousehold;

  /// Create a copy of HouseholdState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HouseholdStateImplCopyWith<_$HouseholdStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
