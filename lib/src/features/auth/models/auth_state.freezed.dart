// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AuthState {
  User? get currentUser => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isSigningIn => throw _privateConstructorUsedError;
  bool get isSigningUp => throw _privateConstructorUsedError;
  bool get isSigningOut => throw _privateConstructorUsedError;
  bool get isResettingPassword => throw _privateConstructorUsedError;
  bool get needsEmailVerification => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  String? get successMessage => throw _privateConstructorUsedError;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthStateCopyWith<AuthState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthStateCopyWith<$Res> {
  factory $AuthStateCopyWith(AuthState value, $Res Function(AuthState) then) =
      _$AuthStateCopyWithImpl<$Res, AuthState>;
  @useResult
  $Res call(
      {User? currentUser,
      bool isLoading,
      bool isSigningIn,
      bool isSigningUp,
      bool isSigningOut,
      bool isResettingPassword,
      bool needsEmailVerification,
      String? error,
      String? successMessage});
}

/// @nodoc
class _$AuthStateCopyWithImpl<$Res, $Val extends AuthState>
    implements $AuthStateCopyWith<$Res> {
  _$AuthStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentUser = freezed,
    Object? isLoading = null,
    Object? isSigningIn = null,
    Object? isSigningUp = null,
    Object? isSigningOut = null,
    Object? isResettingPassword = null,
    Object? needsEmailVerification = null,
    Object? error = freezed,
    Object? successMessage = freezed,
  }) {
    return _then(_value.copyWith(
      currentUser: freezed == currentUser
          ? _value.currentUser
          : currentUser // ignore: cast_nullable_to_non_nullable
              as User?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isSigningIn: null == isSigningIn
          ? _value.isSigningIn
          : isSigningIn // ignore: cast_nullable_to_non_nullable
              as bool,
      isSigningUp: null == isSigningUp
          ? _value.isSigningUp
          : isSigningUp // ignore: cast_nullable_to_non_nullable
              as bool,
      isSigningOut: null == isSigningOut
          ? _value.isSigningOut
          : isSigningOut // ignore: cast_nullable_to_non_nullable
              as bool,
      isResettingPassword: null == isResettingPassword
          ? _value.isResettingPassword
          : isResettingPassword // ignore: cast_nullable_to_non_nullable
              as bool,
      needsEmailVerification: null == needsEmailVerification
          ? _value.needsEmailVerification
          : needsEmailVerification // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      successMessage: freezed == successMessage
          ? _value.successMessage
          : successMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AuthStateImplCopyWith<$Res>
    implements $AuthStateCopyWith<$Res> {
  factory _$$AuthStateImplCopyWith(
          _$AuthStateImpl value, $Res Function(_$AuthStateImpl) then) =
      __$$AuthStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {User? currentUser,
      bool isLoading,
      bool isSigningIn,
      bool isSigningUp,
      bool isSigningOut,
      bool isResettingPassword,
      bool needsEmailVerification,
      String? error,
      String? successMessage});
}

/// @nodoc
class __$$AuthStateImplCopyWithImpl<$Res>
    extends _$AuthStateCopyWithImpl<$Res, _$AuthStateImpl>
    implements _$$AuthStateImplCopyWith<$Res> {
  __$$AuthStateImplCopyWithImpl(
      _$AuthStateImpl _value, $Res Function(_$AuthStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentUser = freezed,
    Object? isLoading = null,
    Object? isSigningIn = null,
    Object? isSigningUp = null,
    Object? isSigningOut = null,
    Object? isResettingPassword = null,
    Object? needsEmailVerification = null,
    Object? error = freezed,
    Object? successMessage = freezed,
  }) {
    return _then(_$AuthStateImpl(
      currentUser: freezed == currentUser
          ? _value.currentUser
          : currentUser // ignore: cast_nullable_to_non_nullable
              as User?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isSigningIn: null == isSigningIn
          ? _value.isSigningIn
          : isSigningIn // ignore: cast_nullable_to_non_nullable
              as bool,
      isSigningUp: null == isSigningUp
          ? _value.isSigningUp
          : isSigningUp // ignore: cast_nullable_to_non_nullable
              as bool,
      isSigningOut: null == isSigningOut
          ? _value.isSigningOut
          : isSigningOut // ignore: cast_nullable_to_non_nullable
              as bool,
      isResettingPassword: null == isResettingPassword
          ? _value.isResettingPassword
          : isResettingPassword // ignore: cast_nullable_to_non_nullable
              as bool,
      needsEmailVerification: null == needsEmailVerification
          ? _value.needsEmailVerification
          : needsEmailVerification // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      successMessage: freezed == successMessage
          ? _value.successMessage
          : successMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$AuthStateImpl extends _AuthState {
  const _$AuthStateImpl(
      {this.currentUser,
      this.isLoading = false,
      this.isSigningIn = false,
      this.isSigningUp = false,
      this.isSigningOut = false,
      this.isResettingPassword = false,
      this.needsEmailVerification = false,
      this.error,
      this.successMessage})
      : super._();

  @override
  final User? currentUser;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isSigningIn;
  @override
  @JsonKey()
  final bool isSigningUp;
  @override
  @JsonKey()
  final bool isSigningOut;
  @override
  @JsonKey()
  final bool isResettingPassword;
  @override
  @JsonKey()
  final bool needsEmailVerification;
  @override
  final String? error;
  @override
  final String? successMessage;

  @override
  String toString() {
    return 'AuthState(currentUser: $currentUser, isLoading: $isLoading, isSigningIn: $isSigningIn, isSigningUp: $isSigningUp, isSigningOut: $isSigningOut, isResettingPassword: $isResettingPassword, needsEmailVerification: $needsEmailVerification, error: $error, successMessage: $successMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthStateImpl &&
            (identical(other.currentUser, currentUser) ||
                other.currentUser == currentUser) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isSigningIn, isSigningIn) ||
                other.isSigningIn == isSigningIn) &&
            (identical(other.isSigningUp, isSigningUp) ||
                other.isSigningUp == isSigningUp) &&
            (identical(other.isSigningOut, isSigningOut) ||
                other.isSigningOut == isSigningOut) &&
            (identical(other.isResettingPassword, isResettingPassword) ||
                other.isResettingPassword == isResettingPassword) &&
            (identical(other.needsEmailVerification, needsEmailVerification) ||
                other.needsEmailVerification == needsEmailVerification) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.successMessage, successMessage) ||
                other.successMessage == successMessage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      currentUser,
      isLoading,
      isSigningIn,
      isSigningUp,
      isSigningOut,
      isResettingPassword,
      needsEmailVerification,
      error,
      successMessage);

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthStateImplCopyWith<_$AuthStateImpl> get copyWith =>
      __$$AuthStateImplCopyWithImpl<_$AuthStateImpl>(this, _$identity);
}

abstract class _AuthState extends AuthState {
  const factory _AuthState(
      {final User? currentUser,
      final bool isLoading,
      final bool isSigningIn,
      final bool isSigningUp,
      final bool isSigningOut,
      final bool isResettingPassword,
      final bool needsEmailVerification,
      final String? error,
      final String? successMessage}) = _$AuthStateImpl;
  const _AuthState._() : super._();

  @override
  User? get currentUser;
  @override
  bool get isLoading;
  @override
  bool get isSigningIn;
  @override
  bool get isSigningUp;
  @override
  bool get isSigningOut;
  @override
  bool get isResettingPassword;
  @override
  bool get needsEmailVerification;
  @override
  String? get error;
  @override
  String? get successMessage;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthStateImplCopyWith<_$AuthStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
