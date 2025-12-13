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
    /// The OAuth provider for a pending linkIdentity operation.
    /// Used to retry with native OAuth if linkIdentity fails with identity_already_exists.
    OAuthProvider? pendingLinkIdentityProvider,
    /// True when linkIdentity fails because the identity is already linked to another account.
    /// The UI should show a dialog offering to sign in to the existing account.
    @Default(false) bool identityAlreadyExistsError,
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
