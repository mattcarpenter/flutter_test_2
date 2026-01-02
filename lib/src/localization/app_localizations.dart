import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Stockpot'**
  String get appTitle;

  /// Sign up page title and link text
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignUp;

  /// Sign in page title and link text
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// Create account page title and button text
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccount;

  /// Button text for email sign up
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get authContinueWithEmail;

  /// Button text for Google sign in
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// Button text for OAuth provider sign in
  ///
  /// In en, this message translates to:
  /// **'Continue with {provider}'**
  String authContinueWithProvider(String provider);

  /// Google sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get authSignInWithGoogle;

  /// Apple sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get authSignInWithApple;

  /// Text before sign in link
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get authAlreadyHaveAccount;

  /// Text before sign up link
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get authDontHaveAccount;

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get authForgotPassword;

  /// Reset password page title
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get authResetPassword;

  /// Reset password button text
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get authSendResetLink;

  /// Instructions on reset password page
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a link to reset your password.'**
  String get authResetPasswordInstructions;

  /// Text before sign in link on reset password page
  ///
  /// In en, this message translates to:
  /// **'Remember your password? '**
  String get authRememberPassword;

  /// Divider text between auth options
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get authOr;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// Email field placeholder
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get authEmailPlaceholder;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPasswordLabel;

  /// Email validation error
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get authEmailRequired;

  /// Email format validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get authEmailInvalid;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authPasswordRequired;

  /// Password length validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authPasswordTooShort;

  /// Confirm password validation error
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get authConfirmPasswordRequired;

  /// Password mismatch validation error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsDoNotMatch;

  /// Error when email or password is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter both email and password.'**
  String get authEnterEmailAndPassword;

  /// Text before Terms of Service link
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get authTermsPrefix;

  /// Terms of service link text
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get authTermsOfService;

  /// Text between Terms and Privacy links
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get authTermsAnd;

  /// Privacy policy link text
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacyPolicy;

  /// Error when terms not accepted
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms of Service and Privacy Policy to continue.'**
  String get authAcceptTermsRequired;

  /// Google sign in error message
  ///
  /// In en, this message translates to:
  /// **'Failed to sign in with Google. Please try again.'**
  String get authFailedGoogle;

  /// Apple sign in error message
  ///
  /// In en, this message translates to:
  /// **'Failed to sign in with Apple. Please try again.'**
  String get authFailedApple;

  /// General sign in error message
  ///
  /// In en, this message translates to:
  /// **'Failed to sign in. Please check your credentials and try again.'**
  String get authFailedSignIn;

  /// Account creation error message
  ///
  /// In en, this message translates to:
  /// **'Failed to create account. Please try again.'**
  String get authFailedCreateAccount;

  /// OAuth sign up error message
  ///
  /// In en, this message translates to:
  /// **'Failed to sign up with {provider}. Please try again.'**
  String authFailedSignUpWithProvider(String provider);

  /// OAuth sign in error message
  ///
  /// In en, this message translates to:
  /// **'Failed to sign in with {provider}. Please try again.'**
  String authFailedSignInWithProvider(String provider);

  /// Password reset success message
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent! Check your inbox and follow the instructions to reset your password.'**
  String get authPasswordResetSuccess;

  /// Password reset error message
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email. Please check your email address and try again.'**
  String get authPasswordResetFailed;

  /// Warning dialog title for subscription users
  ///
  /// In en, this message translates to:
  /// **'Sign In Warning'**
  String get authSignInWarningTitle;

  /// Warning message for subscription users signing in
  ///
  /// In en, this message translates to:
  /// **'You currently have a Stockpot Plus subscription tied to this device. If you sign in to an existing account:\n\n• Your local recipes will be replaced with the account\'s data\n• You\'ll need to restore your purchase after signing in\n\nWe recommend exporting your recipes first.'**
  String get authSignInWarningMessage;

  /// Destructive action button text
  ///
  /// In en, this message translates to:
  /// **'Sign In Anyway'**
  String get authSignInAnyway;

  /// Warning dialog title for anonymous users
  ///
  /// In en, this message translates to:
  /// **'Replace Local Data?'**
  String get authReplaceLocalDataTitle;

  /// Warning message for anonymous users signing in
  ///
  /// In en, this message translates to:
  /// **'Signing in will replace your local recipes with the account\'s data. We recommend exporting your recipes first.'**
  String get authReplaceLocalDataMessage;

  /// Dialog title when OAuth identity already linked
  ///
  /// In en, this message translates to:
  /// **'Account Already Exists'**
  String get authAccountExistsTitle;

  /// Dialog message when OAuth identity already linked
  ///
  /// In en, this message translates to:
  /// **'This {provider} account is already linked to another user. Please go to Sign In to access that account.'**
  String authAccountExistsMessage(String provider);

  /// Button to navigate to sign in
  ///
  /// In en, this message translates to:
  /// **'Go to Sign In'**
  String get authGoToSignIn;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
