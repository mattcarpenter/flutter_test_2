// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthState {
  User? get currentUser;
  bool get isLoading;
  bool get isSigningIn;
  bool get isSigningUp;
  bool get isSigningInWithGoogle;
  bool get isSigningInWithApple;
  bool get isSigningOut;
  bool get isResettingPassword;
  String? get error;
  String? get successMessage;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AuthStateCopyWith<AuthState> get copyWith =>
      _$AuthStateCopyWithImpl<AuthState>(this as AuthState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AuthState &&
            (identical(other.currentUser, currentUser) ||
                other.currentUser == currentUser) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isSigningIn, isSigningIn) ||
                other.isSigningIn == isSigningIn) &&
            (identical(other.isSigningUp, isSigningUp) ||
                other.isSigningUp == isSigningUp) &&
            (identical(other.isSigningInWithGoogle, isSigningInWithGoogle) ||
                other.isSigningInWithGoogle == isSigningInWithGoogle) &&
            (identical(other.isSigningInWithApple, isSigningInWithApple) ||
                other.isSigningInWithApple == isSigningInWithApple) &&
            (identical(other.isSigningOut, isSigningOut) ||
                other.isSigningOut == isSigningOut) &&
            (identical(other.isResettingPassword, isResettingPassword) ||
                other.isResettingPassword == isResettingPassword) &&
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
      isSigningInWithGoogle,
      isSigningInWithApple,
      isSigningOut,
      isResettingPassword,
      error,
      successMessage);

  @override
  String toString() {
    return 'AuthState(currentUser: $currentUser, isLoading: $isLoading, isSigningIn: $isSigningIn, isSigningUp: $isSigningUp, isSigningInWithGoogle: $isSigningInWithGoogle, isSigningInWithApple: $isSigningInWithApple, isSigningOut: $isSigningOut, isResettingPassword: $isResettingPassword, error: $error, successMessage: $successMessage)';
  }
}

/// @nodoc
abstract mixin class $AuthStateCopyWith<$Res> {
  factory $AuthStateCopyWith(AuthState value, $Res Function(AuthState) _then) =
      _$AuthStateCopyWithImpl;
  @useResult
  $Res call(
      {User? currentUser,
      bool isLoading,
      bool isSigningIn,
      bool isSigningUp,
      bool isSigningInWithGoogle,
      bool isSigningInWithApple,
      bool isSigningOut,
      bool isResettingPassword,
      String? error,
      String? successMessage});
}

/// @nodoc
class _$AuthStateCopyWithImpl<$Res> implements $AuthStateCopyWith<$Res> {
  _$AuthStateCopyWithImpl(this._self, this._then);

  final AuthState _self;
  final $Res Function(AuthState) _then;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentUser = freezed,
    Object? isLoading = null,
    Object? isSigningIn = null,
    Object? isSigningUp = null,
    Object? isSigningInWithGoogle = null,
    Object? isSigningInWithApple = null,
    Object? isSigningOut = null,
    Object? isResettingPassword = null,
    Object? error = freezed,
    Object? successMessage = freezed,
  }) {
    return _then(_self.copyWith(
      currentUser: freezed == currentUser
          ? _self.currentUser
          : currentUser // ignore: cast_nullable_to_non_nullable
              as User?,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isSigningIn: null == isSigningIn
          ? _self.isSigningIn
          : isSigningIn // ignore: cast_nullable_to_non_nullable
              as bool,
      isSigningUp: null == isSigningUp
          ? _self.isSigningUp
          : isSigningUp // ignore: cast_nullable_to_non_nullable
              as bool,
      isSigningInWithGoogle: null == isSigningInWithGoogle
          ? _self.isSigningInWithGoogle
          : isSigningInWithGoogle // ignore: cast_nullable_to_non_nullable
              as bool,
      isSigningInWithApple: null == isSigningInWithApple
          ? _self.isSigningInWithApple
          : isSigningInWithApple // ignore: cast_nullable_to_non_nullable
              as bool,
      isSigningOut: null == isSigningOut
          ? _self.isSigningOut
          : isSigningOut // ignore: cast_nullable_to_non_nullable
              as bool,
      isResettingPassword: null == isResettingPassword
          ? _self.isResettingPassword
          : isResettingPassword // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      successMessage: freezed == successMessage
          ? _self.successMessage
          : successMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _AuthState extends AuthState {
  const _AuthState(
      {this.currentUser,
      this.isLoading = false,
      this.isSigningIn = false,
      this.isSigningUp = false,
      this.isSigningInWithGoogle = false,
      this.isSigningInWithApple = false,
      this.isSigningOut = false,
      this.isResettingPassword = false,
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
  final bool isSigningInWithGoogle;
  @override
  @JsonKey()
  final bool isSigningInWithApple;
  @override
  @JsonKey()
  final bool isSigningOut;
  @override
  @JsonKey()
  final bool isResettingPassword;
  @override
  final String? error;
  @override
  final String? successMessage;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AuthStateCopyWith<_AuthState> get copyWith =>
      __$AuthStateCopyWithImpl<_AuthState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AuthState &&
            (identical(other.currentUser, currentUser) ||
                other.currentUser == currentUser) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isSigningIn, isSigningIn) ||
                other.isSigningIn == isSigningIn) &&
            (identical(other.isSigningUp, isSigningUp) ||
                other.isSigningUp == isSigningUp) &&
            (identical(other.isSigningInWithGoogle, isSigningInWithGoogle) ||
                other.isSigningInWithGoogle == isSigningInWithGoogle) &&
            (identical(other.isSigningInWithApple, isSigningInWithApple) ||
                other.isSigningInWithApple == isSigningInWithApple) &&
            (identical(other.isSigningOut, isSigningOut) ||
                other.isSigningOut == isSigningOut) &&
            (identical(other.isResettingPassword, isResettingPassword) ||
                other.isResettingPassword == isResettingPassword) &&
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
      isSigningInWithGoogle,
      isSigningInWithApple,
      isSigningOut,
      isResettingPassword,
      error,
      successMessage);

  @override
  String toString() {
    return 'AuthState(currentUser: $currentUser, isLoading: $isLoading, isSigningIn: $isSigningIn, isSigningUp: $isSigningUp, isSigningInWithGoogle: $isSigningInWithGoogle, isSigningInWithApple: $isSigningInWithApple, isSigningOut: $isSigningOut, isResettingPassword: $isResettingPassword, error: $error, successMessage: $successMessage)';
  }
}

/// @nodoc
abstract mixin class _$AuthStateCopyWith<$Res>
    implements $AuthStateCopyWith<$Res> {
  factory _$AuthStateCopyWith(
          _AuthState value, $Res Function(_AuthState) _then) =
      __$AuthStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {User? currentUser,
      bool isLoading,
      bool isSigningIn,
      bool isSigningUp,
      bool isSigningInWithGoogle,
      bool isSigningInWithApple,
      bool isSigningOut,
      bool isResettingPassword,
      String? error,
      String? successMessage});
}

/// @nodoc
class __$AuthStateCopyWithImpl<$Res> implements _$AuthStateCopyWith<$Res> {
  __$AuthStateCopyWithImpl(this._self, this._then);

  final _AuthState _self;
  final $Res Function(_AuthState) _then;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? currentUser = freezed,
    Object? isLoading = null,
    Object? isSigningIn = null,
    Object? isSigningUp = null,
    Object? isSigningInWithGoogle = null,
    Object? isSigningInWithApple = null,
    Object? isSigningOut = null,
    Object? isResettingPassword = null,
    Object? error = freezed,
    Object? successMessage = freezed,
  }) {
    return _then(_AuthState(
      currentUser: freezed == currentUser
          ? _self.currentUser
          : currentUser // ignore: cast_nullable_to_non_nullable
              as User?,
      isLoading: null == isLoading
          ? _self.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isSigningIn: null == isSigningIn
          ? _self.isSigningIn
          : isSigningIn // ignore: cast_nullable_to_non_nullable
              as bool,
      isSigningUp: null == isSigningUp
          ? _self.isSigningUp
          : isSigningUp // ignore: cast_nullable_to_non_nullable
              as bool,
      isSigningInWithGoogle: null == isSigningInWithGoogle
          ? _self.isSigningInWithGoogle
          : isSigningInWithGoogle // ignore: cast_nullable_to_non_nullable
              as bool,
      isSigningInWithApple: null == isSigningInWithApple
          ? _self.isSigningInWithApple
          : isSigningInWithApple // ignore: cast_nullable_to_non_nullable
              as bool,
      isSigningOut: null == isSigningOut
          ? _self.isSigningOut
          : isSigningOut // ignore: cast_nullable_to_non_nullable
              as bool,
      isResettingPassword: null == isResettingPassword
          ? _self.isResettingPassword
          : isResettingPassword // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      successMessage: freezed == successMessage
          ? _self.successMessage
          : successMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
