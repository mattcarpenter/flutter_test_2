import 'dart:async';
import 'dart:convert';
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
  
  // Google Sign-In v7.x approach - use instance and initialize
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isInitialized = false;
  
  // Debug counter to track multiple calls
  static int _signInCallCount = 0;

  AuthService() : _supabase = Supabase.instance.client;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _googleSignIn.initialize(
        // iOS Client ID from Info.plist (for iOS authentication)
        clientId: '954511479486-avfjhihhekild9n04jrre8dafv21q161.apps.googleusercontent.com',
        // Web Client ID (this should be the ONLY one in Supabase dashboard)
        serverClientId: '954511479486-tqc04eefqqk06usqkcic4sct2v9u8eko.apps.googleusercontent.com',
      );
      _isInitialized = true;
      debugPrint('🔧 GoogleSignIn initialized with client IDs');
    }
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

  /// Sign in with Google using native authentication (v7.x compatible with Supabase)
  Future<AuthResponse> signInWithGoogle() async {
    try {
      _signInCallCount++;
      debugPrint('🔥 GOOGLE SIGN-IN CALLED #$_signInCallCount');
      
      await _ensureInitialized();
      
      debugPrint('Google Sign-In: Starting v7.x compatible flow');

      // Try lightweight authentication first (no UI if already signed in)
      debugPrint('🚀 Attempting lightweight authentication...');
      await _googleSignIn.attemptLightweightAuthentication();
      
      // Now authenticate (this should minimize consent screens)
      debugPrint('🚀 About to call authenticate()...');
      final googleUser = await _googleSignIn.authenticate();
      
      debugPrint('✅ authenticate() completed, user: ${googleUser.displayName}');

      debugPrint('Google Sign-In: User signed in, getting tokens');

      // Get Google authentication tokens - but v7.x has different token access
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      
      debugPrint('🔍 Got authentication object');
      debugPrint('   Has idToken: ${idToken != null}');
      
      // In v7.x, we need to get accessToken differently
      String? accessToken;
      try {
        // Try to use the authorization client for access token
        final authClient = googleUser.authorizationClient;
        final authorization = await authClient.authorizationForScopes(['openid', 'email', 'profile']);
        
        if (authorization != null) {
          accessToken = authorization.accessToken;
          debugPrint('   Got access token from existing authorization');
        } else {
          // Need to authorize scopes
          debugPrint('   No existing authorization, requesting scopes...');
          final newAuth = await authClient.authorizeScopes(['openid', 'email', 'profile']);
          accessToken = newAuth.accessToken;
          debugPrint('   Got access token from new authorization');
        }
      } catch (e) {
        debugPrint('   Error getting access token: $e');
        throw AuthApiException(
          message: 'Failed to get access token: $e',
          type: AuthErrorType.unknown,
        );
      }
      
      debugPrint('🔍 Final token check:');
      debugPrint('   Has accessToken: ${accessToken != null}');
      debugPrint('   Has idToken: ${idToken != null}');

      if (accessToken == null || accessToken.isEmpty) {
        throw AuthApiException(
          message: 'No Access Token found',
          type: AuthErrorType.unknown,
        );
      }
      if (idToken == null) {
        throw AuthApiException(
          message: 'No ID Token found',
          type: AuthErrorType.unknown,
        );
      }

      debugPrint('Google Sign-In: Got tokens, attempting Supabase authentication');
      
      // DEBUG: Let's decode the ID token to see what's actually in it
      debugPrint('=== TOKEN DEBUG INFO ===');
      debugPrint('Access Token (first 50 chars): ${accessToken.substring(0, 50)}...');
      debugPrint('ID Token (first 50 chars): ${idToken.substring(0, 50)}...');
      
      // Decode the ID token payload to see the audience
      try {
        final parts = idToken.split('.');
        if (parts.length == 3) {
          // Decode the payload (middle part)
          String payload = parts[1];
          // Add padding if needed
          while (payload.length % 4 != 0) {
            payload += '=';
          }
          final decoded = utf8.decode(base64Url.decode(payload));
          debugPrint('ID Token Payload: $decoded');
        }
      } catch (e) {
        debugPrint('Failed to decode token: $e');
      }
      debugPrint('=== END TOKEN DEBUG ===');

      // Exchange tokens with Supabase using exact documented approach
      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } on AuthException catch (e) {
      debugPrint('Google sign in error: ${e.message}');
      throw AuthApiException.fromAuthException(e);
    } catch (e) {
      debugPrint('Google sign in error: $e');
      if (e is AuthApiException) {
        rethrow;
      }
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
