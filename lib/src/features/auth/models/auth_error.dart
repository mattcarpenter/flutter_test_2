import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_error.freezed.dart';

@freezed
class AuthError with _$AuthError {
  const factory AuthError({
    required String message,
    String? code,
    String? details,
    @Default(AuthErrorType.unknown) AuthErrorType type,
  }) = _AuthError;

  const AuthError._();

  factory AuthError.fromException(Exception exception) {
    if (exception.toString().contains('Invalid login credentials')) {
      return const AuthError(
        message: 'Invalid email or password. Please try again.',
        type: AuthErrorType.invalidCredentials,
      );
    } else if (exception.toString().contains('User already registered')) {
      return const AuthError(
        message: 'An account with this email already exists.',
        type: AuthErrorType.userAlreadyExists,
      );
    } else if (exception.toString().contains('Password should be at least')) {
      return const AuthError(
        message: 'Password must be at least 6 characters long.',
        type: AuthErrorType.weakPassword,
      );
    } else if (exception.toString().contains('Unable to validate email address')) {
      return const AuthError(
        message: 'Please enter a valid email address.',
        type: AuthErrorType.invalidEmail,
      );
    } else if (exception.toString().contains('Network')) {
      return const AuthError(
        message: 'Network error. Please check your connection and try again.',
        type: AuthErrorType.network,
      );
    }
    
    return AuthError(
      message: exception.toString(),
      type: AuthErrorType.unknown,
    );
  }

  // User-friendly message for display
  String get displayMessage {
    switch (type) {
      case AuthErrorType.invalidCredentials:
        return 'Invalid email or password. Please try again.';
      case AuthErrorType.userAlreadyExists:
        return 'An account with this email already exists. Try signing in instead.';
      case AuthErrorType.weakPassword:
        return 'Password must be at least 6 characters long.';
      case AuthErrorType.invalidEmail:
        return 'Please enter a valid email address.';
      case AuthErrorType.network:
        return 'Network error. Please check your connection and try again.';
      case AuthErrorType.rateLimited:
        return 'Too many attempts. Please wait a moment before trying again.';
      case AuthErrorType.sessionExpired:
        return 'Your session has expired. Please sign in again.';
      case AuthErrorType.userCancelled:
        return 'Sign-in was cancelled.';
      case AuthErrorType.notSupported:
        return 'This sign-in method is not supported on your device.';
      case AuthErrorType.unknown:
        return message.isNotEmpty ? message : 'An unexpected error occurred. Please try again.';
    }
  }
}

enum AuthErrorType {
  invalidCredentials,
  userAlreadyExists,
  weakPassword,
  invalidEmail,
  network,
  rateLimited,
  sessionExpired,
  userCancelled,
  notSupported,
  unknown,
}