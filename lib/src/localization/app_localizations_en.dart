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
  String get commonAdd => 'Add';

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

  @override
  String get helpTitle => 'Help';

  @override
  String get helpLoadError => 'Failed to load help topics';

  @override
  String get helpSectionAddingRecipes => 'Adding Recipes';

  @override
  String get helpSectionQuickQuestions => 'Quick Questions';

  @override
  String get helpSectionLearnMore => 'Learn More';

  @override
  String get helpSectionTroubleshooting => 'Troubleshooting';

  @override
  String get recipesTitle => 'Recipes';

  @override
  String get recipesFolders => 'Recipe Folders';

  @override
  String get recipesAddFolder => 'Add Folder';

  @override
  String get recipesAddSmartFolder => 'Add Smart Folder';

  @override
  String get recipesRecentlyViewed => 'Recently Viewed';

  @override
  String get recipesPinnedRecipes => 'Pinned Recipes';

  @override
  String get recipesViewAll => 'View All';

  @override
  String get recipesNotFound => 'Recipe not found';

  @override
  String recipesLoadError(String error) {
    return 'Error loading recipe: $error';
  }

  @override
  String get recipeCreateTitle => 'Create a Recipe';

  @override
  String get recipeCreateManually => 'Create Manually';

  @override
  String get recipeCreateManuallyDesc => 'Start from scratch';

  @override
  String get recipeImportFromUrl => 'Import from URL';

  @override
  String get recipeImportFromUrlDesc => 'Paste a recipe link';

  @override
  String get recipeGenerateWithAi => 'Generate with AI';

  @override
  String get recipeGenerateWithAiDesc => 'Describe what you want';

  @override
  String get recipeImportFromSocial => 'Import from Social';

  @override
  String get recipeImportFromSocialDesc => 'Instagram, TikTok, YouTube';

  @override
  String get recipeImportFromCamera => 'Import from Camera';

  @override
  String get recipeImportFromCameraDesc => 'Photograph a recipe';

  @override
  String get recipeImportFromPhotos => 'Import from Photos';

  @override
  String get recipeImportFromPhotosDesc => 'Select from your library';

  @override
  String get recipeDiscoverRecipes => 'Discover Recipes';

  @override
  String get recipeDiscoverRecipesDesc => 'Browse and import from the web';

  @override
  String get recipePlus => 'PLUS';

  @override
  String get recipeSocialImportTitle => 'Import from Social Media';

  @override
  String get recipeSocialImportInstructions =>
      'To import a recipe from Instagram, TikTok, or YouTube:';

  @override
  String get recipeSocialImportStep1 => 'Open the app and find a recipe video';

  @override
  String get recipeSocialImportStep2 => 'Tap the Share button';

  @override
  String get recipeSocialImportStep3 =>
      'Select \"Stockpot\" from the share menu';

  @override
  String get recipeSocialImportStep4 =>
      'We\'ll extract the recipe automatically';

  @override
  String get recipeGotIt => 'Got it';

  @override
  String get recipeFolderNew => 'New Recipe Folder';

  @override
  String get recipeFolderEnterName => 'Enter Folder Name';

  @override
  String get recipeFolderNameRequired => 'Folder name is required';

  @override
  String get recipeFolderCreateNew => 'Create New Folder';

  @override
  String get recipeFolderRename => 'Rename Folder';

  @override
  String get recipeFolderName => 'Folder name';

  @override
  String get recipeFolderRenameButton => 'Rename';

  @override
  String get recipeFolderDelete => 'Delete Folder';

  @override
  String get recipeFolderNoFolders => 'No folders yet';

  @override
  String get recipeFolders => 'Folders';

  @override
  String get recipeAiTitle => 'Generate with AI';

  @override
  String get recipeAiDescribe => 'Describe what you want to eat';

  @override
  String get recipeAiPlaceholder => 'e.g., \"I want a warm soup with chicken\"';

  @override
  String get recipeAiUsePantry => 'Use pantry items';

  @override
  String recipeAiItemsInStock(int count) {
    return '$count items in stock';
  }

  @override
  String recipeAiSelected(int count) {
    return '$count selected';
  }

  @override
  String get recipeAiGenerateIdeas => 'Generate Ideas';

  @override
  String get recipeAiRecipeIdeas => 'Recipe Ideas';

  @override
  String get recipeAiSelectToGenerate => 'Select a recipe to generate';

  @override
  String get recipeAiBrainstorming => 'Brainstorming recipes...';

  @override
  String get recipeAiConsidering => 'Considering your preferences...';

  @override
  String get recipeAiFinding => 'Finding delicious ideas...';

  @override
  String get recipeAiGenerating => 'Generating recipe...';

  @override
  String get recipeAiWritingIngredients => 'Writing ingredients...';

  @override
  String get recipeAiCraftingInstructions => 'Crafting instructions...';

  @override
  String get recipeAiLimitReached => 'Limit Reached';

  @override
  String get recipeAiGenerationFailed => 'Generation Failed';

  @override
  String get recipeAiUpgradeToPlus => 'Upgrade to Plus';

  @override
  String get recipeAiTryAgain => 'Try Again';

  @override
  String get recipeAiSelectPantryItems => 'Select Pantry Items';

  @override
  String get recipeAiSelectAll => 'Select All';

  @override
  String get recipeAiDeselectAll => 'Deselect All';

  @override
  String get recipeAiNoPantryItems => 'No pantry items available';

  @override
  String get recipeAiDifficultyEasy => 'Easy';

  @override
  String get recipeAiDifficultyMedium => 'Medium';

  @override
  String get recipeAiDifficultyHard => 'Hard';

  @override
  String get recipeUrlImportTitle => 'Import from URL';

  @override
  String get recipeUrlImportSubtitle => 'Paste a recipe URL to import';

  @override
  String get recipeUrlImportPlaceholder => 'https://example.com/recipe';

  @override
  String get recipeUrlImportButton => 'Import Recipe';

  @override
  String get recipeUrlImporting => 'Importing Recipe';

  @override
  String get recipeUrlFetching => 'Fetching recipe...';

  @override
  String get recipeUrlExtracting => 'Extracting recipe...';

  @override
  String get recipeUrlExtractionFailed => 'Extraction Failed';

  @override
  String get recipeUrlOffline =>
      'You\'re offline. Please check your internet connection.';

  @override
  String get recipeUrlInvalid => 'Please enter a valid URL.';

  @override
  String get recipeUrlNoRecipe =>
      'This page doesn\'t appear to contain recipe information.';

  @override
  String get recipeUrlPreviewLimitReached => 'Preview Limit Reached';

  @override
  String get recipeUrlImportFailed => 'Import Failed';

  @override
  String get recipeUrlPreviewLimit =>
      'Recipe previews are limited for free users. Upgrade to Plus for unlimited imports.';

  @override
  String get recipeUrlPlusRequired =>
      'This page requires Plus subscription for recipe extraction.';

  @override
  String get recipeUrlSomethingWrong =>
      'Something went wrong. Please try again.';

  @override
  String get recipeUrlNoRecipeFound => 'No recipe found on this page.';

  @override
  String get recipeUrlFailedExtract =>
      'Failed to extract recipe. Please try again.';

  @override
  String get recipePhotoProcessing => 'Processing Photo';

  @override
  String get recipePhotoReading => 'Reading photo...';

  @override
  String get recipePhotoProcessingStatus => 'Processing photo...';

  @override
  String get recipePhotoExtracting => 'Extracting recipe...';

  @override
  String get recipePhotoNoRecipe =>
      'No recipe found in the photo.\n\nTry a photo of a recipe card or cookbook page.';

  @override
  String get recipePhotoFailed =>
      'Failed to process the image(s). Please try again.';

  @override
  String get recipePhotoOffline =>
      'You\'re offline. Please check your internet connection and try again.';

  @override
  String get recipeEditorNewRecipe => 'New Recipe';

  @override
  String get recipeEditorAddImages => 'Add Images';

  @override
  String get recipeEditorAddIngredients => 'Add Ingredients';

  @override
  String get recipeEditorAddInstructions => 'Add Instructions';

  @override
  String get recipeEditorAddNotes => 'Add Notes';

  @override
  String get recipeEditorNotesPlaceholder => 'General notes about this recipe';

  @override
  String get recipeEditorSourcePlaceholder => 'Source (optional)';

  @override
  String get recipeEditorRating => 'Rating';

  @override
  String get recipeEditorClearAllIngredients => 'Clear All Ingredients?';

  @override
  String get recipeEditorClearAllSteps => 'Clear All Steps?';

  @override
  String recipeEditorClearConfirm(int count, String type) {
    return 'This will remove all $count $type. This action cannot be undone.';
  }

  @override
  String get recipeEditorClearAll => 'Clear All';

  @override
  String get recipeEditorNewSection => 'New Section';

  @override
  String recipeEditorSaveFailed(String error) {
    return 'Failed to save recipe: $error';
  }

  @override
  String get recipeViewIngredients => 'Ingredients';

  @override
  String get recipeViewInstructions => 'Instructions';

  @override
  String get recipeViewScaleConvert => 'Scale or Convert';

  @override
  String get recipeViewNoIngredients => 'No ingredients listed.';

  @override
  String get recipeViewNoInstructions => 'No instructions listed.';

  @override
  String get recipeTagSelectTitle => 'Select Tags';

  @override
  String get recipeTagCreateNew => 'Create New Tag';

  @override
  String get recipeTagNoTags => 'No tags yet';

  @override
  String get recipeTagCreateFirst =>
      'Create your first tag using the button above';

  @override
  String get recipeTagName => 'Tag Name';

  @override
  String get recipeTagEnterName => 'Enter tag name';

  @override
  String get recipeTagColor => 'Tag Color';

  @override
  String get recipeTagCreate => 'Create';

  @override
  String get recipeTagExists => 'A tag with this name already exists';

  @override
  String get recipeFolderSelectTitle => 'Add Recipe to Folders';

  @override
  String get recipeFolderCreateFirst =>
      'Create your first folder using the button above';

  @override
  String get recipeFolderExists => 'A folder with this name already exists';

  @override
  String get recipeFilterResetAll => 'Reset All';

  @override
  String get recipeFilterApply => 'Apply Changes';

  @override
  String get recipeFilterCookTime => 'Cook Time';

  @override
  String get recipeFilterRating => 'Rating';

  @override
  String get recipeFilterPantryMatch => 'Pantry Match';

  @override
  String get recipeFilterTags => 'Tags';

  @override
  String get recipeFilterMustHaveAllTags => 'Must have all tags';

  @override
  String get recipeFilterSort => 'Sort';

  @override
  String recipeFilterSortBy(String option) {
    return 'Sort by $option';
  }

  @override
  String get recipeFilterMatchAny => 'Match any recipe (Stock not required)';

  @override
  String get recipeFilterFewIngredients => 'A few ingredients in stock (25%)';

  @override
  String get recipeFilterHalfIngredients =>
      'At least half ingredients in stock (50%)';

  @override
  String get recipeFilterMostIngredients => 'Most ingredients in stock (75%)';

  @override
  String get recipeFilterAllIngredients => 'All ingredients in stock (100%)';

  @override
  String recipeFilterPercentMatch(int percent) {
    return '$percent% match';
  }

  @override
  String get recipeCookAddRecipe => 'Add Recipe';

  @override
  String get recipeCookComplete => 'Complete Cook';

  @override
  String get recipeCookAddRecipeTitle => 'Add Recipe to Cook';

  @override
  String get recipeCookNoSteps => 'No steps found for this recipe';

  @override
  String get recipeCookPrevious => 'Previous';

  @override
  String get recipeCookNext => 'Next';

  @override
  String get recipeIngredientLinkToRecipe => 'Link to Recipe';

  @override
  String get recipeIngredientConvertToIngredient => 'Convert to ingredient';

  @override
  String get recipeIngredientSectionName => 'Section name';

  @override
  String get recipeIngredientLinkExisting => 'Link to Existing Recipe';

  @override
  String get recipeIngredientChangeLinked => 'Change Linked Recipe';

  @override
  String get recipeIngredientRemoveLink => 'Remove Recipe Link';

  @override
  String get recipeIngredientNoRecipesFound => 'No recipes found';

  @override
  String get recipeIngredientNoRecipesMatch => 'No recipes match your search';

  @override
  String get recipeStepNextStep => 'Next Step';

  @override
  String get recipeStepConvertToStep => 'Convert to step';

  @override
  String get recipeStepConvertToSection => 'Convert to section';

  @override
  String get recipeStepDescribe => 'Describe this step';

  @override
  String get recipeEditIngredientsTitle => 'Edit Ingredients';

  @override
  String get recipeEditStepsTitle => 'Edit Steps';

  @override
  String get recipeEditUpdate => 'Update';

  @override
  String get recipeAddToShoppingList => 'Add to Shopping List';

  @override
  String get recipeAddToShoppingListButton => 'Add to Shopping List';

  @override
  String get recipeAddToShoppingListAdding => 'Adding...';

  @override
  String get recipeAddToShoppingListNoIngredients => 'No ingredients to add';

  @override
  String get recipeAddToShoppingListDefault => 'My Shopping List';

  @override
  String get recipeWelcomeGettingStarted => 'Getting Started';

  @override
  String get recipeWelcomeTitle => 'Welcome to Stockpot!';

  @override
  String get recipeWelcomeSubtitle =>
      'Create your first recipe and start\nbuilding your collection';

  @override
  String get recipeTileEdit => 'Edit Recipe';

  @override
  String get recipeTileDelete => 'Delete Recipe';

  @override
  String get recipeSearchPlaceholder => 'Search for recipes to add';

  @override
  String get recipeSearchNoResults => 'No recipes found';

  @override
  String get recipeSearchTryDifferent => 'Try a different search term';

  @override
  String get recipeSearchClearFilters => 'Clear Filters';

  @override
  String get recipeSearchFilterSort => 'Filter and Sort';

  @override
  String get recipeAddRecipeButton => 'Add Recipe';

  @override
  String get recipeFolderNoRecipesMatch =>
      'No recipes match the current filters';

  @override
  String get recipeFolderNoTagsMatch => 'No recipes match the selected tags';

  @override
  String get recipeFolderNoIngredientsMatch =>
      'No recipes match the selected ingredients';

  @override
  String get recipeEditSmartFolder => 'Edit Smart Folder';

  @override
  String get recipeCookTimeUnder30 => 'Under 30 minutes';

  @override
  String get recipeCookTime30To60 => '30-60 minutes';

  @override
  String get recipeCookTime1To2Hours => '1-2 hours';

  @override
  String get recipeCookTimeOver2Hours => 'Over 2 hours';

  @override
  String get recipeSortPantryMatch => 'Pantry Match %';

  @override
  String get recipeSortAlphabetical => 'Alphabetical';

  @override
  String get recipeSortRating => 'Rating';

  @override
  String get recipeSortTime => 'Time';

  @override
  String get recipeSortAddedDate => 'Added Date';

  @override
  String get recipeSortUpdatedDate => 'Updated Date';

  @override
  String recipeSearchError(String error) {
    return 'Error: $error';
  }

  @override
  String get recipeAddModalNew => 'New Recipe';

  @override
  String get recipeAddModalEdit => 'Edit Recipe';

  @override
  String get recipeAddModalCreate => 'Create';

  @override
  String get recipeAddModalUpdate => 'Update';

  @override
  String recipeAddModalFailed(String message) {
    return 'Failed to add recipe: $message';
  }

  @override
  String get recipeAddModalCannotAdd => 'Cannot Add Recipe';

  @override
  String get recipeAddModalAdd => 'Add';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDone => 'Done';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonIngredient => 'ingredient';

  @override
  String get commonIngredients => 'ingredients';

  @override
  String get commonStep => 'step';

  @override
  String get commonSteps => 'steps';

  @override
  String get recipeStepAddStep => 'Add Step';

  @override
  String get recipeStepAddSection => 'Add Section';

  @override
  String get recipeStepEditAsText => 'Edit as Text';

  @override
  String get recipeStepClearAll => 'Clear All Steps';

  @override
  String get recipeStepNoSteps => 'No steps added yet.';

  @override
  String get recipePinnedTitle => 'Pinned Recipes';

  @override
  String recipePinnedNoMatch(String query) {
    return 'No pinned recipes match \"$query\"';
  }

  @override
  String get recipePinnedEmpty =>
      'No pinned recipes yet.\nPin your favorite recipes to see them here.';

  @override
  String get recipePinnedNoResults => 'No recipes found';

  @override
  String get recipeMatchTitle => 'Pantry Matches';

  @override
  String recipeMatchSummary(int matched, int total) {
    return 'Pantry matches: $matched of $total ingredients';
  }

  @override
  String recipeMatchMatchedWith(String name) {
    return 'Matched with: $name';
  }

  @override
  String get recipeMatchTermsTitle => 'Matching Terms';

  @override
  String get recipeMatchAddTerm => 'Add New Term';

  @override
  String get recipeMatchNoTerms =>
      'No additional terms for this ingredient. Add terms to improve pantry matching.';

  @override
  String get recipeMatchTip =>
      'Tip: Add terms that match pantry item names to improve matching.';

  @override
  String recipeMatchSource(String source) {
    return 'Source: $source';
  }

  @override
  String get recipeMatchAddTermTitle => 'Add Matching Term';

  @override
  String get recipeMatchTermLabel => 'Term';

  @override
  String get recipeMatchTermHint =>
      'Enter a matching term (e.g., pantry item name)';

  @override
  String get recipeEditorRecipeTitle => 'Recipe Title';

  @override
  String get recipeEditorDescriptionOptional => 'Description (optional)';

  @override
  String get recipeEditorPrepTime => 'Prep Time';

  @override
  String get recipeEditorCookTime => 'Cook Time';

  @override
  String get recipeEditorServings => 'Servings';

  @override
  String get recipeEditorFolders => 'Folders';

  @override
  String get recipeEditorNoFolders => 'No folders';

  @override
  String get recipeEditorOneFolder => '1 folder';

  @override
  String recipeEditorFolderCount(int count) {
    return '$count folders';
  }

  @override
  String get recipeEditorTakePhoto => 'Take Photo';

  @override
  String get recipeEditorChooseFromGallery => 'Choose from Gallery';

  @override
  String get recipeEditorDeleteImage => 'Delete Image';

  @override
  String get recipeEditorDeleteImageConfirm =>
      'Are you sure you want to remove this image?';

  @override
  String get recipeEditorTags => 'Tags';

  @override
  String get recipeEditorEditTags => 'Edit Tags';

  @override
  String get recipeEditorNoTagsAssigned => 'No tags assigned';

  @override
  String get commonEnterValue => 'Enter value';

  @override
  String get commonUpdate => 'Update';

  @override
  String get durationPickerTitle => 'Select Duration';

  @override
  String get durationPickerHours => 'hours';

  @override
  String get durationPickerMinutes => 'minutes';

  @override
  String get durationPickerSeconds => 'seconds';

  @override
  String get folderUncategorized => 'Uncategorized';

  @override
  String get folderNoRecipes => 'no recipes';

  @override
  String get folderOneRecipe => '1 recipe';

  @override
  String folderRecipeCount(int count) {
    return '$count recipes';
  }

  @override
  String get folderRename => 'Rename Folder';

  @override
  String get folderEditSmart => 'Edit Smart Folder';

  @override
  String get folderDelete => 'Delete Folder';

  @override
  String get commonViewAll => 'View All';

  @override
  String get recipeRecentlyViewedTitle => 'Recently Viewed';

  @override
  String get recipeRecentlyViewedEmpty =>
      'No recently viewed recipes yet.\nStart exploring recipes to see them here.';

  @override
  String durationMinutesShort(int count) {
    return '$count min';
  }

  @override
  String durationHoursShort(int count) {
    return '$count hr';
  }

  @override
  String durationHoursMinutesShort(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String recipeServingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count servings',
      one: '1 serving',
    );
    return '$_temp0';
  }

  @override
  String get recipeMetadataServings => 'Servings';

  @override
  String get recipeMetadataPrepTime => 'Prep Time';

  @override
  String get recipeMetadataCookTime => 'Cook Time';

  @override
  String get recipeMetadataTotal => 'Total';

  @override
  String get recipeMetadataRating => 'Rating';

  @override
  String get recipeMetadataNotes => 'Notes';

  @override
  String recipeMetadataSource(String source) {
    return 'Source: $source';
  }

  @override
  String get recipeMetadataSourceLabel => 'Source: ';

  @override
  String get recipeCookStartCooking => 'Start Cooking';

  @override
  String get recipeCookResumeCooking => 'Resume Cooking';

  @override
  String get recipePageEditRecipe => 'Edit Recipe';

  @override
  String get recipePageCheckPantryStock => 'Check Pantry Stock';

  @override
  String get scaleConvertReset => 'Reset';

  @override
  String get scaleConvertScale => 'Scale';

  @override
  String get scaleConvertConvert => 'Convert';

  @override
  String get scaleConvertIngredient => 'Ingredient';

  @override
  String get scaleConvertSelectIngredient => 'Select ingredient';

  @override
  String get scaleTypeAmount => 'Amount';

  @override
  String get scaleTypeServings => 'Servings';

  @override
  String scaleSliderAmount(String value) {
    return 'Amount: ${value}x';
  }

  @override
  String scaleSliderServings(int count) {
    return 'Servings: $count';
  }

  @override
  String scaleSliderIngredientAmount(String value) {
    return 'Amount: $value';
  }

  @override
  String get conversionModeOriginal => 'Original';

  @override
  String get conversionModeImperial => 'Imperial';

  @override
  String get conversionModeMetric => 'Metric';
}
