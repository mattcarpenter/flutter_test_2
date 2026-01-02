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

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Clear button text
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// Error dialog title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'...'**
  String get commonLoading;

  /// Coming soon placeholder text
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get commonComingSoon;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Home screen settings row
  ///
  /// In en, this message translates to:
  /// **'Home Screen'**
  String get settingsHomeScreen;

  /// Layout and appearance settings row
  ///
  /// In en, this message translates to:
  /// **'Layout & Appearance'**
  String get settingsLayoutAppearance;

  /// Manage tags settings row
  ///
  /// In en, this message translates to:
  /// **'Manage Tags'**
  String get settingsManageTags;

  /// Account settings row
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// Import recipes settings row
  ///
  /// In en, this message translates to:
  /// **'Import Recipes'**
  String get settingsImportRecipes;

  /// Export recipes settings row
  ///
  /// In en, this message translates to:
  /// **'Export Recipes'**
  String get settingsExportRecipes;

  /// Help settings row
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsHelp;

  /// Support settings row
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSupport;

  /// Privacy policy settings row
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// Terms of use settings row
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get settingsTermsOfUse;

  /// Acknowledgements settings row
  ///
  /// In en, this message translates to:
  /// **'Acknowledgements'**
  String get settingsAcknowledgements;

  /// Recipes home screen option
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get settingsHomeScreenRecipes;

  /// Shopping home screen option
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get settingsHomeScreenShopping;

  /// Meal plan home screen option
  ///
  /// In en, this message translates to:
  /// **'Meal Plan'**
  String get settingsHomeScreenMealPlan;

  /// Pantry home screen option
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get settingsHomeScreenPantry;

  /// Home screen setting description
  ///
  /// In en, this message translates to:
  /// **'Choose which tab opens when the app launches. Changes take effect on next app launch.'**
  String get settingsHomeScreenDescription;

  /// Fallback when user has no email
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get settingsAccountNoEmail;

  /// Sign out error dialog title
  ///
  /// In en, this message translates to:
  /// **'Sign Out Error'**
  String get settingsAccountSignOutError;

  /// Sign out error message
  ///
  /// In en, this message translates to:
  /// **'Failed to sign out: {error}'**
  String settingsAccountSignOutErrorMessage(String error);

  /// Unsaved changes dialog title
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get settingsAccountUnsavedChanges;

  /// Unsaved changes warning message
  ///
  /// In en, this message translates to:
  /// **'Some data hasn\'t finished syncing to the cloud. If you sign out now, these changes may be lost.\n\nAre you sure you want to sign out?'**
  String get settingsAccountUnsavedChangesMessage;

  /// Sign out button text
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsAccountSignOut;

  /// Sign out anyway button text
  ///
  /// In en, this message translates to:
  /// **'Sign Out Anyway'**
  String get settingsAccountSignOutAnyway;

  /// Account not linked notice title
  ///
  /// In en, this message translates to:
  /// **'Account Not Linked'**
  String get settingsAccountNotLinked;

  /// Account not linked warning message
  ///
  /// In en, this message translates to:
  /// **'You have Stockpot Plus but no account linked. Create an account to sync your recipes across devices and prevent data loss.'**
  String get settingsAccountNotLinkedMessage;

  /// Recipes page section header
  ///
  /// In en, this message translates to:
  /// **'Recipes Page'**
  String get settingsLayoutRecipesPage;

  /// Show folders setting row
  ///
  /// In en, this message translates to:
  /// **'Show Folders'**
  String get settingsLayoutShowFolders;

  /// Sort folders setting row
  ///
  /// In en, this message translates to:
  /// **'Sort Folders'**
  String get settingsLayoutSortFolders;

  /// Appearance section header
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsLayoutAppearanceSection;

  /// Color theme setting row
  ///
  /// In en, this message translates to:
  /// **'Color Theme'**
  String get settingsLayoutColorTheme;

  /// Recipe font size setting row
  ///
  /// In en, this message translates to:
  /// **'Recipe Font Size'**
  String get settingsLayoutRecipeFontSize;

  /// Show all folders option
  ///
  /// In en, this message translates to:
  /// **'All folders'**
  String get settingsShowFoldersAll;

  /// Show first N folders option
  ///
  /// In en, this message translates to:
  /// **'First {count} folders'**
  String settingsShowFoldersFirst(int count);

  /// First N folders option label
  ///
  /// In en, this message translates to:
  /// **'First N folders'**
  String get settingsShowFoldersFirstN;

  /// Number of folders section header
  ///
  /// In en, this message translates to:
  /// **'Number of Folders'**
  String get settingsShowFoldersNumberHeader;

  /// Number of folders setting description
  ///
  /// In en, this message translates to:
  /// **'Show this many folders on the recipes page.'**
  String get settingsShowFoldersNumberDescription;

  /// Sort alphabetically A-Z option
  ///
  /// In en, this message translates to:
  /// **'Alphabetical (A-Z)'**
  String get settingsSortFoldersAlphaAZ;

  /// Sort alphabetically Z-A option
  ///
  /// In en, this message translates to:
  /// **'Alphabetical (Z-A)'**
  String get settingsSortFoldersAlphaZA;

  /// Sort newest first option
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get settingsSortFoldersNewest;

  /// Sort oldest first option
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get settingsSortFoldersOldest;

  /// Custom sort order option
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get settingsSortFoldersCustom;

  /// Error loading folders message
  ///
  /// In en, this message translates to:
  /// **'Error loading folders'**
  String get settingsSortFoldersError;

  /// Custom order section header
  ///
  /// In en, this message translates to:
  /// **'CUSTOM ORDER'**
  String get settingsSortFoldersCustomOrder;

  /// Drag to reorder description
  ///
  /// In en, this message translates to:
  /// **'Drag folders to set your preferred order.'**
  String get settingsSortFoldersDragDescription;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Light theme description
  ///
  /// In en, this message translates to:
  /// **'Always use light appearance'**
  String get settingsThemeLightDescription;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Dark theme description
  ///
  /// In en, this message translates to:
  /// **'Always use dark appearance'**
  String get settingsThemeDarkDescription;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// System theme description
  ///
  /// In en, this message translates to:
  /// **'Match device appearance'**
  String get settingsThemeSystemDescription;

  /// Font size page title
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get settingsFontSizeTitle;

  /// Small font size option
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get settingsFontSizeSmall;

  /// Medium font size option
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get settingsFontSizeMedium;

  /// Large font size option
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get settingsFontSizeLarge;

  /// Font size setting description
  ///
  /// In en, this message translates to:
  /// **'Adjust the text size for recipe ingredients and steps.'**
  String get settingsFontSizeDescription;

  /// Font size preview section header
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get settingsFontSizePreview;

  /// Preview ingredients header
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get settingsFontSizePreviewIngredients;

  /// Preview ingredient 1
  ///
  /// In en, this message translates to:
  /// **'2 cups all-purpose flour'**
  String get settingsFontSizePreviewItem1;

  /// Preview ingredient 2
  ///
  /// In en, this message translates to:
  /// **'1 tsp baking powder'**
  String get settingsFontSizePreviewItem2;

  /// Preview ingredient 3
  ///
  /// In en, this message translates to:
  /// **'1/2 cup unsalted butter, softened'**
  String get settingsFontSizePreviewItem3;

  /// No tags empty state title
  ///
  /// In en, this message translates to:
  /// **'No Tags Yet'**
  String get settingsTagsNoTagsTitle;

  /// No tags empty state description
  ///
  /// In en, this message translates to:
  /// **'Tags help you organize your recipes.\nCreate your first tag by adding one when editing a recipe.'**
  String get settingsTagsNoTagsDescription;

  /// Your tags section header
  ///
  /// In en, this message translates to:
  /// **'Your Tags'**
  String get settingsTagsYourTags;

  /// Tags management description
  ///
  /// In en, this message translates to:
  /// **'Tap a color circle to change the tag color. Deleting a tag will remove it from all recipes.'**
  String get settingsTagsDescription;

  /// Delete tag confirmation title
  ///
  /// In en, this message translates to:
  /// **'Delete \"{tagName}\"?'**
  String settingsTagsDeleteTitle(String tagName);

  /// Delete tag message when tag has recipes
  ///
  /// In en, this message translates to:
  /// **'This tag is used by {count, plural, =1{1 recipe} other{{count} recipes}}. Deleting it will remove the tag from all recipes.'**
  String settingsTagsDeleteMessageWithRecipes(int count);

  /// Delete tag message when tag has no recipes
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get settingsTagsDeleteMessageNoRecipes;

  /// Recipe count display for tags
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No recipes} =1{1 recipe} other{{count} recipes}}'**
  String settingsTagsRecipeCount(int count);

  /// Diagnostics section header
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get settingsSupportDiagnostics;

  /// Export logs row
  ///
  /// In en, this message translates to:
  /// **'Export Logs'**
  String get settingsSupportExportLogs;

  /// Clear logs row
  ///
  /// In en, this message translates to:
  /// **'Clear Logs'**
  String get settingsSupportClearLogs;

  /// Contact section header
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get settingsSupportContact;

  /// Email support row
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get settingsSupportEmailSupport;

  /// No logs available dialog title
  ///
  /// In en, this message translates to:
  /// **'No Logs Available'**
  String get settingsSupportNoLogs;

  /// No logs available message
  ///
  /// In en, this message translates to:
  /// **'There are no logs to export yet.'**
  String get settingsSupportNoLogsMessage;

  /// Clear logs confirmation title
  ///
  /// In en, this message translates to:
  /// **'Clear Logs?'**
  String get settingsSupportClearLogsTitle;

  /// Clear logs confirmation message
  ///
  /// In en, this message translates to:
  /// **'This will delete all diagnostic logs. This action cannot be undone.'**
  String get settingsSupportClearLogsMessage;

  /// Logs cleared success title
  ///
  /// In en, this message translates to:
  /// **'Logs Cleared'**
  String get settingsSupportLogsCleared;

  /// Logs cleared success message
  ///
  /// In en, this message translates to:
  /// **'All diagnostic logs have been deleted.'**
  String get settingsSupportLogsClearedMessage;

  /// Logs clear failed message
  ///
  /// In en, this message translates to:
  /// **'Failed to clear logs. Please try again.'**
  String get settingsSupportLogsClearFailed;

  /// Email error dialog title
  ///
  /// In en, this message translates to:
  /// **'Unable to Open Email'**
  String get settingsSupportEmailError;

  /// Email error message with fallback address
  ///
  /// In en, this message translates to:
  /// **'Please email us at support@stockpot.app'**
  String get settingsSupportEmailErrorMessage;

  /// Support email subject
  ///
  /// In en, this message translates to:
  /// **'Stockpot Support Request'**
  String get settingsSupportEmailSubject;

  /// User ID fallback when not signed in
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get settingsSupportNotSignedIn;

  /// Support email body template
  ///
  /// In en, this message translates to:
  /// **'Please describe your issue above this line\n\n---\nUser ID: {userId}\nApp Version: {appVersion}\nPlatform: {platform}\nOS Version: {osVersion}'**
  String settingsSupportEmailBody(
      String userId, String appVersion, String platform, String osVersion);

  /// OSS licenses row
  ///
  /// In en, this message translates to:
  /// **'Open Source Software Licenses'**
  String get settingsAcknowledgementsOSSLicenses;

  /// Sound credits attribution
  ///
  /// In en, this message translates to:
  /// **'Sound material used: OtoLogic (https://otologic.jp)'**
  String get settingsAcknowledgementsSoundCredits;

  /// Import recipes description
  ///
  /// In en, this message translates to:
  /// **'Import recipes from other apps or websites.'**
  String get settingsImportDescription;

  /// Export recipes description
  ///
  /// In en, this message translates to:
  /// **'Export your recipes to share or backup.'**
  String get settingsExportDescription;

  /// Import page title
  ///
  /// In en, this message translates to:
  /// **'Import Recipes'**
  String get importTitle;

  /// Import source section header
  ///
  /// In en, this message translates to:
  /// **'Import from:'**
  String get importFromHeader;

  /// Stockpot import source
  ///
  /// In en, this message translates to:
  /// **'Stockpot'**
  String get importSourceStockpot;

  /// Stockpot import description
  ///
  /// In en, this message translates to:
  /// **'Import from a previous backup'**
  String get importSourceStockpotDesc;

  /// Paprika import source
  ///
  /// In en, this message translates to:
  /// **'Paprika'**
  String get importSourcePaprika;

  /// Paprika import description
  ///
  /// In en, this message translates to:
  /// **'Import from Paprika Recipe Manager'**
  String get importSourcePaprikaDesc;

  /// Crouton import source
  ///
  /// In en, this message translates to:
  /// **'Crouton'**
  String get importSourceCrouton;

  /// Crouton import description
  ///
  /// In en, this message translates to:
  /// **'Import from Crouton app'**
  String get importSourceCroutonDesc;

  /// Invalid file dialog title
  ///
  /// In en, this message translates to:
  /// **'Invalid File'**
  String get importInvalidFile;

  /// Invalid Paprika file message
  ///
  /// In en, this message translates to:
  /// **'Please select a .paprikarecipes file exported from Paprika.'**
  String get importInvalidPaprikaFile;

  /// Import preview page title
  ///
  /// In en, this message translates to:
  /// **'Import Preview'**
  String get importPreviewTitle;

  /// Loading message while analyzing import
  ///
  /// In en, this message translates to:
  /// **'Analyzing import file...'**
  String get importAnalyzing;

  /// Parse failure title
  ///
  /// In en, this message translates to:
  /// **'Failed to Parse Import'**
  String get importParseFailed;

  /// Unknown error fallback
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get importUnknownError;

  /// Preview header with source name
  ///
  /// In en, this message translates to:
  /// **'Ready to import from {source}:'**
  String importReadyFrom(String source);

  /// Recipe count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recipe} other{{count} recipes}}'**
  String importRecipeCount(int count);

  /// Tag count summary
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{1 tag} other{{total} tags}} ({newCount} new, {existingCount} existing)'**
  String importTagCount(int total, int newCount, int existingCount);

  /// Folder count summary
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{1 folder} other{{total} folders}} ({newCount} new, {existingCount} existing)'**
  String importFolderCount(int total, int newCount, int existingCount);

  /// Paprika categories section header
  ///
  /// In en, this message translates to:
  /// **'Paprika Categories'**
  String get importPaprikaCategoriesHeader;

  /// Paprika categories section footer
  ///
  /// In en, this message translates to:
  /// **'Choose whether to import Paprika categories as tags or folders.'**
  String get importPaprikaCategoriesFooter;

  /// Import as tags option
  ///
  /// In en, this message translates to:
  /// **'Tags (recommended)'**
  String get importAsTags;

  /// Import as folders option
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get importAsFolders;

  /// Import button text
  ///
  /// In en, this message translates to:
  /// **'Import Recipes'**
  String get importButton;

  /// Import complete dialog title
  ///
  /// In en, this message translates to:
  /// **'Import Complete'**
  String get importComplete;

  /// Import finished with partial success
  ///
  /// In en, this message translates to:
  /// **'Import Finished'**
  String get importFinished;

  /// Success message
  ///
  /// In en, this message translates to:
  /// **'Successfully imported {count, plural, =1{1 recipe} other{{count} recipes}}!'**
  String importSuccessMessage(int count);

  /// Success with upgrade prompt
  ///
  /// In en, this message translates to:
  /// **'Imported {count} recipes. Upgrade to unlock your full collection.'**
  String importSuccessUpgradeMessage(int count);

  /// Partial success message
  ///
  /// In en, this message translates to:
  /// **'Imported {success} recipes. {failed} failed.'**
  String importPartialMessage(int success, int failed);

  /// Import failed dialog title
  ///
  /// In en, this message translates to:
  /// **'Import Failed'**
  String get importFailed;

  /// Import failed message
  ///
  /// In en, this message translates to:
  /// **'Failed to import recipes: {error}'**
  String importFailedMessage(String error);

  /// Export page title
  ///
  /// In en, this message translates to:
  /// **'Export Recipes'**
  String get exportTitle;

  /// Export options section header
  ///
  /// In en, this message translates to:
  /// **'Export Options'**
  String get exportOptionsHeader;

  /// Export all recipes row
  ///
  /// In en, this message translates to:
  /// **'Export All Recipes'**
  String get exportAllRecipes;

  /// Export in progress
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get exportExporting;

  /// Export formats coming soon
  ///
  /// In en, this message translates to:
  /// **'Additional export formats (HTML, PDF, etc.) coming soon.'**
  String get exportComingSoon;

  /// No recipes dialog title
  ///
  /// In en, this message translates to:
  /// **'No Recipes'**
  String get exportNoRecipes;

  /// No recipes message
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any recipes to export.'**
  String get exportNoRecipesMessage;

  /// Share sheet subject
  ///
  /// In en, this message translates to:
  /// **'My Recipes Export'**
  String get exportShareSubject;

  /// Export complete dialog title
  ///
  /// In en, this message translates to:
  /// **'Export Complete'**
  String get exportComplete;

  /// Export success message
  ///
  /// In en, this message translates to:
  /// **'Successfully exported {count, plural, =1{1 recipe} other{{count} recipes}}.'**
  String exportSuccessMessage(int count);

  /// Export failed dialog title
  ///
  /// In en, this message translates to:
  /// **'Export Failed'**
  String get exportFailed;

  /// Export failed message
  ///
  /// In en, this message translates to:
  /// **'Failed to export recipes: {error}'**
  String exportFailedMessage(String error);
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
