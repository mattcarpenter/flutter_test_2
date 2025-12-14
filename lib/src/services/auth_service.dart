import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/models/auth_error.dart';
import 'logging/app_logger.dart';

/// Indicates the type of sign-in that was performed
enum SignInMethod {
  /// Native OAuth (ID token exchange) - used for non-anonymous users
  native,
  /// PKCE flow (browser redirect) - used to upgrade anonymous users
  pkce,
}

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
    // Primary: Use HTTP status codes (stable across SDK versions)
    switch (authException.statusCode) {
      case '400':
        // 400 can mean multiple things - use message as secondary filter
        final message = authException.message.toLowerCase();
        if (message.contains('user already registered')) {
          return AuthErrorType.userAlreadyExists;
        } else if (message.contains('password')) {
          return AuthErrorType.weakPassword;
        }
        return AuthErrorType.invalidCredentials;

      case '401':
        return AuthErrorType.sessionExpired;

      case '422':
        return AuthErrorType.invalidEmail;

      case '429':
        return AuthErrorType.rateLimited;

      default:
        // Fallback: Check message for network errors
        final message = authException.message.toLowerCase();
        if (message.contains('network') ||
            message.contains('socket') ||
            message.contains('connection')) {
          return AuthErrorType.network;
        }
        return AuthErrorType.unknown;
    }
  }

  @override
  String toString() => 'AuthApiException: $message';
}

class AuthService {
  final SupabaseClient _supabase;

  // Google Sign-In v7.x approach - use instance and initialize
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isInitialized = false;

  // Deep link monitoring for auth errors
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _deepLinkSubscription;
  final _identityExistsErrorController = StreamController<void>.broadcast();

  /// Stream that emits when an identity_already_exists error is detected from a deep link.
  /// Listen to this to show the "account already exists" dialog.
  Stream<void> get onIdentityAlreadyExistsError => _identityExistsErrorController.stream;

  AuthService() : _supabase = Supabase.instance.client {
    _startDeepLinkMonitoring();
  }

  /// Start monitoring deep links for auth errors.
  /// This runs BEFORE Supabase's internal handler processes the link.
  void _startDeepLinkMonitoring() {
    if (kIsWeb) return; // Web doesn't use deep links

    _deepLinkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _checkForAuthError(uri);
    });
  }

  /// Check if a deep link URL contains an auth error.
  void _checkForAuthError(Uri uri) {
    // Auth callback URLs have error info in the fragment
    // Example: app.stockpot.app://auth-callback#error_code=identity_already_exists&error_description=...
    final fragment = uri.fragment;
    if (fragment.isEmpty) return;

    // Parse the fragment as query parameters
    final params = Uri.splitQueryString(fragment);
    final errorCode = params['error_code'];

    if (errorCode == 'identity_already_exists') {
      AppLogger.info('Detected identity_already_exists error from deep link');
      _identityExistsErrorController.add(null);
    }
  }

  /// Dispose resources. Call this when the service is no longer needed.
  void dispose() {
    _deepLinkSubscription?.cancel();
    _identityExistsErrorController.close();
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _googleSignIn.initialize(
        // iOS Client ID from Info.plist (for iOS authentication)
        clientId: '954511479486-avfjhihhekild9n04jrre8dafv21q161.apps.googleusercontent.com',
        // Web Client ID (this should be the ONLY one in Supabase dashboard)
        serverClientId: '954511479486-tqc04eefqqk06usqkcic4sct2v9u8eko.apps.googleusercontent.com',
      );
      _isInitialized = true;
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
  /// If user is currently anonymous, this upgrades their account by linking email identity
  /// (preserving user ID and any associated subscriptions)
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;

      // Check if current user is anonymous - if so, upgrade their account
      if (currentUser != null && isAnonymousUser) {
        AppLogger.info('Upgrading anonymous user ${currentUser.id} to email account');

        // Link email identity to anonymous account
        // This preserves the user ID, so all subscriptions stay linked
        final response = await _supabase.auth.updateUser(
          UserAttributes(
            email: email,
            password: password,
            data: metadata,
          ),
        );

        if (response.user != null) {
          AppLogger.info('Anonymous user upgraded to email account: ${response.user!.id}');
        }

        // Return an AuthResponse-like structure
        // Note: updateUser returns UserResponse, we need to construct AuthResponse
        return AuthResponse(
          session: _supabase.auth.currentSession,
          user: response.user,
        );
      }

      // Standard sign-up for non-anonymous users
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
      AppLogger.error('Sign up failed', e);
      throw AuthApiException.fromAuthException(e);
    } catch (e) {
      AppLogger.error('Sign up failed', e);
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
      AppLogger.error('Sign in failed', e);
      throw AuthApiException.fromAuthException(e);
    } catch (e) {
      AppLogger.error('Sign in failed', e);
      throw AuthApiException.fromException(Exception(e.toString()));
    }
  }

  /// Sign in with Google using native authentication (v7.x compatible with Supabase)
  /// For anonymous users, uses PKCE linkIdentity to upgrade the account while
  /// preserving user ID and data.
  ///
  /// Set [forceNativeOAuth] to true to skip the anonymous upgrade check and use
  /// native OAuth directly. This is used on the sign-in page when linkIdentity
  /// fails because the identity is already linked to another account.
  Future<AuthResponse> signInWithGoogle({bool forceNativeOAuth = false}) async {
    try {
      // Check if current user is anonymous - use linkIdentity to upgrade
      // (unless forceNativeOAuth is true, which means we want to switch accounts)
      if (!forceNativeOAuth && isAnonymousUser) {
        AppLogger.info('Anonymous user detected, upgrading with Google identity');
        await _linkIdentity(OAuthProvider.google);
        // linkIdentity launches Safari and returns immediately
        // Return current session - auth state listener will update when complete
        return AuthResponse(session: currentSession, user: currentUser);
      }

      // Non-anonymous user (or forced): use native OAuth
      await _ensureInitialized();

      // Try lightweight authentication first (no UI if already signed in)
      await _googleSignIn.attemptLightweightAuthentication();

      // Authenticate with Google
      final googleUser = await _googleSignIn.authenticate();

      // Get Google authentication tokens
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      // In v7.x, we need to get accessToken via authorization client
      String? accessToken;
      try {
        final authClient = googleUser.authorizationClient;
        final authorization = await authClient.authorizationForScopes(['openid', 'email', 'profile']);

        if (authorization != null) {
          accessToken = authorization.accessToken;
        } else {
          final newAuth = await authClient.authorizeScopes(['openid', 'email', 'profile']);
          accessToken = newAuth.accessToken;
        }
      } catch (e) {
        AppLogger.error('Failed to get Google access token', e);
        throw AuthApiException(
          message: 'Failed to get access token',
          type: AuthErrorType.unknown,
        );
      }

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

      // Exchange tokens with Supabase
      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } on AuthException catch (e) {
      AppLogger.error('Google sign in failed', e);
      throw AuthApiException.fromAuthException(e);
    } catch (e) {
      if (e is AuthApiException) {
        rethrow;
      }
      AppLogger.error('Google sign in failed', e);
      throw AuthApiException.fromException(Exception(e.toString()));
    }
  }

  /// Sign in with Apple (iOS only)
  /// Uses native Sign in with Apple with proper nonce for Supabase authentication.
  /// For anonymous users, uses PKCE linkIdentity to upgrade the account while
  /// preserving user ID and data.
  ///
  /// Set [forceNativeOAuth] to true to skip the anonymous upgrade check and use
  /// native OAuth directly. This is used on the sign-in page when linkIdentity
  /// fails because the identity is already linked to another account.
  Future<AuthResponse> signInWithApple({bool forceNativeOAuth = false}) async {
    try {
      // Check if Apple Sign-In is available
      if (!await SignInWithApple.isAvailable()) {
        throw AuthApiException(
          message: 'Apple Sign-In is not available on this device',
          type: AuthErrorType.notSupported,
        );
      }

      // Check if current user is anonymous - use linkIdentity to upgrade
      // (unless forceNativeOAuth is true, which means we want to switch accounts)
      if (!forceNativeOAuth && isAnonymousUser) {
        AppLogger.info('Anonymous user detected, upgrading with Apple identity');
        await _linkIdentity(OAuthProvider.apple);
        // linkIdentity launches Safari and returns immediately
        // Return current session - auth state listener will update when complete
        return AuthResponse(session: currentSession, user: currentUser);
      }

      // Non-anonymous user (or forced): use native OAuth
      // Generate a secure random nonce using Supabase's built-in method
      final rawNonce = _supabase.auth.generateRawNonce();
      // Hash the nonce with SHA-256 for Apple
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      // Start the Apple Sign-In flow with hashed nonce
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw AuthApiException(
          message: 'Failed to get Apple authentication token',
          type: AuthErrorType.unknown,
        );
      }

      // Exchange tokens with Supabase using the RAW nonce (not hashed)
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      if (response.user == null || response.session == null) {
        throw AuthApiException(
          message: 'Failed to authenticate with Supabase',
          type: AuthErrorType.unknown,
        );
      }

      // Apple only provides the user's name on the FIRST sign-in
      // Save it to user metadata if available
      if (credential.givenName != null || credential.familyName != null) {
        final fullName = [credential.givenName, credential.familyName]
            .where((n) => n != null && n.isNotEmpty)
            .join(' ');
        if (fullName.isNotEmpty) {
          try {
            await _supabase.auth.updateUser(
              UserAttributes(data: {'full_name': fullName}),
            );
          } catch (e) {
            // Don't fail the sign-in if metadata update fails
            AppLogger.warning('Failed to save Apple user full name', e);
          }
        }
      }

      return response;
    } on AuthException catch (e) {
      AppLogger.error('Apple sign in failed', e);
      throw AuthApiException.fromAuthException(e);
    } catch (e) {
      if (e is AuthApiException) {
        rethrow;
      }
      // Check if user cancelled
      if (e.toString().contains('canceled') || e.toString().contains('cancelled')) {
        throw AuthApiException(
          message: 'Sign in was cancelled',
          type: AuthErrorType.cancelled,
        );
      }
      AppLogger.error('Apple sign in failed', e);
      throw AuthApiException.fromException(Exception(e.toString()));
    }
  }

  /// Link an OAuth identity to the current anonymous user.
  /// Uses Supabase's built-in linkIdentity() which handles the browser OAuth flow.
  /// The deep link callback is handled automatically by supabase_flutter.
  ///
  /// This method launches Safari and returns immediately - it does NOT wait for
  /// the user to complete the OAuth flow. The auth state listener in AuthNotifier
  /// will handle the success case when the user completes authentication.
  Future<void> _linkIdentity(OAuthProvider provider) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    AppLogger.info('Starting identity linking for ${provider.name} (user: $currentUserId)');

    try {
      // Use Supabase's linkIdentity - handles browser launch and deep link
      // Use externalApplication to open Safari instead of in-app webview
      // This returns after launching Safari, it doesn't wait for completion
      await _supabase.auth.linkIdentity(
        provider,
        redirectTo: _getRedirectUrl(),
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      AppLogger.info('Safari launched for identity linking');
    } on AuthException catch (e) {
      AppLogger.error('Failed to start identity linking', e);
      // Check for "identity already linked" error
      if (e.message.toLowerCase().contains('already') ||
          e.message.toLowerCase().contains('identity') ||
          e.statusCode == '422') {
        throw AuthApiException(
          message: 'This account is already linked to another user',
          code: e.statusCode,
          type: AuthErrorType.identityAlreadyLinked,
        );
      }
      throw AuthApiException.fromAuthException(e);
    } catch (e) {
      if (e is AuthApiException) rethrow;
      AppLogger.error('Failed to start identity linking', e);
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
      AppLogger.error('Password reset failed', e);
      throw AuthApiException.fromAuthException(e);
    } catch (e) {
      AppLogger.error('Password reset failed', e);
      throw AuthApiException.fromException(Exception(e.toString()));
    }
  }

  /// Sign out from both Supabase and RevenueCat
  Future<void> signOut() async {
    try {
      // Sign out from Supabase
      await _supabase.auth.signOut();

      // Also log out from RevenueCat to keep them in sync
      try {
        await Purchases.logOut();
        AppLogger.debug('Logged out from RevenueCat');
      } catch (e) {
        // Don't fail sign out if RevenueCat logout fails
        AppLogger.warning('Failed to log out from RevenueCat', e);
      }
    } on AuthException catch (e) {
      AppLogger.error('Sign out failed', e);
      throw AuthApiException.fromAuthException(e);
    } catch (e) {
      AppLogger.error('Sign out failed', e);
      throw AuthApiException.fromException(Exception(e.toString()));
    }
  }

  /// Create an anonymous Supabase user (for IAP without registration)
  /// Returns the AuthResponse with the anonymous user
  Future<AuthResponse> signInAnonymously() async {
    try {
      final response = await _supabase.auth.signInAnonymously();

      if (response.user == null) {
        throw AuthApiException(
          message: 'Failed to create anonymous user',
          type: AuthErrorType.unknown,
        );
      }

      AppLogger.info('Created anonymous user: ${response.user!.id}');
      return response;
    } on AuthException catch (e) {
      AppLogger.error('Anonymous sign-in failed', e);
      throw AuthApiException.fromAuthException(e);
    } catch (e) {
      if (e is AuthApiException) rethrow;
      AppLogger.error('Anonymous sign-in failed', e);
      throw AuthApiException.fromException(Exception(e.toString()));
    }
  }

  /// Check if current user is anonymous (no linked identity)
  bool get isAnonymousUser {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    // Supabase anonymous users have no identities linked
    // The identities list will be empty or null for anonymous users
    return user.identities?.isEmpty ?? true;
  }

  /// Check if a specific user is anonymous
  static bool isUserAnonymous(User? user) {
    if (user == null) return false;
    return user.identities?.isEmpty ?? true;
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
      AppLogger.error('Update user metadata failed', e);
      throw AuthApiException.fromAuthException(e);
    } catch (e) {
      AppLogger.error('Update user metadata failed', e);
      throw AuthApiException.fromException(Exception(e.toString()));
    }
  }

  /// Get platform-specific redirect URL
  String _getRedirectUrl() {
    if (kIsWeb) {
      return '${Uri.base.origin}/auth/callback';
    } else if (Platform.isIOS || Platform.isAndroid) {
      return 'app.stockpot.app://auth-callback';
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
      return 'app.stockpot.app://reset-callback';
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
