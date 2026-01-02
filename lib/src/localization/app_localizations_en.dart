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

  @override
  String get commonOk => 'OK';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonError => 'Error';

  @override
  String get commonLoading => '...';

  @override
  String get commonComingSoon => 'Coming Soon';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsHomeScreen => 'Home Screen';

  @override
  String get settingsLayoutAppearance => 'Layout & Appearance';

  @override
  String get settingsManageTags => 'Manage Tags';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsImportRecipes => 'Import Recipes';

  @override
  String get settingsExportRecipes => 'Export Recipes';

  @override
  String get settingsHelp => 'Help';

  @override
  String get settingsSupport => 'Support';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsTermsOfUse => 'Terms of Use';

  @override
  String get settingsAcknowledgements => 'Acknowledgements';

  @override
  String get settingsHomeScreenRecipes => 'Recipes';

  @override
  String get settingsHomeScreenShopping => 'Shopping';

  @override
  String get settingsHomeScreenMealPlan => 'Meal Plan';

  @override
  String get settingsHomeScreenPantry => 'Pantry';

  @override
  String get settingsHomeScreenDescription =>
      'Choose which tab opens when the app launches. Changes take effect on next app launch.';

  @override
  String get settingsAccountNoEmail => 'No email';

  @override
  String get settingsAccountSignOutError => 'Sign Out Error';

  @override
  String settingsAccountSignOutErrorMessage(String error) {
    return 'Failed to sign out: $error';
  }

  @override
  String get settingsAccountUnsavedChanges => 'Unsaved Changes';

  @override
  String get settingsAccountUnsavedChangesMessage =>
      'Some data hasn\'t finished syncing to the cloud. If you sign out now, these changes may be lost.\n\nAre you sure you want to sign out?';

  @override
  String get settingsAccountSignOut => 'Sign Out';

  @override
  String get settingsAccountSignOutAnyway => 'Sign Out Anyway';

  @override
  String get settingsAccountNotLinked => 'Account Not Linked';

  @override
  String get settingsAccountNotLinkedMessage =>
      'You have Stockpot Plus but no account linked. Create an account to sync your recipes across devices and prevent data loss.';

  @override
  String get settingsLayoutRecipesPage => 'Recipes Page';

  @override
  String get settingsLayoutShowFolders => 'Show Folders';

  @override
  String get settingsLayoutSortFolders => 'Sort Folders';

  @override
  String get settingsLayoutAppearanceSection => 'Appearance';

  @override
  String get settingsLayoutColorTheme => 'Color Theme';

  @override
  String get settingsLayoutRecipeFontSize => 'Recipe Font Size';

  @override
  String get settingsShowFoldersAll => 'All folders';

  @override
  String settingsShowFoldersFirst(int count) {
    return 'First $count folders';
  }

  @override
  String get settingsShowFoldersFirstN => 'First N folders';

  @override
  String get settingsShowFoldersNumberHeader => 'Number of Folders';

  @override
  String get settingsShowFoldersNumberDescription =>
      'Show this many folders on the recipes page.';

  @override
  String get settingsSortFoldersAlphaAZ => 'Alphabetical (A-Z)';

  @override
  String get settingsSortFoldersAlphaZA => 'Alphabetical (Z-A)';

  @override
  String get settingsSortFoldersNewest => 'Newest First';

  @override
  String get settingsSortFoldersOldest => 'Oldest First';

  @override
  String get settingsSortFoldersCustom => 'Custom';

  @override
  String get settingsSortFoldersError => 'Error loading folders';

  @override
  String get settingsSortFoldersCustomOrder => 'CUSTOM ORDER';

  @override
  String get settingsSortFoldersDragDescription =>
      'Drag folders to set your preferred order.';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeLightDescription => 'Always use light appearance';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeDarkDescription => 'Always use dark appearance';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeSystemDescription => 'Match device appearance';

  @override
  String get settingsFontSizeTitle => 'Font Size';

  @override
  String get settingsFontSizeSmall => 'Small';

  @override
  String get settingsFontSizeMedium => 'Medium';

  @override
  String get settingsFontSizeLarge => 'Large';

  @override
  String get settingsFontSizeDescription =>
      'Adjust the text size for recipe ingredients and steps.';

  @override
  String get settingsFontSizePreview => 'Preview';

  @override
  String get settingsFontSizePreviewIngredients => 'Ingredients';

  @override
  String get settingsFontSizePreviewItem1 => '2 cups all-purpose flour';

  @override
  String get settingsFontSizePreviewItem2 => '1 tsp baking powder';

  @override
  String get settingsFontSizePreviewItem3 =>
      '1/2 cup unsalted butter, softened';

  @override
  String get settingsTagsNoTagsTitle => 'No Tags Yet';

  @override
  String get settingsTagsNoTagsDescription =>
      'Tags help you organize your recipes.\nCreate your first tag by adding one when editing a recipe.';

  @override
  String get settingsTagsYourTags => 'Your Tags';

  @override
  String get settingsTagsDescription =>
      'Tap a color circle to change the tag color. Deleting a tag will remove it from all recipes.';

  @override
  String settingsTagsDeleteTitle(String tagName) {
    return 'Delete \"$tagName\"?';
  }

  @override
  String settingsTagsDeleteMessageWithRecipes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipes',
      one: '1 recipe',
    );
    return 'This tag is used by $_temp0. Deleting it will remove the tag from all recipes.';
  }

  @override
  String get settingsTagsDeleteMessageNoRecipes =>
      'This action cannot be undone.';

  @override
  String settingsTagsRecipeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipes',
      one: '1 recipe',
      zero: 'No recipes',
    );
    return '$_temp0';
  }

  @override
  String get settingsSupportDiagnostics => 'Diagnostics';

  @override
  String get settingsSupportExportLogs => 'Export Logs';

  @override
  String get settingsSupportClearLogs => 'Clear Logs';

  @override
  String get settingsSupportContact => 'Contact';

  @override
  String get settingsSupportEmailSupport => 'Email Support';

  @override
  String get settingsSupportNoLogs => 'No Logs Available';

  @override
  String get settingsSupportNoLogsMessage => 'There are no logs to export yet.';

  @override
  String get settingsSupportClearLogsTitle => 'Clear Logs?';

  @override
  String get settingsSupportClearLogsMessage =>
      'This will delete all diagnostic logs. This action cannot be undone.';

  @override
  String get settingsSupportLogsCleared => 'Logs Cleared';

  @override
  String get settingsSupportLogsClearedMessage =>
      'All diagnostic logs have been deleted.';

  @override
  String get settingsSupportLogsClearFailed =>
      'Failed to clear logs. Please try again.';

  @override
  String get settingsSupportEmailError => 'Unable to Open Email';

  @override
  String get settingsSupportEmailErrorMessage =>
      'Please email us at support@stockpot.app';

  @override
  String get settingsSupportEmailSubject => 'Stockpot Support Request';

  @override
  String get settingsSupportNotSignedIn => 'Not signed in';

  @override
  String settingsSupportEmailBody(
      String userId, String appVersion, String platform, String osVersion) {
    return 'Please describe your issue above this line\n\n---\nUser ID: $userId\nApp Version: $appVersion\nPlatform: $platform\nOS Version: $osVersion';
  }

  @override
  String get settingsAcknowledgementsOSSLicenses =>
      'Open Source Software Licenses';

  @override
  String get settingsAcknowledgementsSoundCredits =>
      'Sound material used: OtoLogic (https://otologic.jp)';

  @override
  String get settingsImportDescription =>
      'Import recipes from other apps or websites.';

  @override
  String get settingsExportDescription =>
      'Export your recipes to share or backup.';

  @override
  String get importTitle => 'Import Recipes';

  @override
  String get importFromHeader => 'Import from:';

  @override
  String get importSourceStockpot => 'Stockpot';

  @override
  String get importSourceStockpotDesc => 'Import from a previous backup';

  @override
  String get importSourcePaprika => 'Paprika';

  @override
  String get importSourcePaprikaDesc => 'Import from Paprika Recipe Manager';

  @override
  String get importSourceCrouton => 'Crouton';

  @override
  String get importSourceCroutonDesc => 'Import from Crouton app';

  @override
  String get importInvalidFile => 'Invalid File';

  @override
  String get importInvalidPaprikaFile =>
      'Please select a .paprikarecipes file exported from Paprika.';

  @override
  String get importPreviewTitle => 'Import Preview';

  @override
  String get importAnalyzing => 'Analyzing import file...';

  @override
  String get importParseFailed => 'Failed to Parse Import';

  @override
  String get importUnknownError => 'Unknown error';

  @override
  String importReadyFrom(String source) {
    return 'Ready to import from $source:';
  }

  @override
  String importRecipeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipes',
      one: '1 recipe',
    );
    return '$_temp0';
  }

  @override
  String importTagCount(int total, int newCount, int existingCount) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total tags',
      one: '1 tag',
    );
    return '$_temp0 ($newCount new, $existingCount existing)';
  }

  @override
  String importFolderCount(int total, int newCount, int existingCount) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total folders',
      one: '1 folder',
    );
    return '$_temp0 ($newCount new, $existingCount existing)';
  }

  @override
  String get importPaprikaCategoriesHeader => 'Paprika Categories';

  @override
  String get importPaprikaCategoriesFooter =>
      'Choose whether to import Paprika categories as tags or folders.';

  @override
  String get importAsTags => 'Tags (recommended)';

  @override
  String get importAsFolders => 'Folders';

  @override
  String get importButton => 'Import Recipes';

  @override
  String get importComplete => 'Import Complete';

  @override
  String get importFinished => 'Import Finished';

  @override
  String importSuccessMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipes',
      one: '1 recipe',
    );
    return 'Successfully imported $_temp0!';
  }

  @override
  String importSuccessUpgradeMessage(int count) {
    return 'Imported $count recipes. Upgrade to unlock your full collection.';
  }

  @override
  String importPartialMessage(int success, int failed) {
    return 'Imported $success recipes. $failed failed.';
  }

  @override
  String get importFailed => 'Import Failed';

  @override
  String importFailedMessage(String error) {
    return 'Failed to import recipes: $error';
  }

  @override
  String get exportTitle => 'Export Recipes';

  @override
  String get exportOptionsHeader => 'Export Options';

  @override
  String get exportAllRecipes => 'Export All Recipes';

  @override
  String get exportExporting => 'Exporting...';

  @override
  String get exportComingSoon =>
      'Additional export formats (HTML, PDF, etc.) coming soon.';

  @override
  String get exportNoRecipes => 'No Recipes';

  @override
  String get exportNoRecipesMessage => 'You don\'t have any recipes to export.';

  @override
  String get exportShareSubject => 'My Recipes Export';

  @override
  String get exportComplete => 'Export Complete';

  @override
  String exportSuccessMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipes',
      one: '1 recipe',
    );
    return 'Successfully exported $_temp0.';
  }

  @override
  String get exportFailed => 'Export Failed';

  @override
  String exportFailedMessage(String error) {
    return 'Failed to export recipes: $error';
  }
}
