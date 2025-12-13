import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/models/auth_state.dart' as models;
import '../services/auth_service.dart';

class AuthNotifier extends StateNotifier<models.AuthState> {
  final AuthService _authService;
  
  late final StreamSubscription _authSubscription;

  AuthNotifier({
    required AuthService authService,
    required Ref ref,
  })  : _authService = authService,
        super(const models.AuthState()) {
    _initializeAuthState();
  }

  void _initializeAuthState() {
    // Set initial state based on current auth status
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final isAnon = AuthService.isUserAnonymous(currentUser);
      state = state.copyWith(
        currentUser: currentUser,
        isAnonymous: isAnon,
        isLoading: false,
      );
    }

    // Listen to auth state changes
    _authSubscription = _authService.authStateChangesWithSession.listen((authState) {
      switch (authState.event) {
        case AuthChangeEvent.signedIn:
          if (authState.session?.user != null) {
            final user = authState.session!.user;
            final isAnon = AuthService.isUserAnonymous(user);
            state = state.copyWith(
              currentUser: user,
              isAnonymous: isAnon,
              isLoading: false,
              isSigningIn: false,
              isSigningUp: false,
              error: null,
              successMessage: isAnon ? null : 'Successfully signed in!',
            );
          }
          break;

        case AuthChangeEvent.signedOut:
          state = const models.AuthState();
          break;

        case AuthChangeEvent.userUpdated:
          if (authState.session?.user != null) {
            final user = authState.session!.user;
            final isAnon = AuthService.isUserAnonymous(user);
            state = state.copyWith(
              currentUser: user,
              isAnonymous: isAnon,
              error: null,
            );
          }
          break;

        case AuthChangeEvent.passwordRecovery:
          state = state.copyWith(
            isResettingPassword: false,
            error: null,
            successMessage: 'Password reset email sent! Check your inbox.',
          );
          break;

        default:
          break;
      }
    });
  }

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(
      isSigningIn: true,
      error: null,
      successMessage: null,
    );

    try {
      await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      // State will be updated via auth stream listener
    } catch (e) {
      final errorMessage = AuthService.getErrorMessage(e as Exception);
      state = state.copyWith(
        isSigningIn: false,
        error: errorMessage,
      );
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail(
    String email,
    String password, {
    Map<String, dynamic>? metadata,
  }) async {
    state = state.copyWith(
      isSigningUp: true,
      error: null,
      successMessage: null,
    );

    try {
      final response = await _authService.signUpWithEmail(
        email: email,
        password: password,
        metadata: metadata,
      );

      // User is signed up and signed in (no email verification needed)
      state = state.copyWith(
        isSigningUp: false,
        currentUser: response.user,
      );
    } catch (e) {
      final errorMessage = AuthService.getErrorMessage(e as Exception);
      state = state.copyWith(
        isSigningUp: false,
        error: errorMessage,
      );
      rethrow;
    }
  }

  /// Sign in with Google using native authentication.
  /// For anonymous users, uses PKCE linkIdentity to upgrade the account.
  ///
  /// Set [forceNativeOAuth] to true to skip the anonymous upgrade check and use
  /// native OAuth directly. This is used on the sign-in page when linkIdentity
  /// fails because the identity is already linked to another account.
  Future<void> signInWithGoogle({bool forceNativeOAuth = false}) async {
    state = state.copyWith(
      isSigningInWithGoogle: true,
      error: null,
      successMessage: null,
    );

    try {
      final response = await _authService.signInWithGoogle(
        forceNativeOAuth: forceNativeOAuth,
      );
      // State will be updated via auth stream listener, but also update here for immediate response
      state = state.copyWith(
        isSigningInWithGoogle: false,
        currentUser: response.user,
        successMessage: 'Successfully signed in with Google!',
      );
    } catch (e) {
      final errorMessage = AuthService.getErrorMessage(e as Exception);
      state = state.copyWith(
        isSigningInWithGoogle: false,
        error: errorMessage,
      );
      rethrow;
    }
  }

  /// Sign in with Apple (iOS only).
  /// For anonymous users, uses PKCE linkIdentity to upgrade the account.
  ///
  /// Set [forceNativeOAuth] to true to skip the anonymous upgrade check and use
  /// native OAuth directly. This is used on the sign-in page when linkIdentity
  /// fails because the identity is already linked to another account.
  Future<void> signInWithApple({bool forceNativeOAuth = false}) async {
    state = state.copyWith(
      isSigningInWithApple: true,
      error: null,
      successMessage: null,
    );

    try {
      final response = await _authService.signInWithApple(
        forceNativeOAuth: forceNativeOAuth,
      );
      state = state.copyWith(
        isSigningInWithApple: false,
        currentUser: response.user,
        successMessage: 'Successfully signed in with Apple!',
      );
    } catch (e) {
      final errorMessage = AuthService.getErrorMessage(e as Exception);
      state = state.copyWith(
        isSigningInWithApple: false,
        error: errorMessage,
      );
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    state = state.copyWith(
      isResettingPassword: true,
      error: null,
      successMessage: null,
    );

    try {
      await _authService.resetPassword(email);
      state = state.copyWith(
        isResettingPassword: false,
        successMessage: 'Password reset email sent! Check your inbox.',
      );
    } catch (e) {
      final errorMessage = AuthService.getErrorMessage(e as Exception);
      state = state.copyWith(
        isResettingPassword: false,
        error: errorMessage,
      );
      rethrow;
    }
  }


  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(
      isSigningOut: true,
      error: null,
      successMessage: null,
    );

    try {
      await _authService.signOut();
      // State will be updated via auth stream listener
    } catch (e) {
      final errorMessage = AuthService.getErrorMessage(e as Exception);
      state = state.copyWith(
        isSigningOut: false,
        error: errorMessage,
      );
      rethrow;
    }
  }

  /// Update user metadata
  Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      successMessage: null,
    );

    try {
      await _authService.updateUserMetadata(metadata);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Profile updated successfully!',
      );
    } catch (e) {
      final errorMessage = AuthService.getErrorMessage(e as Exception);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      rethrow;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear success message
  void clearSuccess() {
    state = state.copyWith(successMessage: null);
  }

  /// Clear the restore prompt flag
  void clearRestorePrompt() {
    state = state.copyWith(shouldPromptRestore: false);
  }


  /// Set the restore prompt flag (called when anonymous user with subscription signs in)
  void setShouldPromptRestore(bool value) {
    state = state.copyWith(shouldPromptRestore: value);
  }


  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider for current user (convenience provider)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.currentUser;
});

// Provider for authentication status (convenience provider)
// NOTE: This now maps to isEffectivelyAuthenticated for backwards compatibility
// Anonymous users will appear as "not authenticated" in UI contexts
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isEffectivelyAuthenticated;
});

/// True if user has ANY Supabase session (including anonymous)
/// Use this for system-level checks (PowerSync, RevenueCat, etc.)
final isSystemAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isAuthenticated;
});

/// True only if user has a real account (not anonymous)
/// Use this for UI display and feature gating
final isEffectivelyAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isEffectivelyAuthenticated;
});

/// Check if current session is anonymous
final isAnonymousUserProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isAnonymous;
});

/// Check if user should be prompted to restore purchases
final shouldPromptRestoreProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.shouldPromptRestore;
});

// Main auth state provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, models.AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);

  return AuthNotifier(
    authService: authService,
    ref: ref,
  );
});