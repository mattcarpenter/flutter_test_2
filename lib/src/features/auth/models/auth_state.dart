import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    User? currentUser,
    @Default(false) bool isLoading,
    @Default(false) bool isSigningIn,
    @Default(false) bool isSigningUp,
    @Default(false) bool isSigningOut,
    @Default(false) bool isResettingPassword,
    @Default(false) bool needsEmailVerification,
    String? error,
    String? successMessage,
  }) = _AuthState;

  const AuthState._();

  bool get isAuthenticated => currentUser != null;
  bool get hasError => error != null;
  bool get hasSuccess => successMessage != null;
  bool get isPerformingAction => isSigningIn || isSigningUp || isSigningOut || isResettingPassword;
}