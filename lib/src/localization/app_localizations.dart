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

  /// Add button text
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

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

  /// Help page title
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// Error message when help topics fail to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load help topics'**
  String get helpLoadError;

  /// Help section name
  ///
  /// In en, this message translates to:
  /// **'Adding Recipes'**
  String get helpSectionAddingRecipes;

  /// Help section name
  ///
  /// In en, this message translates to:
  /// **'Quick Questions'**
  String get helpSectionQuickQuestions;

  /// Help section name
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get helpSectionLearnMore;

  /// Help section name
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get helpSectionTroubleshooting;

  /// Recipes page title
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get recipesTitle;

  /// Recipe folders section header
  ///
  /// In en, this message translates to:
  /// **'Recipe Folders'**
  String get recipesFolders;

  /// Add folder button
  ///
  /// In en, this message translates to:
  /// **'Add Folder'**
  String get recipesAddFolder;

  /// Add smart folder button
  ///
  /// In en, this message translates to:
  /// **'Add Smart Folder'**
  String get recipesAddSmartFolder;

  /// Recently viewed section title
  ///
  /// In en, this message translates to:
  /// **'Recently Viewed'**
  String get recipesRecentlyViewed;

  /// Pinned recipes section title
  ///
  /// In en, this message translates to:
  /// **'Pinned Recipes'**
  String get recipesPinnedRecipes;

  /// View all button
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get recipesViewAll;

  /// Recipe not found message
  ///
  /// In en, this message translates to:
  /// **'Recipe not found'**
  String get recipesNotFound;

  /// Recipe loading error
  ///
  /// In en, this message translates to:
  /// **'Error loading recipe: {error}'**
  String recipesLoadError(String error);

  /// Create recipe modal title
  ///
  /// In en, this message translates to:
  /// **'Create a Recipe'**
  String get recipeCreateTitle;

  /// Create manually option
  ///
  /// In en, this message translates to:
  /// **'Create Manually'**
  String get recipeCreateManually;

  /// Create manually description
  ///
  /// In en, this message translates to:
  /// **'Start from scratch'**
  String get recipeCreateManuallyDesc;

  /// Import from URL option
  ///
  /// In en, this message translates to:
  /// **'Import from URL'**
  String get recipeImportFromUrl;

  /// Import from URL description
  ///
  /// In en, this message translates to:
  /// **'Paste a recipe link'**
  String get recipeImportFromUrlDesc;

  /// Generate with AI option
  ///
  /// In en, this message translates to:
  /// **'Generate with AI'**
  String get recipeGenerateWithAi;

  /// Generate with AI description
  ///
  /// In en, this message translates to:
  /// **'Describe what you want'**
  String get recipeGenerateWithAiDesc;

  /// Import from social option
  ///
  /// In en, this message translates to:
  /// **'Import from Social'**
  String get recipeImportFromSocial;

  /// Import from social description
  ///
  /// In en, this message translates to:
  /// **'Instagram, TikTok, YouTube'**
  String get recipeImportFromSocialDesc;

  /// Import from camera option
  ///
  /// In en, this message translates to:
  /// **'Import from Camera'**
  String get recipeImportFromCamera;

  /// Import from camera description
  ///
  /// In en, this message translates to:
  /// **'Photograph a recipe'**
  String get recipeImportFromCameraDesc;

  /// Import from photos option
  ///
  /// In en, this message translates to:
  /// **'Import from Photos'**
  String get recipeImportFromPhotos;

  /// Import from photos description
  ///
  /// In en, this message translates to:
  /// **'Select from your library'**
  String get recipeImportFromPhotosDesc;

  /// Discover recipes option
  ///
  /// In en, this message translates to:
  /// **'Discover Recipes'**
  String get recipeDiscoverRecipes;

  /// Discover recipes description
  ///
  /// In en, this message translates to:
  /// **'Browse and import from the web'**
  String get recipeDiscoverRecipesDesc;

  /// Plus badge text
  ///
  /// In en, this message translates to:
  /// **'PLUS'**
  String get recipePlus;

  /// Social import modal title
  ///
  /// In en, this message translates to:
  /// **'Import from Social Media'**
  String get recipeSocialImportTitle;

  /// Social import instructions
  ///
  /// In en, this message translates to:
  /// **'To import a recipe from Instagram, TikTok, or YouTube:'**
  String get recipeSocialImportInstructions;

  /// Social import step 1
  ///
  /// In en, this message translates to:
  /// **'Open the app and find a recipe video'**
  String get recipeSocialImportStep1;

  /// Social import step 2
  ///
  /// In en, this message translates to:
  /// **'Tap the Share button'**
  String get recipeSocialImportStep2;

  /// Social import step 3
  ///
  /// In en, this message translates to:
  /// **'Select \"Stockpot\" from the share menu'**
  String get recipeSocialImportStep3;

  /// Social import step 4
  ///
  /// In en, this message translates to:
  /// **'We\'ll extract the recipe automatically'**
  String get recipeSocialImportStep4;

  /// Got it button
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get recipeGotIt;

  /// New folder modal title
  ///
  /// In en, this message translates to:
  /// **'New Recipe Folder'**
  String get recipeFolderNew;

  /// Folder name placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter Folder Name'**
  String get recipeFolderEnterName;

  /// Folder name required error
  ///
  /// In en, this message translates to:
  /// **'Folder name is required'**
  String get recipeFolderNameRequired;

  /// Create folder button
  ///
  /// In en, this message translates to:
  /// **'Create New Folder'**
  String get recipeFolderCreateNew;

  /// Rename folder modal title
  ///
  /// In en, this message translates to:
  /// **'Rename Folder'**
  String get recipeFolderRename;

  /// Folder name label
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get recipeFolderName;

  /// Rename button
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get recipeFolderRenameButton;

  /// Delete folder action
  ///
  /// In en, this message translates to:
  /// **'Delete Folder'**
  String get recipeFolderDelete;

  /// No folders message
  ///
  /// In en, this message translates to:
  /// **'No folders yet'**
  String get recipeFolderNoFolders;

  /// Folders label
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get recipeFolders;

  /// AI generator title
  ///
  /// In en, this message translates to:
  /// **'Generate with AI'**
  String get recipeAiTitle;

  /// AI generator subtitle
  ///
  /// In en, this message translates to:
  /// **'Describe what you want to eat'**
  String get recipeAiDescribe;

  /// AI generator input placeholder
  ///
  /// In en, this message translates to:
  /// **'e.g., \"I want a warm soup with chicken\"'**
  String get recipeAiPlaceholder;

  /// Use pantry items toggle
  ///
  /// In en, this message translates to:
  /// **'Use pantry items'**
  String get recipeAiUsePantry;

  /// Items in stock count
  ///
  /// In en, this message translates to:
  /// **'{count} items in stock'**
  String recipeAiItemsInStock(int count);

  /// Selected items count
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String recipeAiSelected(int count);

  /// Generate ideas button
  ///
  /// In en, this message translates to:
  /// **'Generate Ideas'**
  String get recipeAiGenerateIdeas;

  /// Recipe ideas title
  ///
  /// In en, this message translates to:
  /// **'Recipe Ideas'**
  String get recipeAiRecipeIdeas;

  /// Select recipe instruction
  ///
  /// In en, this message translates to:
  /// **'Select a recipe to generate'**
  String get recipeAiSelectToGenerate;

  /// Brainstorming status
  ///
  /// In en, this message translates to:
  /// **'Brainstorming recipes...'**
  String get recipeAiBrainstorming;

  /// Considering status
  ///
  /// In en, this message translates to:
  /// **'Considering your preferences...'**
  String get recipeAiConsidering;

  /// Finding ideas status
  ///
  /// In en, this message translates to:
  /// **'Finding delicious ideas...'**
  String get recipeAiFinding;

  /// Generating recipe status
  ///
  /// In en, this message translates to:
  /// **'Generating recipe...'**
  String get recipeAiGenerating;

  /// Writing ingredients status
  ///
  /// In en, this message translates to:
  /// **'Writing ingredients...'**
  String get recipeAiWritingIngredients;

  /// Crafting instructions status
  ///
  /// In en, this message translates to:
  /// **'Crafting instructions...'**
  String get recipeAiCraftingInstructions;

  /// Limit reached error title
  ///
  /// In en, this message translates to:
  /// **'Limit Reached'**
  String get recipeAiLimitReached;

  /// Generation failed error title
  ///
  /// In en, this message translates to:
  /// **'Generation Failed'**
  String get recipeAiGenerationFailed;

  /// Upgrade to Plus button
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Plus'**
  String get recipeAiUpgradeToPlus;

  /// Try again button
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get recipeAiTryAgain;

  /// Select pantry items title
  ///
  /// In en, this message translates to:
  /// **'Select Pantry Items'**
  String get recipeAiSelectPantryItems;

  /// Select all button
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get recipeAiSelectAll;

  /// Deselect all button
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get recipeAiDeselectAll;

  /// No pantry items message
  ///
  /// In en, this message translates to:
  /// **'No pantry items available'**
  String get recipeAiNoPantryItems;

  /// Easy difficulty
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get recipeAiDifficultyEasy;

  /// Medium difficulty
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get recipeAiDifficultyMedium;

  /// Hard difficulty
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get recipeAiDifficultyHard;

  /// URL import modal title
  ///
  /// In en, this message translates to:
  /// **'Import from URL'**
  String get recipeUrlImportTitle;

  /// URL import subtitle
  ///
  /// In en, this message translates to:
  /// **'Paste a recipe URL to import'**
  String get recipeUrlImportSubtitle;

  /// URL import placeholder
  ///
  /// In en, this message translates to:
  /// **'https://example.com/recipe'**
  String get recipeUrlImportPlaceholder;

  /// Import recipe button
  ///
  /// In en, this message translates to:
  /// **'Import Recipe'**
  String get recipeUrlImportButton;

  /// Importing recipe title
  ///
  /// In en, this message translates to:
  /// **'Importing Recipe'**
  String get recipeUrlImporting;

  /// Fetching recipe status
  ///
  /// In en, this message translates to:
  /// **'Fetching recipe...'**
  String get recipeUrlFetching;

  /// Extracting recipe status
  ///
  /// In en, this message translates to:
  /// **'Extracting recipe...'**
  String get recipeUrlExtracting;

  /// Extraction failed title
  ///
  /// In en, this message translates to:
  /// **'Extraction Failed'**
  String get recipeUrlExtractionFailed;

  /// Offline error message
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Please check your internet connection.'**
  String get recipeUrlOffline;

  /// Invalid URL error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL.'**
  String get recipeUrlInvalid;

  /// No recipe found error
  ///
  /// In en, this message translates to:
  /// **'This page doesn\'t appear to contain recipe information.'**
  String get recipeUrlNoRecipe;

  /// Preview limit reached title
  ///
  /// In en, this message translates to:
  /// **'Preview Limit Reached'**
  String get recipeUrlPreviewLimitReached;

  /// Import failed title
  ///
  /// In en, this message translates to:
  /// **'Import Failed'**
  String get recipeUrlImportFailed;

  /// Preview limit message
  ///
  /// In en, this message translates to:
  /// **'Recipe previews are limited for free users. Upgrade to Plus for unlimited imports.'**
  String get recipeUrlPreviewLimit;

  /// Plus required message
  ///
  /// In en, this message translates to:
  /// **'This page requires Plus subscription for recipe extraction.'**
  String get recipeUrlPlusRequired;

  /// Something went wrong error
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get recipeUrlSomethingWrong;

  /// No recipe found message
  ///
  /// In en, this message translates to:
  /// **'No recipe found on this page.'**
  String get recipeUrlNoRecipeFound;

  /// Failed to extract error
  ///
  /// In en, this message translates to:
  /// **'Failed to extract recipe. Please try again.'**
  String get recipeUrlFailedExtract;

  /// Processing photo title
  ///
  /// In en, this message translates to:
  /// **'Processing Photo'**
  String get recipePhotoProcessing;

  /// Reading photo status
  ///
  /// In en, this message translates to:
  /// **'Reading photo...'**
  String get recipePhotoReading;

  /// Processing photo status
  ///
  /// In en, this message translates to:
  /// **'Processing photo...'**
  String get recipePhotoProcessingStatus;

  /// Extracting recipe status
  ///
  /// In en, this message translates to:
  /// **'Extracting recipe...'**
  String get recipePhotoExtracting;

  /// No recipe in photo error
  ///
  /// In en, this message translates to:
  /// **'No recipe found in the photo.\n\nTry a photo of a recipe card or cookbook page.'**
  String get recipePhotoNoRecipe;

  /// Photo processing failed error
  ///
  /// In en, this message translates to:
  /// **'Failed to process the image(s). Please try again.'**
  String get recipePhotoFailed;

  /// Photo import offline error
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Please check your internet connection and try again.'**
  String get recipePhotoOffline;

  /// New recipe title
  ///
  /// In en, this message translates to:
  /// **'New Recipe'**
  String get recipeEditorNewRecipe;

  /// Add images section
  ///
  /// In en, this message translates to:
  /// **'Add Images'**
  String get recipeEditorAddImages;

  /// Add ingredients section
  ///
  /// In en, this message translates to:
  /// **'Add Ingredients'**
  String get recipeEditorAddIngredients;

  /// Add instructions section
  ///
  /// In en, this message translates to:
  /// **'Add Instructions'**
  String get recipeEditorAddInstructions;

  /// Add notes section
  ///
  /// In en, this message translates to:
  /// **'Add Notes'**
  String get recipeEditorAddNotes;

  /// Notes placeholder
  ///
  /// In en, this message translates to:
  /// **'General notes about this recipe'**
  String get recipeEditorNotesPlaceholder;

  /// Source placeholder
  ///
  /// In en, this message translates to:
  /// **'Source (optional)'**
  String get recipeEditorSourcePlaceholder;

  /// Rating section
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get recipeEditorRating;

  /// Clear all ingredients dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear All Ingredients?'**
  String get recipeEditorClearAllIngredients;

  /// Clear all steps dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear All Steps?'**
  String get recipeEditorClearAllSteps;

  /// Clear confirmation message
  ///
  /// In en, this message translates to:
  /// **'This will remove all {count} {type}. This action cannot be undone.'**
  String recipeEditorClearConfirm(int count, String type);

  /// Clear all button
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get recipeEditorClearAll;

  /// New section default text
  ///
  /// In en, this message translates to:
  /// **'New Section'**
  String get recipeEditorNewSection;

  /// Save failed error
  ///
  /// In en, this message translates to:
  /// **'Failed to save recipe: {error}'**
  String recipeEditorSaveFailed(String error);

  /// Ingredients section title
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get recipeViewIngredients;

  /// Instructions section title
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get recipeViewInstructions;

  /// Scale or convert button
  ///
  /// In en, this message translates to:
  /// **'Scale or Convert'**
  String get recipeViewScaleConvert;

  /// No ingredients message
  ///
  /// In en, this message translates to:
  /// **'No ingredients listed.'**
  String get recipeViewNoIngredients;

  /// No instructions message
  ///
  /// In en, this message translates to:
  /// **'No instructions listed.'**
  String get recipeViewNoInstructions;

  /// Select tags modal title
  ///
  /// In en, this message translates to:
  /// **'Select Tags'**
  String get recipeTagSelectTitle;

  /// Create new tag button
  ///
  /// In en, this message translates to:
  /// **'Create New Tag'**
  String get recipeTagCreateNew;

  /// No tags message
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get recipeTagNoTags;

  /// Create first tag message
  ///
  /// In en, this message translates to:
  /// **'Create your first tag using the button above'**
  String get recipeTagCreateFirst;

  /// Tag name label
  ///
  /// In en, this message translates to:
  /// **'Tag Name'**
  String get recipeTagName;

  /// Tag name placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter tag name'**
  String get recipeTagEnterName;

  /// Tag color label
  ///
  /// In en, this message translates to:
  /// **'Tag Color'**
  String get recipeTagColor;

  /// Create tag button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get recipeTagCreate;

  /// Tag exists error
  ///
  /// In en, this message translates to:
  /// **'A tag with this name already exists'**
  String get recipeTagExists;

  /// Add to folders modal title
  ///
  /// In en, this message translates to:
  /// **'Add Recipe to Folders'**
  String get recipeFolderSelectTitle;

  /// Create first folder message
  ///
  /// In en, this message translates to:
  /// **'Create your first folder using the button above'**
  String get recipeFolderCreateFirst;

  /// Folder exists error
  ///
  /// In en, this message translates to:
  /// **'A folder with this name already exists'**
  String get recipeFolderExists;

  /// Reset all filters button
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get recipeFilterResetAll;

  /// Apply changes button
  ///
  /// In en, this message translates to:
  /// **'Apply Changes'**
  String get recipeFilterApply;

  /// Cook time filter title
  ///
  /// In en, this message translates to:
  /// **'Cook Time'**
  String get recipeFilterCookTime;

  /// Rating filter title
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get recipeFilterRating;

  /// Pantry match filter title
  ///
  /// In en, this message translates to:
  /// **'Pantry Match'**
  String get recipeFilterPantryMatch;

  /// Tags filter title
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get recipeFilterTags;

  /// Must have all tags toggle
  ///
  /// In en, this message translates to:
  /// **'Must have all tags'**
  String get recipeFilterMustHaveAllTags;

  /// Sort section title
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get recipeFilterSort;

  /// Sort by label
  ///
  /// In en, this message translates to:
  /// **'Sort by {option}'**
  String recipeFilterSortBy(String option);

  /// 0% pantry match label
  ///
  /// In en, this message translates to:
  /// **'Match any recipe (Stock not required)'**
  String get recipeFilterMatchAny;

  /// 25% pantry match label
  ///
  /// In en, this message translates to:
  /// **'A few ingredients in stock (25%)'**
  String get recipeFilterFewIngredients;

  /// 50% pantry match label
  ///
  /// In en, this message translates to:
  /// **'At least half ingredients in stock (50%)'**
  String get recipeFilterHalfIngredients;

  /// 75% pantry match label
  ///
  /// In en, this message translates to:
  /// **'Most ingredients in stock (75%)'**
  String get recipeFilterMostIngredients;

  /// 100% pantry match label
  ///
  /// In en, this message translates to:
  /// **'All ingredients in stock (100%)'**
  String get recipeFilterAllIngredients;

  /// Percent match label
  ///
  /// In en, this message translates to:
  /// **'{percent}% match'**
  String recipeFilterPercentMatch(int percent);

  /// Add recipe to cook button
  ///
  /// In en, this message translates to:
  /// **'Add Recipe'**
  String get recipeCookAddRecipe;

  /// Complete cook button
  ///
  /// In en, this message translates to:
  /// **'Complete Cook'**
  String get recipeCookComplete;

  /// Add recipe to cook modal title
  ///
  /// In en, this message translates to:
  /// **'Add Recipe to Cook'**
  String get recipeCookAddRecipeTitle;

  /// No steps message
  ///
  /// In en, this message translates to:
  /// **'No steps found for this recipe'**
  String get recipeCookNoSteps;

  /// Previous step button
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get recipeCookPrevious;

  /// Next step button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get recipeCookNext;

  /// Link to recipe option
  ///
  /// In en, this message translates to:
  /// **'Link to Recipe'**
  String get recipeIngredientLinkToRecipe;

  /// Convert to ingredient option
  ///
  /// In en, this message translates to:
  /// **'Convert to ingredient'**
  String get recipeIngredientConvertToIngredient;

  /// Section name hint
  ///
  /// In en, this message translates to:
  /// **'Section name'**
  String get recipeIngredientSectionName;

  /// Link to existing recipe option
  ///
  /// In en, this message translates to:
  /// **'Link to Existing Recipe'**
  String get recipeIngredientLinkExisting;

  /// Change linked recipe option
  ///
  /// In en, this message translates to:
  /// **'Change Linked Recipe'**
  String get recipeIngredientChangeLinked;

  /// Remove recipe link option
  ///
  /// In en, this message translates to:
  /// **'Remove Recipe Link'**
  String get recipeIngredientRemoveLink;

  /// No recipes found message
  ///
  /// In en, this message translates to:
  /// **'No recipes found'**
  String get recipeIngredientNoRecipesFound;

  /// No recipes match message
  ///
  /// In en, this message translates to:
  /// **'No recipes match your search'**
  String get recipeIngredientNoRecipesMatch;

  /// Placeholder text for ingredient input field
  ///
  /// In en, this message translates to:
  /// **'e.g. 1 cup flour'**
  String get recipeIngredientPlaceholder;

  /// Next step button
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get recipeStepNextStep;

  /// Convert to step option
  ///
  /// In en, this message translates to:
  /// **'Convert to step'**
  String get recipeStepConvertToStep;

  /// Convert to section option
  ///
  /// In en, this message translates to:
  /// **'Convert to section'**
  String get recipeStepConvertToSection;

  /// Step description placeholder
  ///
  /// In en, this message translates to:
  /// **'Describe this step'**
  String get recipeStepDescribe;

  /// Edit ingredients modal title
  ///
  /// In en, this message translates to:
  /// **'Edit Ingredients'**
  String get recipeEditIngredientsTitle;

  /// Edit steps modal title
  ///
  /// In en, this message translates to:
  /// **'Edit Steps'**
  String get recipeEditStepsTitle;

  /// Update button
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get recipeEditUpdate;

  /// Add to shopping list modal title
  ///
  /// In en, this message translates to:
  /// **'Add to Shopping List'**
  String get recipeAddToShoppingList;

  /// Add to shopping list button
  ///
  /// In en, this message translates to:
  /// **'Add to Shopping List'**
  String get recipeAddToShoppingListButton;

  /// Adding to shopping list status
  ///
  /// In en, this message translates to:
  /// **'Adding...'**
  String get recipeAddToShoppingListAdding;

  /// No ingredients to add message
  ///
  /// In en, this message translates to:
  /// **'No ingredients to add'**
  String get recipeAddToShoppingListNoIngredients;

  /// Default shopping list name
  ///
  /// In en, this message translates to:
  /// **'My Shopping List'**
  String get recipeAddToShoppingListDefault;

  /// Getting started title
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get recipeWelcomeGettingStarted;

  /// Welcome card title
  ///
  /// In en, this message translates to:
  /// **'Welcome to Stockpot!'**
  String get recipeWelcomeTitle;

  /// Welcome card subtitle
  ///
  /// In en, this message translates to:
  /// **'Create your first recipe and start\nbuilding your collection'**
  String get recipeWelcomeSubtitle;

  /// Edit recipe option
  ///
  /// In en, this message translates to:
  /// **'Edit Recipe'**
  String get recipeTileEdit;

  /// Delete recipe option
  ///
  /// In en, this message translates to:
  /// **'Delete Recipe'**
  String get recipeTileDelete;

  /// Recipe search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search for recipes to add'**
  String get recipeSearchPlaceholder;

  /// No search results message
  ///
  /// In en, this message translates to:
  /// **'No recipes found'**
  String get recipeSearchNoResults;

  /// Try different search suggestion
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get recipeSearchTryDifferent;

  /// Clear filters button
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get recipeSearchClearFilters;

  /// Filter and sort button
  ///
  /// In en, this message translates to:
  /// **'Filter and Sort'**
  String get recipeSearchFilterSort;

  /// Add recipe button
  ///
  /// In en, this message translates to:
  /// **'Add Recipe'**
  String get recipeAddRecipeButton;

  /// No recipes match filters message
  ///
  /// In en, this message translates to:
  /// **'No recipes match the current filters'**
  String get recipeFolderNoRecipesMatch;

  /// No recipes match tags message
  ///
  /// In en, this message translates to:
  /// **'No recipes match the selected tags'**
  String get recipeFolderNoTagsMatch;

  /// No recipes match ingredients message
  ///
  /// In en, this message translates to:
  /// **'No recipes match the selected ingredients'**
  String get recipeFolderNoIngredientsMatch;

  /// Edit smart folder menu item
  ///
  /// In en, this message translates to:
  /// **'Edit Smart Folder'**
  String get recipeEditSmartFolder;

  /// Cook time filter under 30 minutes
  ///
  /// In en, this message translates to:
  /// **'Under 30 minutes'**
  String get recipeCookTimeUnder30;

  /// Cook time filter 30-60 minutes
  ///
  /// In en, this message translates to:
  /// **'30-60 minutes'**
  String get recipeCookTime30To60;

  /// Cook time filter 1-2 hours
  ///
  /// In en, this message translates to:
  /// **'1-2 hours'**
  String get recipeCookTime1To2Hours;

  /// Cook time filter over 2 hours
  ///
  /// In en, this message translates to:
  /// **'Over 2 hours'**
  String get recipeCookTimeOver2Hours;

  /// Sort by pantry match option
  ///
  /// In en, this message translates to:
  /// **'Pantry Match %'**
  String get recipeSortPantryMatch;

  /// Sort alphabetically option
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get recipeSortAlphabetical;

  /// Sort by rating option
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get recipeSortRating;

  /// Sort by time option
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get recipeSortTime;

  /// Sort by added date option
  ///
  /// In en, this message translates to:
  /// **'Added Date'**
  String get recipeSortAddedDate;

  /// Sort by updated date option
  ///
  /// In en, this message translates to:
  /// **'Updated Date'**
  String get recipeSortUpdatedDate;

  /// Search error message
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String recipeSearchError(String error);

  /// New recipe modal title
  ///
  /// In en, this message translates to:
  /// **'New Recipe'**
  String get recipeAddModalNew;

  /// Edit recipe modal title
  ///
  /// In en, this message translates to:
  /// **'Edit Recipe'**
  String get recipeAddModalEdit;

  /// Create button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get recipeAddModalCreate;

  /// Update button
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get recipeAddModalUpdate;

  /// Failed to add recipe message
  ///
  /// In en, this message translates to:
  /// **'Failed to add recipe: {message}'**
  String recipeAddModalFailed(String message);

  /// Cannot add recipe dialog title
  ///
  /// In en, this message translates to:
  /// **'Cannot Add Recipe'**
  String get recipeAddModalCannotAdd;

  /// Add button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get recipeAddModalAdd;

  /// Search field placeholder in add recipe modal
  ///
  /// In en, this message translates to:
  /// **'Search recipes...'**
  String get recipeAddModalSearchPlaceholder;

  /// Initial state message prompting user to search
  ///
  /// In en, this message translates to:
  /// **'Search for recipes to add'**
  String get recipeAddModalSearchPrompt;

  /// Section header for recently viewed recipes
  ///
  /// In en, this message translates to:
  /// **'Recently Viewed'**
  String get recipeAddModalRecentlyViewed;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Done button
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Ingredient singular
  ///
  /// In en, this message translates to:
  /// **'ingredient'**
  String get commonIngredient;

  /// Ingredients plural
  ///
  /// In en, this message translates to:
  /// **'ingredients'**
  String get commonIngredients;

  /// Step singular
  ///
  /// In en, this message translates to:
  /// **'step'**
  String get commonStep;

  /// Steps plural
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get commonSteps;

  /// Add step button
  ///
  /// In en, this message translates to:
  /// **'Add Step'**
  String get recipeStepAddStep;

  /// Add section button
  ///
  /// In en, this message translates to:
  /// **'Add Section'**
  String get recipeStepAddSection;

  /// Edit as text menu option
  ///
  /// In en, this message translates to:
  /// **'Edit as Text'**
  String get recipeStepEditAsText;

  /// Clear all steps menu option
  ///
  /// In en, this message translates to:
  /// **'Clear All Steps'**
  String get recipeStepClearAll;

  /// Empty steps message
  ///
  /// In en, this message translates to:
  /// **'No steps added yet.'**
  String get recipeStepNoSteps;

  /// Pinned recipes page title
  ///
  /// In en, this message translates to:
  /// **'Pinned Recipes'**
  String get recipePinnedTitle;

  /// Message when search finds no pinned recipes
  ///
  /// In en, this message translates to:
  /// **'No pinned recipes match \"{query}\"'**
  String recipePinnedNoMatch(String query);

  /// Message when no recipes are pinned
  ///
  /// In en, this message translates to:
  /// **'No pinned recipes yet.\nPin your favorite recipes to see them here.'**
  String get recipePinnedEmpty;

  /// Generic no results message
  ///
  /// In en, this message translates to:
  /// **'No recipes found'**
  String get recipePinnedNoResults;

  /// Pantry matches page title
  ///
  /// In en, this message translates to:
  /// **'Pantry Matches'**
  String get recipeMatchTitle;

  /// Summary of pantry matches
  ///
  /// In en, this message translates to:
  /// **'Pantry matches: {matched} of {total} ingredients'**
  String recipeMatchSummary(int matched, int total);

  /// Matched pantry item label
  ///
  /// In en, this message translates to:
  /// **'Matched with: {name}'**
  String recipeMatchMatchedWith(String name);

  /// Matching terms section title
  ///
  /// In en, this message translates to:
  /// **'Matching Terms'**
  String get recipeMatchTermsTitle;

  /// Add term tooltip
  ///
  /// In en, this message translates to:
  /// **'Add New Term'**
  String get recipeMatchAddTerm;

  /// Message when no terms exist
  ///
  /// In en, this message translates to:
  /// **'No additional terms for this ingredient. Add terms to improve pantry matching.'**
  String get recipeMatchNoTerms;

  /// Helpful tip for adding terms
  ///
  /// In en, this message translates to:
  /// **'Tip: Add terms that match pantry item names to improve matching.'**
  String get recipeMatchTip;

  /// Term source label
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String recipeMatchSource(String source);

  /// Add term dialog title
  ///
  /// In en, this message translates to:
  /// **'Add Matching Term'**
  String get recipeMatchAddTermTitle;

  /// Term input label
  ///
  /// In en, this message translates to:
  /// **'Term'**
  String get recipeMatchTermLabel;

  /// Term input hint
  ///
  /// In en, this message translates to:
  /// **'Enter a matching term (e.g., pantry item name)'**
  String get recipeMatchTermHint;

  /// Recipe title placeholder
  ///
  /// In en, this message translates to:
  /// **'Recipe Title'**
  String get recipeEditorRecipeTitle;

  /// Description field placeholder
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get recipeEditorDescriptionOptional;

  /// Prep time placeholder
  ///
  /// In en, this message translates to:
  /// **'Prep Time'**
  String get recipeEditorPrepTime;

  /// Cook time placeholder
  ///
  /// In en, this message translates to:
  /// **'Cook Time'**
  String get recipeEditorCookTime;

  /// Servings placeholder
  ///
  /// In en, this message translates to:
  /// **'Servings'**
  String get recipeEditorServings;

  /// Folders label
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get recipeEditorFolders;

  /// No folders selected
  ///
  /// In en, this message translates to:
  /// **'No folders'**
  String get recipeEditorNoFolders;

  /// One folder selected
  ///
  /// In en, this message translates to:
  /// **'1 folder'**
  String get recipeEditorOneFolder;

  /// Number of folders selected
  ///
  /// In en, this message translates to:
  /// **'{count} folders'**
  String recipeEditorFolderCount(int count);

  /// Take photo option
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get recipeEditorTakePhoto;

  /// Choose from gallery option
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get recipeEditorChooseFromGallery;

  /// Delete image dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Image'**
  String get recipeEditorDeleteImage;

  /// Delete image confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this image?'**
  String get recipeEditorDeleteImageConfirm;

  /// Tags section label
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get recipeEditorTags;

  /// Edit tags button
  ///
  /// In en, this message translates to:
  /// **'Edit Tags'**
  String get recipeEditorEditTags;

  /// No tags assigned message
  ///
  /// In en, this message translates to:
  /// **'No tags assigned'**
  String get recipeEditorNoTagsAssigned;

  /// Placeholder for empty input fields
  ///
  /// In en, this message translates to:
  /// **'Enter value'**
  String get commonEnterValue;

  /// Update button
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get commonUpdate;

  /// Duration picker title
  ///
  /// In en, this message translates to:
  /// **'Select Duration'**
  String get durationPickerTitle;

  /// Hours label in duration picker
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get durationPickerHours;

  /// Minutes label in duration picker
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get durationPickerMinutes;

  /// Seconds label in duration picker
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get durationPickerSeconds;

  /// Name for the uncategorized folder
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get folderUncategorized;

  /// Text shown when folder has no recipes
  ///
  /// In en, this message translates to:
  /// **'no recipes'**
  String get folderNoRecipes;

  /// Text shown when folder has one recipe
  ///
  /// In en, this message translates to:
  /// **'1 recipe'**
  String get folderOneRecipe;

  /// Text shown for recipe count in folder
  ///
  /// In en, this message translates to:
  /// **'{count} recipes'**
  String folderRecipeCount(int count);

  /// Rename folder menu item
  ///
  /// In en, this message translates to:
  /// **'Rename Folder'**
  String get folderRename;

  /// Edit smart folder menu item
  ///
  /// In en, this message translates to:
  /// **'Edit Smart Folder'**
  String get folderEditSmart;

  /// Delete folder menu item
  ///
  /// In en, this message translates to:
  /// **'Delete Folder'**
  String get folderDelete;

  /// View all button text
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get commonViewAll;

  /// Search placeholder text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// Search placeholder when search is active
  ///
  /// In en, this message translates to:
  /// **'Enter search text'**
  String get commonSearchActive;

  /// Message when search returns no results
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get commonNoSearchResults;

  /// Generic no results message
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get commonNoResults;

  /// Recently viewed section title
  ///
  /// In en, this message translates to:
  /// **'Recently Viewed'**
  String get recipeRecentlyViewedTitle;

  /// Empty state message for recently viewed
  ///
  /// In en, this message translates to:
  /// **'No recently viewed recipes yet.\nStart exploring recipes to see them here.'**
  String get recipeRecentlyViewedEmpty;

  /// Short format for minutes duration
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String durationMinutesShort(int count);

  /// Short format for hours duration
  ///
  /// In en, this message translates to:
  /// **'{count} hr'**
  String durationHoursShort(int count);

  /// Short format for hours and minutes duration
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHoursMinutesShort(int hours, int minutes);

  /// Servings count for recipe cards
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 serving} other{{count} servings}}'**
  String recipeServingsCount(int count);

  /// Servings label in recipe metadata
  ///
  /// In en, this message translates to:
  /// **'Servings'**
  String get recipeMetadataServings;

  /// Prep time label in recipe metadata
  ///
  /// In en, this message translates to:
  /// **'Prep Time'**
  String get recipeMetadataPrepTime;

  /// Cook time label in recipe metadata
  ///
  /// In en, this message translates to:
  /// **'Cook Time'**
  String get recipeMetadataCookTime;

  /// Total time label in recipe metadata
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get recipeMetadataTotal;

  /// Rating label in recipe metadata
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get recipeMetadataRating;

  /// Notes section heading in recipe view
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get recipeMetadataNotes;

  /// Source label with value in recipe view
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String recipeMetadataSource(String source);

  /// Source label prefix for URL sources
  ///
  /// In en, this message translates to:
  /// **'Source: '**
  String get recipeMetadataSourceLabel;

  /// Start cooking button text
  ///
  /// In en, this message translates to:
  /// **'Start Cooking'**
  String get recipeCookStartCooking;

  /// Resume cooking button text
  ///
  /// In en, this message translates to:
  /// **'Resume Cooking'**
  String get recipeCookResumeCooking;

  /// Edit recipe menu item on recipe page
  ///
  /// In en, this message translates to:
  /// **'Edit Recipe'**
  String get recipePageEditRecipe;

  /// Check pantry stock menu item on recipe page
  ///
  /// In en, this message translates to:
  /// **'Check Pantry Stock'**
  String get recipePageCheckPantryStock;

  /// Reset button in scale/convert panel
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get scaleConvertReset;

  /// Scale row label
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get scaleConvertScale;

  /// Convert row label
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get scaleConvertConvert;

  /// Ingredient row label and scale type
  ///
  /// In en, this message translates to:
  /// **'Ingredient'**
  String get scaleConvertIngredient;

  /// Placeholder for ingredient selector
  ///
  /// In en, this message translates to:
  /// **'Select ingredient'**
  String get scaleConvertSelectIngredient;

  /// Amount scale type option
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get scaleTypeAmount;

  /// Servings scale type option
  ///
  /// In en, this message translates to:
  /// **'Servings'**
  String get scaleTypeServings;

  /// Slider label for amount scale
  ///
  /// In en, this message translates to:
  /// **'Amount: {value}x'**
  String scaleSliderAmount(String value);

  /// Slider label for servings scale
  ///
  /// In en, this message translates to:
  /// **'Servings: {count}'**
  String scaleSliderServings(int count);

  /// Slider label for ingredient amount
  ///
  /// In en, this message translates to:
  /// **'Amount: {value}'**
  String scaleSliderIngredientAmount(String value);

  /// Original conversion mode option
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get conversionModeOriginal;

  /// Imperial conversion mode option
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get conversionModeImperial;

  /// Metric conversion mode option
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get conversionModeMetric;

  /// Step progress indicator in cook modal
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String cookStepProgress(int current, int total);

  /// Percentage complete indicator for cook session
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String cookPercentComplete(int percent);

  /// Error message when recipe cannot be found
  ///
  /// In en, this message translates to:
  /// **'Recipe not found'**
  String get cookRecipeNotFound;

  /// Validation error when trying to cook a recipe without steps
  ///
  /// In en, this message translates to:
  /// **'This recipe doesn\'t have any cooking steps yet. Please add steps to this recipe before starting a cook session.'**
  String get cookNoStepsValidation;

  /// Title for ingredients sheet in cook modal
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredientsSheetTitle;

  /// Button text to expand scale/convert panel
  ///
  /// In en, this message translates to:
  /// **'Scale or Convert'**
  String get ingredientsSheetScaleConvert;

  /// Title for start timer confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Start Timer?'**
  String get timerStartTitle;

  /// Confirmation message for starting a timer
  ///
  /// In en, this message translates to:
  /// **'Start a {duration} timer for\n{recipeName}\nStep {stepNumber} of {totalSteps}'**
  String timerStartMessage(
      String duration, String recipeName, int stepNumber, int totalSteps);

  /// Start button for timer dialog
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get timerStart;

  /// Error message when timer fails to start
  ///
  /// In en, this message translates to:
  /// **'Failed to start timer. Please try again.'**
  String get timerStartFailed;

  /// Title for notification permission dialog
  ///
  /// In en, this message translates to:
  /// **'Enable Timer Notifications'**
  String get timerNotificationsTitle;

  /// Explanation for notification permission
  ///
  /// In en, this message translates to:
  /// **'Get notified when your cooking timers are done, even when the app is in the background.'**
  String get timerNotificationsMessage;

  /// Decline button for notification permission
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get timerNotificationsNotNow;

  /// Enable button for notification permission
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get timerNotificationsEnable;

  /// Header label when cooking is active
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get statusBarCooking;

  /// Count of recipes being cooked
  ///
  /// In en, this message translates to:
  /// **'{count} recipes'**
  String statusBarRecipesCount(int count);

  /// Button to show cooking instructions
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get statusBarInstructions;

  /// Button to view recipe
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get statusBarRecipe;

  /// Title for complete cook confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Complete Cook?'**
  String get statusBarCompleteCookTitle;

  /// Message for complete cook confirmation
  ///
  /// In en, this message translates to:
  /// **'Mark \"{recipeName}\" as complete?'**
  String statusBarCompleteCookMessage(String recipeName);

  /// Button to complete cooking
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get statusBarComplete;

  /// Timer section header
  ///
  /// In en, this message translates to:
  /// **'Timers'**
  String get statusBarTimers;

  /// Timer step display
  ///
  /// In en, this message translates to:
  /// **'Step {stepDisplay}'**
  String statusBarTimerStep(String stepDisplay);

  /// Timer action sheet message
  ///
  /// In en, this message translates to:
  /// **'Step {stepDisplay} · {detectedText}'**
  String statusBarTimerSheetMessage(String stepDisplay, String detectedText);

  /// Extend timer by 1 minute option
  ///
  /// In en, this message translates to:
  /// **'Extend 1 min'**
  String get statusBarExtend1Min;

  /// Extend timer by 5 minutes option
  ///
  /// In en, this message translates to:
  /// **'Extend 5 min'**
  String get statusBarExtend5Min;

  /// View recipe option in timer menu
  ///
  /// In en, this message translates to:
  /// **'View Recipe'**
  String get statusBarViewRecipe;

  /// Cancel timer option
  ///
  /// In en, this message translates to:
  /// **'Cancel Timer'**
  String get statusBarCancelTimer;

  /// Cancel timer confirmation title
  ///
  /// In en, this message translates to:
  /// **'Cancel Timer?'**
  String get statusBarCancelTimerTitle;

  /// Cancel timer confirmation message
  ///
  /// In en, this message translates to:
  /// **'Cancel the {detectedText} timer for \"{recipeName}\"?'**
  String statusBarCancelTimerMessage(String detectedText, String recipeName);

  /// Keep timer button
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get statusBarKeep;

  /// Title for ingredient matches bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Recipe Ingredients'**
  String get ingredientMatchTitle;

  /// Status when all ingredients are available
  ///
  /// In en, this message translates to:
  /// **'All {count} ingredients available'**
  String ingredientMatchAllAvailable(int count);

  /// Status showing available vs total items
  ///
  /// In en, this message translates to:
  /// **'{available} of {total} items available'**
  String ingredientMatchAvailableOf(int available, int total);

  /// Count of out of stock items
  ///
  /// In en, this message translates to:
  /// **'{count} out of stock'**
  String ingredientMatchOutOfStock(int count);

  /// Count of items not in pantry
  ///
  /// In en, this message translates to:
  /// **'{count} not in pantry'**
  String ingredientMatchNotInPantry(int count);

  /// Button text with item count for adding to shopping list
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 Item} other{Add {count} Items}}'**
  String ingredientMatchAddItemsButton(int count);

  /// Default button text when no items selected
  ///
  /// In en, this message translates to:
  /// **'Add Items'**
  String get ingredientMatchAddItemsDefault;

  /// Button and title for manage lists page
  ///
  /// In en, this message translates to:
  /// **'Manage Lists'**
  String get ingredientMatchManageLists;

  /// Title for create new list page
  ///
  /// In en, this message translates to:
  /// **'Create New List'**
  String get ingredientMatchCreateNewList;

  /// Label showing item is already in a shopping list
  ///
  /// In en, this message translates to:
  /// **'In {listName}'**
  String ingredientMatchInList(String listName);

  /// Label showing pantry item match
  ///
  /// In en, this message translates to:
  /// **'Matches with pantry item {name}'**
  String ingredientMatchMatchesWith(String name);

  /// Prefix for linked recipe when all ingredients available
  ///
  /// In en, this message translates to:
  /// **'You have everything to make '**
  String get ingredientMatchEverythingToMake;

  /// Prefix for linked recipe when ingredients missing
  ///
  /// In en, this message translates to:
  /// **'Missing ingredients for '**
  String get ingredientMatchMissingFor;

  /// Explainer text for linked recipe ingredients
  ///
  /// In en, this message translates to:
  /// **'This ingredient is linked to a recipe. However, if any of the terms below match items in your pantry, those will be used instead of making the recipe.'**
  String get ingredientMatchLinkedExplainer;

  /// Button to add a matching term
  ///
  /// In en, this message translates to:
  /// **'Add Term'**
  String get ingredientMatchAddTermButton;

  /// Action sheet message for adding term options
  ///
  /// In en, this message translates to:
  /// **'Choose an option to add a matching term'**
  String get ingredientMatchChooseOption;

  /// Option to enter a custom matching term
  ///
  /// In en, this message translates to:
  /// **'Enter Custom Term'**
  String get ingredientMatchEnterCustomTerm;

  /// Option to select from pantry items
  ///
  /// In en, this message translates to:
  /// **'Select from Pantry'**
  String get ingredientMatchSelectFromPantry;

  /// Description for custom term option
  ///
  /// In en, this message translates to:
  /// **'Enter a new term for matching'**
  String get ingredientMatchEnterNewTermDesc;

  /// Description for pantry selection option
  ///
  /// In en, this message translates to:
  /// **'Use an existing pantry item name'**
  String get ingredientMatchUsePantryItemDesc;

  /// Title for add term page
  ///
  /// In en, this message translates to:
  /// **'Add Term for \"{name}\"'**
  String ingredientMatchAddTermFor(String name);

  /// Placeholder for term input field
  ///
  /// In en, this message translates to:
  /// **'Enter matching term'**
  String get ingredientMatchEnterTermPlaceholder;

  /// Title for pantry selection page
  ///
  /// In en, this message translates to:
  /// **'Select Item for \"{name}\"'**
  String ingredientMatchSelectItemFor(String name);

  /// Placeholder for pantry search field
  ///
  /// In en, this message translates to:
  /// **'Search pantry items...'**
  String get ingredientMatchSearchPantry;

  /// Empty state when no pantry items exist
  ///
  /// In en, this message translates to:
  /// **'No pantry items found'**
  String get ingredientMatchNoPantryItems;

  /// Hint to add items in pantry tab
  ///
  /// In en, this message translates to:
  /// **'Add items in the Pantry tab'**
  String get ingredientMatchAddInPantryTab;

  /// Empty state when search returns no results
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get ingredientMatchNoItemsFound;

  /// Hint when search returns no results
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get ingredientMatchTryDifferentSearch;

  /// Button text to create a new shopping list
  ///
  /// In en, this message translates to:
  /// **'Create New List'**
  String get shoppingListCreateNew;

  /// Empty state when no shopping lists exist
  ///
  /// In en, this message translates to:
  /// **'No shopping lists yet'**
  String get shoppingListNoLists;

  /// Title for delete list confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete List'**
  String get shoppingListDeleteTitle;

  /// Confirmation message for deleting a shopping list
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? All items in this list will also be deleted.'**
  String shoppingListDeleteConfirm(String name);

  /// Fallback name for unnamed shopping lists
  ///
  /// In en, this message translates to:
  /// **'Unnamed List'**
  String get shoppingListUnnamed;

  /// Label for list name input field
  ///
  /// In en, this message translates to:
  /// **'List Name'**
  String get shoppingListNameLabel;

  /// Placeholder for list name input field
  ///
  /// In en, this message translates to:
  /// **'Enter list name'**
  String get shoppingListNamePlaceholder;

  /// Button text to create a shopping list
  ///
  /// In en, this message translates to:
  /// **'Create List'**
  String get shoppingListCreateButton;

  /// Shopping list page title
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get shoppingListPageTitle;

  /// Empty state message when shopping list has no items
  ///
  /// In en, this message translates to:
  /// **'No items in this shopping list yet.'**
  String get shoppingListEmptyState;

  /// Call to action to add first item
  ///
  /// In en, this message translates to:
  /// **'Add your first item'**
  String get shoppingListAddFirstItem;

  /// Button to manage shopping lists
  ///
  /// In en, this message translates to:
  /// **'Manage Lists'**
  String get shoppingListManageLists;

  /// Button to add a shopping list item
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get shoppingListAddItem;

  /// Menu option to clear all items
  ///
  /// In en, this message translates to:
  /// **'Clear All Items'**
  String get shoppingListClearAll;

  /// Dialog title when no items to clear
  ///
  /// In en, this message translates to:
  /// **'No Items'**
  String get shoppingListNoItemsTitle;

  /// Message when no items to clear
  ///
  /// In en, this message translates to:
  /// **'There are no items to clear.'**
  String get shoppingListNoItemsMessage;

  /// Confirmation message for clearing all items
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all {count} {count, plural, =1{item} other{items}} from this list?'**
  String shoppingListClearAllConfirm(int count);

  /// Dialog title when cannot delete default list
  ///
  /// In en, this message translates to:
  /// **'Cannot Delete'**
  String get shoppingListCannotDeleteTitle;

  /// Message explaining default list cannot be deleted
  ///
  /// In en, this message translates to:
  /// **'The default shopping list cannot be deleted.'**
  String get shoppingListCannotDeleteMessage;

  /// Title for shopping list selection modal
  ///
  /// In en, this message translates to:
  /// **'Select Shopping List'**
  String get shoppingListSelectTitle;

  /// Title for manage shopping lists modal
  ///
  /// In en, this message translates to:
  /// **'Manage Shopping Lists'**
  String get shoppingListManageTitle;

  /// Dialog title for creating new list
  ///
  /// In en, this message translates to:
  /// **'New Shopping List'**
  String get shoppingListNewListTitle;

  /// Short create button text
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get shoppingListCreate;

  /// Modal title for adding shopping list item
  ///
  /// In en, this message translates to:
  /// **'Add Shopping List Item'**
  String get shoppingListAddItemTitle;

  /// Placeholder for item name input
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get shoppingListItemPlaceholder;

  /// Section header for previously added items
  ///
  /// In en, this message translates to:
  /// **'Previously Added'**
  String get shoppingListPreviouslyAdded;

  /// Undo button text
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get shoppingListUndo;

  /// Dialog title for deleting an item
  ///
  /// In en, this message translates to:
  /// **'Delete Item'**
  String get shoppingListDeleteItemTitle;

  /// Confirmation message for deleting an item
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String shoppingListDeleteItemConfirm(String name);

  /// FAB label for bulk actions on marked items
  ///
  /// In en, this message translates to:
  /// **'With marked…'**
  String get shoppingListBulkLabel;

  /// Action sheet title for bulk actions
  ///
  /// In en, this message translates to:
  /// **'Actions for {count} marked items'**
  String shoppingListBulkTitle(int count);

  /// Bulk action to update pantry
  ///
  /// In en, this message translates to:
  /// **'Update Pantry'**
  String get shoppingListBulkUpdatePantry;

  /// Bulk action to unmark items
  ///
  /// In en, this message translates to:
  /// **'Un-mark'**
  String get shoppingListBulkUnmark;

  /// Title when all pantry items are up to date
  ///
  /// In en, this message translates to:
  /// **'Nothing to update'**
  String get shoppingListPantryNothingToUpdate;

  /// Message when all pantry items are up to date
  ///
  /// In en, this message translates to:
  /// **'All items are already in your pantry\nand marked as in stock.'**
  String get shoppingListPantryNothingMessage;

  /// Section header for items to add to pantry
  ///
  /// In en, this message translates to:
  /// **'Items to add'**
  String get shoppingListPantryItemsToAdd;

  /// Section header for items to update in pantry
  ///
  /// In en, this message translates to:
  /// **'Items to update'**
  String get shoppingListPantryItemsToUpdate;

  /// Button text to update pantry with count
  ///
  /// In en, this message translates to:
  /// **'Update Pantry ({count})'**
  String shoppingListPantryUpdateButton(int count);

  /// Button text to update pantry without count
  ///
  /// In en, this message translates to:
  /// **'Update Pantry'**
  String get shoppingListPantryUpdateButtonEmpty;

  /// Error message when pantry fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading pantry: {error}'**
  String shoppingListErrorLoading(String error);

  /// Short placeholder for list name in dialog
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get shoppingListListNamePlaceholder;

  /// Short label for out of stock status
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get stockStatusOut;

  /// Short label for low stock status
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get stockStatusLow;

  /// Full label for low stock status
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get stockStatusLowStock;

  /// Label for in stock status
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get stockStatusInStock;

  /// Label for new pantry items
  ///
  /// In en, this message translates to:
  /// **'New item'**
  String get stockStatusNewItem;

  /// Label for items not found in pantry
  ///
  /// In en, this message translates to:
  /// **'Not in Pantry'**
  String get stockStatusNotInPantry;

  /// Title for the meal plans page
  ///
  /// In en, this message translates to:
  /// **'Meal Plans'**
  String get mealPlanPageTitle;

  /// Add recipe menu item
  ///
  /// In en, this message translates to:
  /// **'Add Recipe'**
  String get mealPlanAddRecipe;

  /// Add note menu item and modal title
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get mealPlanAddNote;

  /// Clear items menu item and dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear Items'**
  String get mealPlanClearItems;

  /// Clear items confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all recipes and notes from this day?'**
  String get mealPlanClearItemsConfirm;

  /// View recipe context menu action
  ///
  /// In en, this message translates to:
  /// **'View Recipe'**
  String get mealPlanViewRecipe;

  /// Edit note context menu action and dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get mealPlanEditNote;

  /// Remove item context menu action
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get mealPlanRemove;

  /// Placeholder message for edit note dialog
  ///
  /// In en, this message translates to:
  /// **'Note editing will be implemented'**
  String get mealPlanEditNotePlaceholder;

  /// Placeholder for note text field
  ///
  /// In en, this message translates to:
  /// **'Enter your note...'**
  String get mealPlanNotePlaceholder;

  /// Error message when adding note fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add note: {message}'**
  String mealPlanFailedToAddNote(String message);

  /// Title for meal plan actions sheet
  ///
  /// In en, this message translates to:
  /// **'Meal Plan Actions'**
  String get mealPlanActionsTitle;

  /// Title for add to meal plan action sheet
  ///
  /// In en, this message translates to:
  /// **'Add to Meal Plan'**
  String get mealPlanAddToMealPlanTitle;

  /// Empty state when no recipes match search
  ///
  /// In en, this message translates to:
  /// **'No recipes found'**
  String get mealPlanNoRecipesFound;

  /// Suggestion when no recipes found
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get mealPlanTryDifferentSearch;

  /// Recipe servings label
  ///
  /// In en, this message translates to:
  /// **'{count} servings'**
  String mealPlanServings(int count);

  /// Indicator that ingredient is already on shopping list
  ///
  /// In en, this message translates to:
  /// **'Already on shopping list'**
  String get mealPlanAlreadyOnShoppingList;

  /// Message when all ingredients are available
  ///
  /// In en, this message translates to:
  /// **'All ingredients are in your pantry or already on a shopping list.'**
  String get mealPlanAllIngredientsInPantry;

  /// Placeholder text for discover sub page
  ///
  /// In en, this message translates to:
  /// **'Discover Sub Page'**
  String get mealPlanDiscoverSubPage;

  /// Date header for today's meal plan
  ///
  /// In en, this message translates to:
  /// **'Today, {date}'**
  String mealPlanTodayDate(String date);

  /// Date header for tomorrow's meal plan
  ///
  /// In en, this message translates to:
  /// **'Tomorrow, {date}'**
  String mealPlanTomorrowDate(String date);

  /// Fallback title for recipe with missing title
  ///
  /// In en, this message translates to:
  /// **'Unknown Recipe'**
  String get mealPlanUnknownRecipe;

  /// Fallback title for note with missing text
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get mealPlanNoteDefault;

  /// Fallback title for unknown item type
  ///
  /// In en, this message translates to:
  /// **'Unknown Item'**
  String get mealPlanUnknownItem;

  /// Empty state title for date card with no items
  ///
  /// In en, this message translates to:
  /// **'No meals planned'**
  String get mealPlanNoMealsPlanned;

  /// Empty state hint for date card with no items
  ///
  /// In en, this message translates to:
  /// **'Tap + to add recipes or notes'**
  String get mealPlanTapToAdd;

  /// Error message when meal plan fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading meal plan: {error}'**
  String mealPlanErrorLoading(String error);

  /// Pantry page title
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get pantryTitle;

  /// Filter and sort button text
  ///
  /// In en, this message translates to:
  /// **'Filter and Sort'**
  String get pantryFilterAndSort;

  /// Add item button text
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get pantryAddItem;

  /// Empty state when filters exclude all items
  ///
  /// In en, this message translates to:
  /// **'No pantry items match the current filters'**
  String get pantryNoItemsMatchFilters;

  /// Empty state when pantry is empty
  ///
  /// In en, this message translates to:
  /// **'No pantry items yet. Tap the + button to add items.'**
  String get pantryNoItemsYet;

  /// Clear filters button text
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get pantryClearFilters;

  /// Add pantry item menu option
  ///
  /// In en, this message translates to:
  /// **'Add Pantry Item'**
  String get pantryAddPantryItem;

  /// Add pantry items modal title
  ///
  /// In en, this message translates to:
  /// **'Add Pantry Items'**
  String get pantryAddItemsTitle;

  /// Item name field placeholder
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get pantryItemNamePlaceholder;

  /// Previously added section header
  ///
  /// In en, this message translates to:
  /// **'Previously Added'**
  String get pantryPreviouslyAdded;

  /// Undo button text
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get pantryUndo;

  /// Status label
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get pantryStatusLabel;

  /// Help text in add pantry item modal
  ///
  /// In en, this message translates to:
  /// **'Items are added with \"In Stock\" status by default. You can change the status above or edit items later for more details.'**
  String get pantryAddHelpText;

  /// Edit pantry item modal title
  ///
  /// In en, this message translates to:
  /// **'Edit Pantry Item'**
  String get pantryEditTitle;

  /// Pantry item name field placeholder
  ///
  /// In en, this message translates to:
  /// **'Pantry Item Name'**
  String get pantryItemNameFieldPlaceholder;

  /// Stock status section label
  ///
  /// In en, this message translates to:
  /// **'Stock Status'**
  String get pantryStockStatusLabel;

  /// Mark as staple toggle label
  ///
  /// In en, this message translates to:
  /// **'Mark as staple'**
  String get pantryMarkAsStaple;

  /// Staple toggle description
  ///
  /// In en, this message translates to:
  /// **'Staples are assumed to always be in stock'**
  String get pantryStapleDescription;

  /// Matching terms section header
  ///
  /// In en, this message translates to:
  /// **'Matching Terms'**
  String get pantryMatchingTerms;

  /// Add term button text
  ///
  /// In en, this message translates to:
  /// **'Add Term'**
  String get pantryAddTerm;

  /// Empty state for terms list
  ///
  /// In en, this message translates to:
  /// **'No additional terms for this item. Add terms to improve recipe matching.'**
  String get pantryNoTermsMessage;

  /// Term source label
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String pantryTermSource(String source);

  /// Tip for adding terms
  ///
  /// In en, this message translates to:
  /// **'Tip: Add terms that match recipe ingredients to improve matching.'**
  String get pantryTermTip;

  /// Add term page title
  ///
  /// In en, this message translates to:
  /// **'Add Term for \"{name}\"'**
  String pantryAddTermFor(String name);

  /// Matching term field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter matching term'**
  String get pantryEnterMatchingTerm;

  /// Reset all filters button
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get pantryResetAll;

  /// Apply changes button
  ///
  /// In en, this message translates to:
  /// **'Apply Changes'**
  String get pantryApplyChanges;

  /// Sort section header
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get pantrySortHeader;

  /// Sort by label
  ///
  /// In en, this message translates to:
  /// **'Sort by {option}'**
  String pantrySortBy(String option);

  /// Ascending sort indicator
  ///
  /// In en, this message translates to:
  /// **'A-Z'**
  String get pantrySortAZ;

  /// Descending sort indicator
  ///
  /// In en, this message translates to:
  /// **'Z-A'**
  String get pantrySortZA;

  /// Sort by category option
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get pantrySortCategory;

  /// Sort alphabetically option
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get pantrySortAlphabetical;

  /// Sort by date added option
  ///
  /// In en, this message translates to:
  /// **'Date Added'**
  String get pantrySortDateAdded;

  /// Sort by date modified option
  ///
  /// In en, this message translates to:
  /// **'Date Modified'**
  String get pantrySortDateModified;

  /// Sort by stock status option
  ///
  /// In en, this message translates to:
  /// **'Stock Status'**
  String get pantrySortStockStatus;

  /// Category filter section header
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get pantryCategoryHeader;

  /// Other category fallback
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get pantryCategoryOther;

  /// Empty state for categories
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get pantryCategoryNone;

  /// Stock status filter section header
  ///
  /// In en, this message translates to:
  /// **'Stock Status'**
  String get pantryStockStatusHeader;

  /// Out of stock status label
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get pantryStockOutOfStock;

  /// Low stock status label
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get pantryStockLowStock;

  /// In stock status label
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get pantryStockInStock;

  /// Show staples section header
  ///
  /// In en, this message translates to:
  /// **'Show Staples'**
  String get pantryShowStaplesHeader;

  /// Include staple items toggle label
  ///
  /// In en, this message translates to:
  /// **'Include staple items'**
  String get pantryIncludeStapleItems;

  /// Set to out of stock menu option
  ///
  /// In en, this message translates to:
  /// **'Set to Out of Stock'**
  String get pantrySetOutOfStock;

  /// Set to low stock menu option
  ///
  /// In en, this message translates to:
  /// **'Set to Low Stock'**
  String get pantrySetLowStock;

  /// Set to in stock menu option
  ///
  /// In en, this message translates to:
  /// **'Set to In Stock'**
  String get pantrySetInStock;

  /// Edit menu option
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get pantryEdit;

  /// Delete item dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Item'**
  String get pantryDeleteItemTitle;

  /// Delete item confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String pantryDeleteItemMessage(String name);

  /// Delete item error message
  ///
  /// In en, this message translates to:
  /// **'Failed to delete item: {error}'**
  String pantryDeleteFailed(String error);

  /// Selected items count label
  ///
  /// In en, this message translates to:
  /// **'{count} Selected'**
  String pantrySelectedCount(int count);

  /// Items selected action sheet title
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item selected} other{{count} items selected}}'**
  String pantryItemsSelected(int count);

  /// Bulk set to in stock action
  ///
  /// In en, this message translates to:
  /// **'Set All to In-Stock'**
  String get pantrySetAllInStock;

  /// Bulk set to low stock action
  ///
  /// In en, this message translates to:
  /// **'Set All to Low-Stock'**
  String get pantrySetAllLowStock;

  /// Bulk set to out of stock action
  ///
  /// In en, this message translates to:
  /// **'Set All to Out-of-Stock'**
  String get pantrySetAllOutOfStock;

  /// Delete selected items action
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get pantryDeleteSelected;

  /// Delete items dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Items'**
  String get pantryDeleteItemsTitle;

  /// Delete items confirmation message
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Are you sure you want to delete 1 item? This action cannot be undone.} other{Are you sure you want to delete {count} items? This action cannot be undone.}}'**
  String pantryDeleteItemsMessage(int count);

  /// Accessibility label for stock status
  ///
  /// In en, this message translates to:
  /// **'Stock status: {status}'**
  String pantryStockStatusAccessibility(String status);

  /// Accessibility hint for stock status control
  ///
  /// In en, this message translates to:
  /// **'Tap to change stock status'**
  String get pantryTapToChangeStatus;

  /// Pantry details sub-page title
  ///
  /// In en, this message translates to:
  /// **'Pantry Details'**
  String get pantryDetailsTitle;

  /// Placeholder text for pantry sub-page
  ///
  /// In en, this message translates to:
  /// **'This is a pantry sub-page'**
  String get pantrySubPagePlaceholder;

  /// Go back button text
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get pantryGoBack;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get pantrySave;

  /// Clippings page title
  ///
  /// In en, this message translates to:
  /// **'Clippings'**
  String get clippingsTitle;

  /// Empty state message when no clippings exist
  ///
  /// In en, this message translates to:
  /// **'No clippings yet'**
  String get clippingsEmpty;

  /// Hint text in empty state
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add a clipping'**
  String get clippingsEmptyHint;

  /// Empty state when search has no results
  ///
  /// In en, this message translates to:
  /// **'No clippings match your search'**
  String get clippingsNoSearchResults;

  /// Clear search button text
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get clippingsClearSearch;

  /// Menu item to create new clipping
  ///
  /// In en, this message translates to:
  /// **'New Clipping'**
  String get clippingsNewClipping;

  /// Fallback title for untitled clippings
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get clippingsUntitled;

  /// Date group header for today's clippings
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get clippingsToday;

  /// Date group header for last 7 days
  ///
  /// In en, this message translates to:
  /// **'Previous 7 Days'**
  String get clippingsPrevious7Days;

  /// Delete clipping dialog title and menu item
  ///
  /// In en, this message translates to:
  /// **'Delete Clipping'**
  String get clippingsDeleteTitle;

  /// Delete clipping confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this clipping?'**
  String get clippingsDeleteConfirm;

  /// Placeholder for clipping title field
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get clippingsTitlePlaceholder;

  /// Placeholder for clipping content field
  ///
  /// In en, this message translates to:
  /// **'Start typing...'**
  String get clippingsContentPlaceholder;

  /// Button/menu item to convert clipping to recipe
  ///
  /// In en, this message translates to:
  /// **'Convert to Recipe'**
  String get clippingsConvertToRecipe;

  /// Button/menu item to convert clipping to shopping list
  ///
  /// In en, this message translates to:
  /// **'To Shopping List'**
  String get clippingsToShoppingList;

  /// Tooltip for add link button in toolbar
  ///
  /// In en, this message translates to:
  /// **'Add link'**
  String get clippingsAddLinkTooltip;

  /// Add link modal title
  ///
  /// In en, this message translates to:
  /// **'Add Link'**
  String get clippingsLinkAddTitle;

  /// Edit link modal title
  ///
  /// In en, this message translates to:
  /// **'Edit Link'**
  String get clippingsLinkEditTitle;

  /// Link text field label
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get clippingsLinkTextLabel;

  /// Link text field placeholder
  ///
  /// In en, this message translates to:
  /// **'Link text'**
  String get clippingsLinkTextPlaceholder;

  /// Link URL field label
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get clippingsLinkUrlLabel;

  /// Link URL field placeholder
  ///
  /// In en, this message translates to:
  /// **'https://example.com'**
  String get clippingsLinkUrlPlaceholder;

  /// Help modal title
  ///
  /// In en, this message translates to:
  /// **'About Clippings'**
  String get clippingsAboutTitle;

  /// Help section title about clippings
  ///
  /// In en, this message translates to:
  /// **'Your recipe scratchpad'**
  String get clippingsAboutScratchpadTitle;

  /// Help section body about clippings
  ///
  /// In en, this message translates to:
  /// **'Capture recipe ideas from anywhere — websites, messages, photos, or just your own thoughts. No need to format anything perfectly.'**
  String get clippingsAboutScratchpadBody;

  /// Help section title about converting to recipe
  ///
  /// In en, this message translates to:
  /// **'Convert to Recipe'**
  String get clippingsAboutConvertTitle;

  /// Help section body about converting to recipe
  ///
  /// In en, this message translates to:
  /// **'Turn your notes into a complete recipe. We\'ll extract ingredients, steps, cooking times, and more.'**
  String get clippingsAboutConvertBody;

  /// Tip about completing partial recipes
  ///
  /// In en, this message translates to:
  /// **'Have a partial recipe? Add \"Complete this recipe\" to your notes and we\'ll fill in the missing details.'**
  String get clippingsAboutConvertTip;

  /// Help section title about shopping list
  ///
  /// In en, this message translates to:
  /// **'To Shopping List'**
  String get clippingsAboutShoppingTitle;

  /// Help section body about shopping list
  ///
  /// In en, this message translates to:
  /// **'Pull out the items you need to buy. We\'ll organize them by aisle automatically.'**
  String get clippingsAboutShoppingBody;

  /// Error message when no internet connection
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network and try again.'**
  String get clippingsExtractionNoInternet;

  /// Error when recipe extraction fails
  ///
  /// In en, this message translates to:
  /// **'Unable to extract a recipe from this text. Please make sure the text contains recipe information.'**
  String get clippingsExtractionNoRecipe;

  /// Error when no recipe is detected in preview
  ///
  /// In en, this message translates to:
  /// **'Unable to detect a recipe in this text.'**
  String get clippingsExtractionNoRecipeDetected;

  /// Error when no shopping items found
  ///
  /// In en, this message translates to:
  /// **'No shopping list items found in this text.'**
  String get clippingsExtractionNoItems;

  /// Generic extraction failure message
  ///
  /// In en, this message translates to:
  /// **'Failed to process. Please try again.'**
  String get clippingsExtractionFailed;

  /// Loading message during recipe extraction
  ///
  /// In en, this message translates to:
  /// **'Extracting recipe...'**
  String get clippingsExtractionExtractingRecipe;

  /// Loading message during extraction
  ///
  /// In en, this message translates to:
  /// **'Finding the details...'**
  String get clippingsExtractionFindingDetails;

  /// Loading message near end of extraction
  ///
  /// In en, this message translates to:
  /// **'Wrapping up...'**
  String get clippingsExtractionWrappingUp;

  /// Loading message during shopping list extraction
  ///
  /// In en, this message translates to:
  /// **'Extracting items...'**
  String get clippingsExtractionExtractingItems;

  /// Loading message during recipe preview
  ///
  /// In en, this message translates to:
  /// **'Scanning for recipes...'**
  String get clippingsExtractionScanningRecipes;

  /// Loading message during shopping list preview
  ///
  /// In en, this message translates to:
  /// **'Scanning for items...'**
  String get clippingsExtractionScanningItems;

  /// Button loading text when adding items
  ///
  /// In en, this message translates to:
  /// **'Adding...'**
  String get clippingsShoppingAdding;

  /// Add to shopping list modal title
  ///
  /// In en, this message translates to:
  /// **'Add to Shopping List'**
  String get clippingsShoppingAddTitle;

  /// Manage lists button and page title
  ///
  /// In en, this message translates to:
  /// **'Manage Lists'**
  String get clippingsShoppingManageLists;

  /// Create new list page title
  ///
  /// In en, this message translates to:
  /// **'Create New List'**
  String get clippingsShoppingCreateNew;

  /// Empty state title when all items are in lists
  ///
  /// In en, this message translates to:
  /// **'No items to add'**
  String get clippingsShoppingNoItems;

  /// Empty state description when all items are in lists
  ///
  /// In en, this message translates to:
  /// **'All items are already on a shopping list.'**
  String get clippingsShoppingAllInList;

  /// Status text for items already in a shopping list
  ///
  /// In en, this message translates to:
  /// **'Already on shopping list'**
  String get clippingsShoppingAlreadyInList;

  /// Plus subscription badge text
  ///
  /// In en, this message translates to:
  /// **'PLUS'**
  String get clippingsPreviewPlusBadge;

  /// Recipe preview section label
  ///
  /// In en, this message translates to:
  /// **'Recipe Name'**
  String get clippingsPreviewRecipeName;

  /// Recipe preview description section label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get clippingsPreviewDescription;

  /// Recipe preview ingredients section label
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get clippingsPreviewIngredients;

  /// Shopping list preview section label
  ///
  /// In en, this message translates to:
  /// **'Items Found'**
  String get clippingsPreviewItemsFound;

  /// Shopping list preview title
  ///
  /// In en, this message translates to:
  /// **'Convert to Shopping List'**
  String get clippingsPreviewConvertToShoppingList;

  /// Value proposition headline
  ///
  /// In en, this message translates to:
  /// **'We\'ll do the work for you'**
  String get clippingsPreviewValuePropHeadline;

  /// Recipe value proposition item 1
  ///
  /// In en, this message translates to:
  /// **'Turn notes into real recipes'**
  String get clippingsPreviewValuePropRecipe1;

  /// Recipe value proposition item 2
  ///
  /// In en, this message translates to:
  /// **'Auto-extract ingredients and steps'**
  String get clippingsPreviewValuePropRecipe2;

  /// Recipe value proposition item 3
  ///
  /// In en, this message translates to:
  /// **'Complete partial recipes'**
  String get clippingsPreviewValuePropRecipe3;

  /// Recipe value proposition item 4
  ///
  /// In en, this message translates to:
  /// **'Save it to your Library'**
  String get clippingsPreviewValuePropRecipe4;

  /// Shopping list value proposition item 1
  ///
  /// In en, this message translates to:
  /// **'Turn notes into shopping lists'**
  String get clippingsPreviewValuePropShopping1;

  /// Shopping list value proposition item 2
  ///
  /// In en, this message translates to:
  /// **'Auto-categorize items by aisle'**
  String get clippingsPreviewValuePropShopping2;

  /// Shopping list value proposition item 3
  ///
  /// In en, this message translates to:
  /// **'Smart matching with your pantry'**
  String get clippingsPreviewValuePropShopping3;

  /// Shopping list value proposition item 4
  ///
  /// In en, this message translates to:
  /// **'Add everything in one tap'**
  String get clippingsPreviewValuePropShopping4;

  /// Value proposition trailing item
  ///
  /// In en, this message translates to:
  /// **'… and much more!'**
  String get clippingsPreviewValuePropMore;

  /// Subscribe button text
  ///
  /// In en, this message translates to:
  /// **'Unlock with Plus'**
  String get clippingsPreviewUnlockPlus;

  /// Discover page navigation bar title
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// Address bar placeholder text
  ///
  /// In en, this message translates to:
  /// **'Enter URL or search'**
  String get discoverUrlPlaceholder;

  /// Import recipe button text
  ///
  /// In en, this message translates to:
  /// **'Import Recipe'**
  String get discoverImportRecipe;

  /// Error message when user is offline
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Please check your internet connection and try again.'**
  String get discoverErrorOffline;

  /// Error message when page content cannot be read
  ///
  /// In en, this message translates to:
  /// **'Could not read page content. Please try again.'**
  String get discoverErrorNoContent;

  /// Error message when there is no content to extract
  ///
  /// In en, this message translates to:
  /// **'No content available to extract.'**
  String get discoverErrorNoContentAvailable;

  /// Error message when no recipe is found on page
  ///
  /// In en, this message translates to:
  /// **'This page doesn\'t appear to contain recipe information.\n\nTry navigating to a recipe page.'**
  String get discoverErrorNoRecipe;

  /// Error message when Plus is required for extraction
  ///
  /// In en, this message translates to:
  /// **'This page requires Plus subscription for recipe extraction.'**
  String get discoverErrorPlusRequired;

  /// Error message when recipe not found after extraction
  ///
  /// In en, this message translates to:
  /// **'No recipe found on this page.'**
  String get discoverErrorNotFound;

  /// Error message when extraction fails
  ///
  /// In en, this message translates to:
  /// **'Failed to extract recipe. Please try again.'**
  String get discoverErrorFailed;

  /// Importing modal title
  ///
  /// In en, this message translates to:
  /// **'Importing Recipe'**
  String get discoverImporting;

  /// Loading message during extraction
  ///
  /// In en, this message translates to:
  /// **'Extracting recipe...'**
  String get discoverExtracting;

  /// Extraction failed modal title
  ///
  /// In en, this message translates to:
  /// **'Extraction Failed'**
  String get discoverExtractionFailed;

  /// Import failed modal title
  ///
  /// In en, this message translates to:
  /// **'Import Failed'**
  String get discoverImportFailed;

  /// Generic error fallback message
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get discoverErrorGeneric;

  /// Household page title
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get householdTitle;

  /// Leave household dialog title
  ///
  /// In en, this message translates to:
  /// **'Leave Household'**
  String get householdLeaveTitle;

  /// Delete household dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Household'**
  String get householdDeleteTitle;

  /// Transfer ownership modal title
  ///
  /// In en, this message translates to:
  /// **'Transfer Ownership'**
  String get householdTransferOwnershipTitle;

  /// Create household modal title
  ///
  /// In en, this message translates to:
  /// **'Create Household'**
  String get householdCreateTitle;

  /// Join household modal title
  ///
  /// In en, this message translates to:
  /// **'Join Household'**
  String get householdJoinTitle;

  /// Invite member modal title
  ///
  /// In en, this message translates to:
  /// **'Invite Member'**
  String get householdInviteMemberTitle;

  /// Member limit reached dialog title
  ///
  /// In en, this message translates to:
  /// **'Member Limit Reached'**
  String get householdMemberLimitTitle;

  /// Remove member dialog title
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get householdRemoveMemberTitle;

  /// Invite code created dialog title
  ///
  /// In en, this message translates to:
  /// **'Invite Code Created'**
  String get householdInviteCodeCreatedTitle;

  /// Authentication required title
  ///
  /// In en, this message translates to:
  /// **'Authentication Required'**
  String get householdAuthRequiredTitle;

  /// Pending invites section header
  ///
  /// In en, this message translates to:
  /// **'Pending Invites'**
  String get householdPendingInvites;

  /// Pending invitations section header
  ///
  /// In en, this message translates to:
  /// **'Pending Invitations'**
  String get householdPendingInvitations;

  /// Members section header with count
  ///
  /// In en, this message translates to:
  /// **'Members ({count})'**
  String householdMembersCount(int count);

  /// Pending invites section header with count
  ///
  /// In en, this message translates to:
  /// **'Pending Invites ({count})'**
  String householdPendingInvitesCount(int count);

  /// Select new owner section header
  ///
  /// In en, this message translates to:
  /// **'Select new owner'**
  String get householdSelectNewOwner;

  /// Delete household confirmation message
  ///
  /// In en, this message translates to:
  /// **'Since you are the only member, this will delete the household. Your shared data will become personal data. This cannot be undone.'**
  String get householdDeleteMessage;

  /// Authentication required message
  ///
  /// In en, this message translates to:
  /// **'Please sign in to access household sharing features'**
  String get householdAuthRequiredMessage;

  /// Empty state description when no household
  ///
  /// In en, this message translates to:
  /// **'Share recipes and collaborate with your household'**
  String get householdEmptyDescription;

  /// Leave household confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this household?'**
  String get householdLeaveConfirmation;

  /// Transfer ownership explanation
  ///
  /// In en, this message translates to:
  /// **'As the owner, you must transfer ownership to another member before leaving.'**
  String get householdTransferOwnershipMessage;

  /// Member limit reached message
  ///
  /// In en, this message translates to:
  /// **'Households can have a maximum of 10 members. Remove a member or revoke a pending invite to add someone new.'**
  String get householdMemberLimitMessage;

  /// Remove member confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {name} from the household?'**
  String householdRemoveMemberConfirmation(String name);

  /// Create household instruction
  ///
  /// In en, this message translates to:
  /// **'Enter a name for your household'**
  String get householdEnterName;

  /// Join with code instruction
  ///
  /// In en, this message translates to:
  /// **'Enter the invitation code'**
  String get householdEnterInviteCode;

  /// Invite method selection instruction
  ///
  /// In en, this message translates to:
  /// **'Choose how to invite a new member'**
  String get householdChooseInviteMethod;

  /// Email invite description
  ///
  /// In en, this message translates to:
  /// **'An invitation email will be sent to this address'**
  String get householdEmailInviteDescription;

  /// Code invite description
  ///
  /// In en, this message translates to:
  /// **'A shareable invitation code will be generated'**
  String get householdCodeInviteDescription;

  /// Share invite URL instruction
  ///
  /// In en, this message translates to:
  /// **'Share this URL with the person you want to invite:'**
  String get householdShareInviteUrl;

  /// Household name input placeholder
  ///
  /// In en, this message translates to:
  /// **'Household name'**
  String get householdNamePlaceholder;

  /// Invitation code input placeholder
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get householdInviteCodePlaceholder;

  /// Email address input placeholder
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get householdEmailPlaceholder;

  /// Display name input placeholder
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get householdDisplayNamePlaceholder;

  /// Create household button text
  ///
  /// In en, this message translates to:
  /// **'Create Household'**
  String get householdCreateButton;

  /// Join household button text
  ///
  /// In en, this message translates to:
  /// **'Join Household'**
  String get householdJoinButton;

  /// Join with code button text
  ///
  /// In en, this message translates to:
  /// **'Join with Code'**
  String get householdJoinWithCodeButton;

  /// Leave button text
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get householdLeaveButton;

  /// Transfer ownership and leave button text
  ///
  /// In en, this message translates to:
  /// **'Transfer & Leave'**
  String get householdTransferLeaveButton;

  /// Transferring in progress button text
  ///
  /// In en, this message translates to:
  /// **'Transferring...'**
  String get householdTransferringButton;

  /// Send invitation button text
  ///
  /// In en, this message translates to:
  /// **'Send Invitation'**
  String get householdSendInvitationButton;

  /// Generate code button text
  ///
  /// In en, this message translates to:
  /// **'Generate Code'**
  String get householdGenerateCodeButton;

  /// Copy and close button text
  ///
  /// In en, this message translates to:
  /// **'Copy & Close'**
  String get householdCopyCloseButton;

  /// Accept invite button text
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get householdAcceptButton;

  /// Accepting in progress button text
  ///
  /// In en, this message translates to:
  /// **'Accepting...'**
  String get householdAcceptingButton;

  /// Decline invite button text
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get householdDeclineButton;

  /// Resend invite button text
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get householdResendButton;

  /// Revoke invite button text
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get householdRevokeButton;

  /// Remove member button text
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get householdRemoveButton;

  /// Email invite segment label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get householdInviteEmail;

  /// Code invite segment label
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get householdInviteCode;

  /// Pending status badge
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get householdStatusPending;

  /// Accepted status badge
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get householdStatusAccepted;

  /// Declined status badge
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get householdStatusDeclined;

  /// Revoked status badge
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get householdStatusRevoked;

  /// Accepting in progress status
  ///
  /// In en, this message translates to:
  /// **'Accepting...'**
  String get householdStatusAccepting;

  /// Revoking in progress status
  ///
  /// In en, this message translates to:
  /// **'Revoking...'**
  String get householdStatusRevoking;

  /// Owner badge text
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get householdOwnerBadge;

  /// Household created success message
  ///
  /// In en, this message translates to:
  /// **'Household \"{name}\" has been created successfully!'**
  String householdCreatedSuccess(String name);

  /// Household joined success message
  ///
  /// In en, this message translates to:
  /// **'You have successfully joined the household!'**
  String get householdJoinedSuccess;

  /// Household left success message
  ///
  /// In en, this message translates to:
  /// **'You have successfully left the household.'**
  String get householdLeftSuccess;

  /// Ownership transferred and left success message
  ///
  /// In en, this message translates to:
  /// **'You have successfully left the household and transferred ownership.'**
  String get householdTransferredSuccess;

  /// Invitation sent success message
  ///
  /// In en, this message translates to:
  /// **'Invitation email has been sent!'**
  String get householdInviteSentSuccess;

  /// Invitation resent success message
  ///
  /// In en, this message translates to:
  /// **'Invitation has been resent successfully.'**
  String get householdInviteResentSuccess;

  /// Invite URL copied success message
  ///
  /// In en, this message translates to:
  /// **'Invite URL copied to clipboard!'**
  String get householdInviteCopiedSuccess;

  /// Invite not found error message
  ///
  /// In en, this message translates to:
  /// **'The invitation was not found. It may have been cancelled or expired.'**
  String get householdErrorInviteNotFound;

  /// Permission denied error message
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to perform this action.'**
  String get householdErrorPermissionDenied;

  /// Already a member error message
  ///
  /// In en, this message translates to:
  /// **'You are already a member of this household.'**
  String get householdErrorAlreadyMember;

  /// Already has household error message
  ///
  /// In en, this message translates to:
  /// **'You already belong to a household. Please leave your current household first.'**
  String get householdErrorAlreadyHasHousehold;

  /// Invite expired error message
  ///
  /// In en, this message translates to:
  /// **'This invitation has expired. Please request a new one.'**
  String get householdErrorInviteExpired;

  /// Network error message
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your internet connection and try again.'**
  String get householdErrorNetwork;

  /// Timeout error message
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Please try again.'**
  String get householdErrorTimeout;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get householdErrorGeneric;

  /// Authentication required error
  ///
  /// In en, this message translates to:
  /// **'Authentication required'**
  String get householdErrorAuthRequired;

  /// Expires in prefix with date
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String householdExpiresIn(String date);

  /// Days until expiry
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String householdExpiresDays(int count);

  /// Hours until expiry
  ///
  /// In en, this message translates to:
  /// **'{count} hours'**
  String householdExpiresHours(int count);

  /// Minutes until expiry
  ///
  /// In en, this message translates to:
  /// **'{count} minutes'**
  String householdExpiresMinutes(int count);

  /// Expires soon text
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get householdExpiresSoon;

  /// Empty state for no pending invitations
  ///
  /// In en, this message translates to:
  /// **'No pending invitations'**
  String get householdNoPendingInvitations;

  /// Fallback name for member
  ///
  /// In en, this message translates to:
  /// **'this member'**
  String get householdThisMember;

  /// Loading state title in share session modal
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get shareSessionLoading;

  /// Error state title in share session modal
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get shareSessionError;

  /// Error message when share session fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load shared content. Please try again.'**
  String get shareSessionErrorLoadFailed;

  /// Error message when session data fails to load
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the shared content. Please try sharing again.'**
  String get shareSessionErrorSessionFailed;

  /// Error message when OG extraction fails
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read this post. It may be private or unavailable.'**
  String get shareSessionErrorCantReadPost;

  /// Error message when web extraction fails
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read this page. Please try again.'**
  String get shareSessionErrorCantReadPage;

  /// Generic processing error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while processing.'**
  String get shareSessionErrorProcessing;

  /// Error message when user is offline
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Please check your internet connection and try again.'**
  String get shareSessionErrorOffline;

  /// Error message when image processing fails
  ///
  /// In en, this message translates to:
  /// **'Failed to process the image(s). Please try again.'**
  String get shareSessionErrorImageProcessing;

  /// Error message when no recipe detected in photo
  ///
  /// In en, this message translates to:
  /// **'No recipe found in the photo.\n\nTry sharing a photo of a recipe card or cookbook page.'**
  String get shareSessionErrorNoRecipeInPhoto;

  /// Error message when photo processing fails
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while processing the photo.'**
  String get shareSessionErrorPhotoProcessing;

  /// Error message when no content is available
  ///
  /// In en, this message translates to:
  /// **'No content available to extract.'**
  String get shareSessionErrorNoContent;

  /// Error message when no recipe found on web page
  ///
  /// In en, this message translates to:
  /// **'This page doesn\'t appear to contain recipe information.\n\nTry sharing a page that includes a recipe.'**
  String get shareSessionErrorNoRecipeOnPage;

  /// Error message during import
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while importing.'**
  String get shareSessionErrorImporting;

  /// Error message when Plus is required for extraction
  ///
  /// In en, this message translates to:
  /// **'This site requires Plus subscription for recipe extraction.'**
  String get shareSessionErrorPlusRequired;

  /// Error message when no content in social post
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any content to extract from this post.'**
  String get shareSessionErrorNoContentInPost;

  /// Error message when no recipe in social post
  ///
  /// In en, this message translates to:
  /// **'This post doesn\'t appear to contain recipe information.\n\nTry sharing a post that includes ingredients or cooking steps in the caption.'**
  String get shareSessionErrorNoRecipeInPost;

  /// Error message when recipe extraction fails
  ///
  /// In en, this message translates to:
  /// **'Unable to extract a recipe from this post.'**
  String get shareSessionErrorExtractFailed;

  /// Error message prompting retry
  ///
  /// In en, this message translates to:
  /// **'Failed to extract recipe. Please try again.'**
  String get shareSessionErrorExtractRetry;

  /// Short error message when no recipe found
  ///
  /// In en, this message translates to:
  /// **'No recipe found on this page.'**
  String get shareSessionErrorNoRecipeOnPageShort;

  /// Error message when clipping save fails
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save this clipping. Please try again.'**
  String get shareSessionErrorClippingSave;

  /// Error message when no images to process
  ///
  /// In en, this message translates to:
  /// **'No images found to process.'**
  String get shareSessionErrorNoImages;

  /// Error message when page load fails
  ///
  /// In en, this message translates to:
  /// **'Could not load the page. Please try again.'**
  String get shareSessionErrorPageLoad;

  /// Fallback error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred.'**
  String get shareSessionErrorOccurred;

  /// Generic fallback error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get shareSessionErrorGeneric;

  /// Title for choosing action state
  ///
  /// In en, this message translates to:
  /// **'Shared Content'**
  String get shareSessionTitleSharedContent;

  /// Title during recipe import
  ///
  /// In en, this message translates to:
  /// **'Importing Recipe'**
  String get shareSessionTitleImportingRecipe;

  /// Title during photo processing
  ///
  /// In en, this message translates to:
  /// **'Processing Photo'**
  String get shareSessionTitleProcessingPhoto;

  /// Title during clipping save
  ///
  /// In en, this message translates to:
  /// **'Saving Clipping'**
  String get shareSessionTitleSavingClipping;

  /// Title during content extraction
  ///
  /// In en, this message translates to:
  /// **'Extracting Content'**
  String get shareSessionTitleExtractingContent;

  /// Title when extraction fails
  ///
  /// In en, this message translates to:
  /// **'Extraction Failed'**
  String get shareSessionTitleExtractionFailed;

  /// Error title when no recipe detected
  ///
  /// In en, this message translates to:
  /// **'No Recipe Found'**
  String get shareSessionErrorTitleNoRecipe;

  /// Error title when post can't be read
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t Read Post'**
  String get shareSessionErrorTitleCantRead;

  /// Error title when offline
  ///
  /// In en, this message translates to:
  /// **'No Connection'**
  String get shareSessionErrorTitleNoConnection;

  /// Generic error title
  ///
  /// In en, this message translates to:
  /// **'Something Went Wrong'**
  String get shareSessionErrorTitleGeneric;

  /// Error title when save fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t Save'**
  String get shareSessionErrorTitleCantSave;

  /// Error title when import fails
  ///
  /// In en, this message translates to:
  /// **'Import Failed'**
  String get shareSessionErrorTitleImportFailed;

  /// Button title for photo import
  ///
  /// In en, this message translates to:
  /// **'Import from Photo'**
  String get shareSessionActionImportFromPhoto;

  /// Button description for photo import
  ///
  /// In en, this message translates to:
  /// **'Extract recipe from cookbook or food photo'**
  String get shareSessionActionImportFromPhotoDesc;

  /// Button title for recipe import
  ///
  /// In en, this message translates to:
  /// **'Import Recipe'**
  String get shareSessionActionImportRecipe;

  /// Button description for recipe import
  ///
  /// In en, this message translates to:
  /// **'Extract ingredients and steps to create a new recipe'**
  String get shareSessionActionImportRecipeDesc;

  /// Button title for save as clipping
  ///
  /// In en, this message translates to:
  /// **'Save as Clipping'**
  String get shareSessionActionSaveAsClipping;

  /// Button description for save as clipping
  ///
  /// In en, this message translates to:
  /// **'Save for later and convert to a recipe when ready'**
  String get shareSessionActionSaveAsClippingDesc;

  /// Button description in error state
  ///
  /// In en, this message translates to:
  /// **'Save the link for later'**
  String get shareSessionActionSaveClippingErrorDesc;

  /// Loading text during fetch
  ///
  /// In en, this message translates to:
  /// **'Fetching from {domain}...'**
  String shareSessionLoadingFetching(String domain);

  /// Loading text during photo processing
  ///
  /// In en, this message translates to:
  /// **'Processing photo...'**
  String get shareSessionLoadingProcessingPhoto;

  /// Loading text during recipe extraction
  ///
  /// In en, this message translates to:
  /// **'Extracting recipe...'**
  String get shareSessionLoadingExtractingRecipe;

  /// Loading text during clipping save
  ///
  /// In en, this message translates to:
  /// **'Saving to clippings...'**
  String get shareSessionLoadingSavingClipping;

  /// Animated loading text
  ///
  /// In en, this message translates to:
  /// **'Finding ingredients...'**
  String get shareSessionLoadingFindingIngredients;

  /// Animated loading text
  ///
  /// In en, this message translates to:
  /// **'Organizing steps...'**
  String get shareSessionLoadingOrganizingSteps;

  /// Animated loading text
  ///
  /// In en, this message translates to:
  /// **'Reading photo...'**
  String get shareSessionLoadingReadingPhoto;

  /// Animated loading text
  ///
  /// In en, this message translates to:
  /// **'Finding recipe...'**
  String get shareSessionLoadingFindingRecipe;

  /// Animated loading text
  ///
  /// In en, this message translates to:
  /// **'Extracting ingredients...'**
  String get shareSessionLoadingExtractingIngredients;

  /// Section title in clipping
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get shareSessionClippingIngredients;

  /// Section title in clipping
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get shareSessionClippingInstructions;

  /// Metadata in clipping
  ///
  /// In en, this message translates to:
  /// **'Imported from {platform} on {date}'**
  String shareSessionClippingImportedFrom(String platform, String date);

  /// Default platform name when unknown
  ///
  /// In en, this message translates to:
  /// **'shared content'**
  String get shareSessionClippingSharedContent;

  /// Bottom tab bar label for menu/more
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navTabMore;

  /// Bottom tab bar label for recipes
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get navTabRecipes;

  /// Bottom tab bar label for shopping
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get navTabShopping;

  /// Bottom tab bar label for meal plan
  ///
  /// In en, this message translates to:
  /// **'Meal Plan'**
  String get navTabMealPlan;

  /// Bottom tab bar label for pantry
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get navTabPantry;

  /// Side menu item for recipes
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get menuRecipes;

  /// Side menu item for shopping list
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get menuShoppingList;

  /// Side menu item for meal plans
  ///
  /// In en, this message translates to:
  /// **'Meal Plans'**
  String get menuMealPlans;

  /// Side menu item for pantry
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get menuPantry;

  /// Side menu item for clippings
  ///
  /// In en, this message translates to:
  /// **'Clippings'**
  String get menuClippings;

  /// Side menu item for discover
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get menuDiscover;

  /// Side menu item for household
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get menuHousehold;

  /// Side menu item for account (when logged in)
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get menuAccount;

  /// Side menu item for sign up (when not logged in)
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get menuSignUp;

  /// Side menu item for settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// Upgrade banner title in side menu
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Plus'**
  String get menuUpgradeTitle;

  /// Upgrade banner subtitle in side menu
  ///
  /// In en, this message translates to:
  /// **'Import from social media & more'**
  String get menuUpgradeSubtitle;

  /// Title for recipe preview sheet
  ///
  /// In en, this message translates to:
  /// **'Import Recipe'**
  String get recipePreviewTitle;

  /// Plus badge label
  ///
  /// In en, this message translates to:
  /// **'PLUS'**
  String get recipePreviewPlusBadge;

  /// Headline for recipe preview upsell
  ///
  /// In en, this message translates to:
  /// **'Unlock the Full Recipe'**
  String get recipePreviewHeadline;

  /// Subheading for AI generation preview
  ///
  /// In en, this message translates to:
  /// **'Subscribe to Plus to get all ingredients and detailed cooking steps.'**
  String get recipePreviewSubheadingAi;

  /// Subheading for photo import preview
  ///
  /// In en, this message translates to:
  /// **'Plus extracts complete recipes from photos of cookbooks and handwritten notes.'**
  String get recipePreviewSubheadingPhoto;

  /// Subheading for social share preview
  ///
  /// In en, this message translates to:
  /// **'Plus extracts complete recipes from Instagram, TikTok, YouTube, and more.'**
  String get recipePreviewSubheadingSocial;

  /// Subheading for URL import preview
  ///
  /// In en, this message translates to:
  /// **'Plus uses AI to extract complete recipes from any website.'**
  String get recipePreviewSubheadingUrl;

  /// Recipe name section label
  ///
  /// In en, this message translates to:
  /// **'Recipe Name'**
  String get recipePreviewRecipeName;

  /// Description section label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get recipePreviewDescription;

  /// Ingredients section label
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get recipePreviewIngredients;

  /// Value prop for AI generation
  ///
  /// In en, this message translates to:
  /// **'AI generates complete recipes'**
  String get recipePreviewValuePropAi1;

  /// Value prop for AI generation
  ///
  /// In en, this message translates to:
  /// **'Full ingredients with measurements'**
  String get recipePreviewValuePropAi2;

  /// Value prop for AI generation
  ///
  /// In en, this message translates to:
  /// **'Detailed cooking steps'**
  String get recipePreviewValuePropAi3;

  /// Value prop for AI generation
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI recipe generation'**
  String get recipePreviewValuePropAi4;

  /// Value prop for photo import
  ///
  /// In en, this message translates to:
  /// **'AI extracts ingredients and steps'**
  String get recipePreviewValuePropPhoto1;

  /// Value prop for photo import
  ///
  /// In en, this message translates to:
  /// **'Works with photos of recipes'**
  String get recipePreviewValuePropPhoto2;

  /// Value prop for photo import
  ///
  /// In en, this message translates to:
  /// **'Import from social media too'**
  String get recipePreviewValuePropPhoto3;

  /// Value prop for photo import
  ///
  /// In en, this message translates to:
  /// **'Unlimited recipe imports'**
  String get recipePreviewValuePropPhoto4;

  /// Value prop for social share
  ///
  /// In en, this message translates to:
  /// **'Full ingredients with measurements'**
  String get recipePreviewValuePropSocial1;

  /// Value prop for social share
  ///
  /// In en, this message translates to:
  /// **'Complete cooking instructions'**
  String get recipePreviewValuePropSocial2;

  /// Value prop for social share
  ///
  /// In en, this message translates to:
  /// **'Works with any social platform'**
  String get recipePreviewValuePropSocial3;

  /// Value prop for social share
  ///
  /// In en, this message translates to:
  /// **'Unlimited recipe imports'**
  String get recipePreviewValuePropSocial4;

  /// Value prop for URL import
  ///
  /// In en, this message translates to:
  /// **'AI extracts ingredients and steps'**
  String get recipePreviewValuePropUrl1;

  /// Value prop for URL import
  ///
  /// In en, this message translates to:
  /// **'Works with any recipe page'**
  String get recipePreviewValuePropUrl2;

  /// Value prop for URL import
  ///
  /// In en, this message translates to:
  /// **'Import from social media too'**
  String get recipePreviewValuePropUrl3;

  /// Value prop for URL import
  ///
  /// In en, this message translates to:
  /// **'Unlimited recipe imports'**
  String get recipePreviewValuePropUrl4;

  /// Button to unlock recipe with Plus subscription
  ///
  /// In en, this message translates to:
  /// **'Unlock with Plus'**
  String get recipePreviewUnlockButton;

  /// Category label for fresh produce (fruits and vegetables)
  ///
  /// In en, this message translates to:
  /// **'Produce'**
  String get categoryProduce;

  /// Category label for meat and seafood
  ///
  /// In en, this message translates to:
  /// **'Meat & Seafood'**
  String get categoryMeatSeafood;

  /// Category label for dairy products and eggs
  ///
  /// In en, this message translates to:
  /// **'Dairy & Eggs'**
  String get categoryDairyEggs;

  /// Category label for tofu and soy-based products
  ///
  /// In en, this message translates to:
  /// **'Tofu & Soy Products'**
  String get categoryTofuSoyProducts;

  /// Category label for frozen foods
  ///
  /// In en, this message translates to:
  /// **'Frozen Foods'**
  String get categoryFrozenFoods;

  /// Category label for grains, cereals, and pasta
  ///
  /// In en, this message translates to:
  /// **'Grains, Cereals & Pasta'**
  String get categoryGrainsCerealsPasta;

  /// Category label for legumes, nuts, and plant proteins
  ///
  /// In en, this message translates to:
  /// **'Legumes, Nuts & Plant Proteins'**
  String get categoryLegumesNutsPlantProteins;

  /// Category label for dried foods like seaweed, mushrooms, and preserved items
  ///
  /// In en, this message translates to:
  /// **'Dried Goods'**
  String get categoryDriedGoods;

  /// Category label for baking ingredients and sweeteners
  ///
  /// In en, this message translates to:
  /// **'Baking & Sweeteners'**
  String get categoryBakingSweeteners;

  /// Category label for oils, fats, and vinegars
  ///
  /// In en, this message translates to:
  /// **'Oils, Fats & Vinegars'**
  String get categoryOilsFatsVinegars;

  /// Category label for herbs, spices, and seasonings
  ///
  /// In en, this message translates to:
  /// **'Herbs, Spices & Seasonings'**
  String get categoryHerbsSpicesSeasonings;

  /// Category label for sauces, condiments, and spreads
  ///
  /// In en, this message translates to:
  /// **'Sauces, Condiments & Spreads'**
  String get categorySaucesCondimentsSpreads;

  /// Category label for canned and jarred goods
  ///
  /// In en, this message translates to:
  /// **'Canned & Jarred Goods'**
  String get categoryCannedJarredGoods;

  /// Category label for beverages and snacks
  ///
  /// In en, this message translates to:
  /// **'Beverages & Snacks'**
  String get categoryBeveragesSnacks;

  /// Category label for miscellaneous items
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;
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
