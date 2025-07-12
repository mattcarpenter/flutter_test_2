import 'dart:async';

import 'package:flutter/foundation.dart';
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
      state = state.copyWith(
        currentUser: currentUser,
        isLoading: false,
      );
    }

    // Listen to auth state changes
    _authSubscription = _authService.authStateChangesWithSession.listen((authState) {
      debugPrint('Auth state changed: ${authState.event}');
      
      switch (authState.event) {
        case AuthChangeEvent.signedIn:
          if (authState.session?.user != null) {
            state = state.copyWith(
              currentUser: authState.session!.user,
              isLoading: false,
              isSigningIn: false,
              isSigningUp: false,
              error: null,
              successMessage: 'Successfully signed in!',
            );
          }
          break;
          
        case AuthChangeEvent.signedOut:
          state = const models.AuthState();
          break;
          
        case AuthChangeEvent.userUpdated:
          if (authState.session?.user != null) {
            state = state.copyWith(
              currentUser: authState.session!.user,
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

      // Check if email verification is needed
      if (response.user != null && response.session == null) {
        state = state.copyWith(
          isSigningUp: false,
          needsEmailVerification: true,
          successMessage: 'Please check your email to verify your account.',
        );
      } else {
        // User is signed up and signed in
        state = state.copyWith(
          isSigningUp: false,
          currentUser: response.user,
        );
      }
    } catch (e) {
      final errorMessage = AuthService.getErrorMessage(e as Exception);
      state = state.copyWith(
        isSigningUp: false,
        error: errorMessage,
      );
      rethrow;
    }
  }

  /// Sign in with Google using native authentication
  Future<void> signInWithGoogle() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      successMessage: null,
    );

    try {
      final response = await _authService.signInWithGoogle();
      // State will be updated via auth stream listener, but also update here for immediate response
      state = state.copyWith(
        isLoading: false,
        currentUser: response.user,
        successMessage: 'Successfully signed in with Google!',
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

  /// Sign in with Apple (iOS only)
  Future<void> signInWithApple() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      successMessage: null,
    );

    try {
      final response = await _authService.signInWithApple();
      state = state.copyWith(
        isLoading: false,
        currentUser: response.user,
        successMessage: 'Successfully signed in with Apple!',
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

  /// Resend email verification
  Future<void> resendEmailVerification(String email) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      successMessage: null,
    );

    try {
      await _authService.resendEmailVerification(email);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Verification email sent! Check your inbox.',
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

  /// Clear email verification flag
  void clearEmailVerification() {
    state = state.copyWith(needsEmailVerification: false);
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
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isAuthenticated;
});

// Main auth state provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, models.AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  
  return AuthNotifier(
    authService: authService,
    ref: ref,
  );
});