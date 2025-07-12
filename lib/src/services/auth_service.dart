import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/models/auth_error.dart';

class AuthApiException implements Exception {
  final String message;
  final String? code;
  final AuthErrorType type;

  AuthApiException({
    required this.message,
    this.code,
    required this.type,
  });

  factory AuthApiException.fromAuthException(AuthException authException) {
    return AuthApiException(
      message: authException.message,
      code: authException.statusCode,
      type: _mapAuthExceptionToType(authException),
    );
  }

  factory AuthApiException.fromException(Exception exception) {
    final authError = AuthError.fromException(exception);
    return AuthApiException(
      message: authError.message,
      code: authError.code,
      type: authError.type,
    );
  }

  static AuthErrorType _mapAuthExceptionToType(AuthException authException) {
    final message = authException.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return AuthErrorType.invalidCredentials;
    } else if (message.contains('email not confirmed')) {
      return AuthErrorType.emailNotVerified;
    } else if (message.contains('user already registered')) {
      return AuthErrorType.userAlreadyExists;
    } else if (message.contains('password should be at least')) {
      return AuthErrorType.weakPassword;
    } else if (message.contains('unable to validate email')) {
      return AuthErrorType.invalidEmail;
    } else if (message.contains('rate limit')) {
      return AuthErrorType.rateLimited;
    }

    return AuthErrorType.unknown;
  }

  @override
  String toString() => 'AuthApiException: $message';
}

class AuthService {
  final SupabaseClient _supabase;
  late final GoogleSignIn _googleSignIn;

  AuthService() : _supabase = Supabase.instance.client {
    _googleSignIn = GoogleSignIn(
      // TODO: Replace with your actual web client ID from Google Cloud Console
    serverClientId: '954511479486-avfjhihhekild9n04jrre8dafv21q161.apps.googleusercontent.com',
      scopes: ['openid', 'email', 'profile'],
    );
  }

  /// Stream of auth state changes
  Stream<AuthChangeEvent> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) => data.event);
  }

  /// Stream of auth state changes with session data
  Stream<AuthState> get authStateChangesWithSession {
    return _supabase.auth.onAuthStateChange;
  }

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: _getRedirectUrl(),
        data: metadata,
      );

      if (response.user == null && response.session == null) {
        throw AuthApiException(
          message: 'Sign up failed: No user or session returned',
          type: AuthErrorType.unknown,
        );
      }

      return response;
    } on AuthException catch (e) {
      debugPrint('Auth sign up error: ${e.message}');
      throw AuthApiException.fromAuthException(e);
    } catch (e) {
      debugPrint('Sign up error: $e');
      throw AuthApiException.fromException(Exception(e.toString()));
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null || response.session == null) {
        throw AuthApiException(
          message: 'Sign in failed: Invalid credentials',
          type: AuthErrorType.invalidCredentials,
        );
      }

      return response;
    } on AuthException catch (e) {
      debugPrint('Auth sign in error: ${e.message}');
      throw AuthApiException.fromAuthException(e);
    } catch (e) {
      debugPrint('Sign in error: $e');
      throw AuthApiException.fromException(Exception(e.toString()));
    }
  }

  /// Sign in with Google using native authentication
  Future<AuthResponse> signInWithGoogle() async {
    try {
      // Sign out from any previous session
      await _googleSignIn.signOut();

      // Start the Google Sign-In flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthApiException(
          message: 'Google Sign-In was cancelled',
          type: AuthErrorType.userCancelled,
        );
      }

      // Get Google authentication
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw AuthApiException(
          message: 'Failed to get Google authentication tokens',
          type: AuthErrorType.unknown,
        );
      }

      // Exchange tokens with Supabase (requires "Skip nonce check" enabled in Supabase Dashboard)
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null || response.session == null) {
        throw AuthApiException(
          message: 'Failed to authenticate with Supabase',
          type: AuthErrorType.unknown,
        );
      }

      return response;
    } on AuthException catch (e) {
      debugPrint('Google sign in error: ${e.message}');
      throw AuthApiException.fromAuthException(e);
    } catch (e) {
      debugPrint('Google sign in error: $e');
      throw AuthApiException.fromException(Exception(e.toString()));
    }
  }

  /// Sign in with Apple (iOS only)
  Future<AuthResponse> signInWithApple() async {
    try {
      // Check if Apple Sign-In is available
      if (!await SignInWithApple.isAvailable()) {
        throw AuthApiException(
          message: 'Apple Sign-In is not available on this device',
          type: AuthErrorType.notSupported,
        );
      }

      // Start the Apple Sign-In flow
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw AuthApiException(
          message: 'Failed to get Apple authentication token',
          type: AuthErrorType.unknown,
        );
      }

      // Exchange tokens with Supabase
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );

      if (response.user == null || response.session == null) {
        throw AuthApiException(
          message: 'Failed to authenticate with Supabase',
          type: AuthErrorType.unknown,
        );
      }

      return response;
    } on AuthException catch (e) {
      debugPrint('Apple sign in error: ${e.message}');
      throw AuthApiException.fromAuthException(e);
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      throw AuthApiException.fromException(Exception(e.toString()));
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: _getPasswordResetUrl(),
      );
    } on AuthException catch (e) {
      debugPrint('Password reset error: ${e.message}');
      throw AuthApiException.fromAuthException(e);
    } catch (e) {
      debugPrint('Password reset error: $e');
      throw AuthApiException.fromException(Exception(e.toString()));
    }
  }

  /// Resend email verification
  Future<void> resendEmailVerification(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: _getRedirectUrl(),
      );
    } on AuthException catch (e) {
      debugPrint('Resend verification error: ${e.message}');
      throw AuthApiException.fromAuthException(e);
    } catch (e) {
      debugPrint('Resend verification error: $e');
      throw AuthApiException.fromException(Exception(e.toString()));
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      debugPrint('Sign out error: ${e.message}');
      throw AuthApiException.fromAuthException(e);
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw AuthApiException.fromException(Exception(e.toString()));
    }
  }

  /// Update user metadata
  Future<UserResponse> updateUserMetadata(Map<String, dynamic> metadata) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(data: metadata),
      );

      if (response.user == null) {
        throw AuthApiException(
          message: 'Failed to update user metadata',
          type: AuthErrorType.unknown,
        );
      }

      return response;
    } on AuthException catch (e) {
      debugPrint('Update metadata error: ${e.message}');
      throw AuthApiException.fromAuthException(e);
    } catch (e) {
      debugPrint('Update metadata error: $e');
      throw AuthApiException.fromException(Exception(e.toString()));
    }
  }

  /// Get platform-specific redirect URL
  String _getRedirectUrl() {
    if (kIsWeb) {
      return '${Uri.base.origin}/auth/callback';
    } else if (Platform.isIOS || Platform.isAndroid) {
      return 'io.supabase.flutterrecipeapp://login-callback/';
    } else {
      // Desktop
      return 'http://localhost:3000/auth/callback';
    }
  }

  /// Get platform-specific password reset URL
  String _getPasswordResetUrl() {
    if (kIsWeb) {
      return '${Uri.base.origin}/auth/reset-password';
    } else if (Platform.isIOS || Platform.isAndroid) {
      return 'io.supabase.flutterrecipeapp://reset-callback/';
    } else {
      // Desktop
      return 'http://localhost:3000/auth/reset-password';
    }
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate password strength
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Get user-friendly error message
  static String getErrorMessage(Exception exception) {
    if (exception is AuthApiException) {
      final authError = AuthError(
        message: exception.message,
        code: exception.code,
        type: exception.type,
      );
      return authError.displayMessage;
    }

    return AuthError.fromException(exception).displayMessage;
  }
}
