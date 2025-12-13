import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_state.freezed.dart';

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    User? currentUser,
    @Default(false) bool isLoading,
    @Default(false) bool isSigningIn,
    @Default(false) bool isSigningUp,
    @Default(false) bool isSigningInWithGoogle,
    @Default(false) bool isSigningInWithApple,
    @Default(false) bool isSigningOut,
    @Default(false) bool isResettingPassword,
    /// True if the current user is an anonymous Supabase user (no linked identity)
    @Default(false) bool isAnonymous,
    /// True if user should be prompted to restore purchases after signing in
    @Default(false) bool shouldPromptRestore,
    String? error,
    String? successMessage,
  }) = _AuthState;

  const AuthState._();

  /// True if user has any Supabase session (including anonymous)
  bool get isAuthenticated => currentUser != null;

  /// True only if user has a real account (not anonymous)
  bool get isEffectivelyAuthenticated => currentUser != null && !isAnonymous;

  bool get hasError => error != null;
  bool get hasSuccess => successMessage != null;
  bool get isPerformingAction =>
      isSigningIn ||
      isSigningUp ||
      isSigningInWithGoogle ||
      isSigningInWithApple ||
      isSigningOut ||
      isResettingPassword;
}
