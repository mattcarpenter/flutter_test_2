// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Stockpot';

  @override
  String get authSignUp => 'Sign Up';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authCreateAccount => 'Create Account';

  @override
  String get authContinueWithEmail => 'Continue with Email';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String authContinueWithProvider(String provider) {
    return 'Continue with $provider';
  }

  @override
  String get authSignInWithGoogle => 'Sign in with Google';

  @override
  String get authSignInWithApple => 'Sign in with Apple';

  @override
  String get authAlreadyHaveAccount => 'Already have an account? ';

  @override
  String get authDontHaveAccount => 'Don\'t have an account? ';

  @override
  String get authForgotPassword => 'Forgot Password?';

  @override
  String get authResetPassword => 'Reset Password';

  @override
  String get authSendResetLink => 'Send Reset Link';

  @override
  String get authResetPasswordInstructions =>
      'Enter your email address and we\'ll send you a link to reset your password.';

  @override
  String get authRememberPassword => 'Remember your password? ';

  @override
  String get authOr => 'OR';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailPlaceholder => 'your@email.com';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authConfirmPasswordLabel => 'Confirm Password';

  @override
  String get authEmailRequired => 'Email is required';

  @override
  String get authEmailInvalid => 'Please enter a valid email address';

  @override
  String get authPasswordRequired => 'Password is required';

  @override
  String get authPasswordTooShort => 'Password must be at least 6 characters';

  @override
  String get authConfirmPasswordRequired => 'Please confirm your password';

  @override
  String get authPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get authEnterEmailAndPassword =>
      'Please enter both email and password.';

  @override
  String get authTermsPrefix => 'I agree to the ';

  @override
  String get authTermsOfService => 'Terms of Service';

  @override
  String get authTermsAnd => ' and ';

  @override
  String get authPrivacyPolicy => 'Privacy Policy';

  @override
  String get authAcceptTermsRequired =>
      'Please accept the Terms of Service and Privacy Policy to continue.';

  @override
  String get authFailedGoogle =>
      'Failed to sign in with Google. Please try again.';

  @override
  String get authFailedApple =>
      'Failed to sign in with Apple. Please try again.';

  @override
  String get authFailedSignIn =>
      'Failed to sign in. Please check your credentials and try again.';

  @override
  String get authFailedCreateAccount =>
      'Failed to create account. Please try again.';

  @override
  String authFailedSignUpWithProvider(String provider) {
    return 'Failed to sign up with $provider. Please try again.';
  }

  @override
  String authFailedSignInWithProvider(String provider) {
    return 'Failed to sign in with $provider. Please try again.';
  }

  @override
  String get authPasswordResetSuccess =>
      'Password reset email sent! Check your inbox and follow the instructions to reset your password.';

  @override
  String get authPasswordResetFailed =>
      'Failed to send reset email. Please check your email address and try again.';

  @override
  String get authSignInWarningTitle => 'Sign In Warning';

  @override
  String get authSignInWarningMessage =>
      'You currently have a Stockpot Plus subscription tied to this device. If you sign in to an existing account:\n\n• Your local recipes will be replaced with the account\'s data\n• You\'ll need to restore your purchase after signing in\n\nWe recommend exporting your recipes first.';

  @override
  String get authSignInAnyway => 'Sign In Anyway';

  @override
  String get authReplaceLocalDataTitle => 'Replace Local Data?';

  @override
  String get authReplaceLocalDataMessage =>
      'Signing in will replace your local recipes with the account\'s data. We recommend exporting your recipes first.';

  @override
  String get authAccountExistsTitle => 'Account Already Exists';

  @override
  String authAccountExistsMessage(String provider) {
    return 'This $provider account is already linked to another user. Please go to Sign In to access that account.';
  }

  @override
  String get authGoToSignIn => 'Go to Sign In';

  @override
  String get commonCancel => 'Cancel';
}
