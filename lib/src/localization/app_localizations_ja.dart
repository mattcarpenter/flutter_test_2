// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Stockpot';

  @override
  String get authSignUp => '新規登録';

  @override
  String get authSignIn => 'ログイン';

  @override
  String get authCreateAccount => 'アカウント作成';

  @override
  String get authContinueWithEmail => 'メールで続ける';

  @override
  String get authContinueWithGoogle => 'Googleで続ける';

  @override
  String authContinueWithProvider(String provider) {
    return '$providerで続ける';
  }

  @override
  String get authSignInWithGoogle => 'Googleでログイン';

  @override
  String get authSignInWithApple => 'Appleでログイン';

  @override
  String get authAlreadyHaveAccount => 'アカウントをお持ちの方は';

  @override
  String get authDontHaveAccount => 'アカウントをお持ちでない方は';

  @override
  String get authForgotPassword => 'パスワードをお忘れですか？';

  @override
  String get authResetPassword => 'パスワードをリセット';

  @override
  String get authSendResetLink => 'リセットリンクを送信';

  @override
  String get authResetPasswordInstructions =>
      'メールアドレスを入力してください。パスワードリセット用のリンクをお送りします。';

  @override
  String get authRememberPassword => 'パスワードを覚えている方は';

  @override
  String get authOr => 'または';

  @override
  String get authEmailLabel => 'メールアドレス';

  @override
  String get authEmailPlaceholder => 'your@email.com';

  @override
  String get authPasswordLabel => 'パスワード';

  @override
  String get authConfirmPasswordLabel => 'パスワード（確認）';

  @override
  String get authEmailRequired => 'メールアドレスを入力してください';

  @override
  String get authEmailInvalid => '有効なメールアドレスを入力してください';

  @override
  String get authPasswordRequired => 'パスワードを入力してください';

  @override
  String get authPasswordTooShort => 'パスワードは6文字以上で入力してください';

  @override
  String get authConfirmPasswordRequired => 'パスワードを確認してください';

  @override
  String get authPasswordsDoNotMatch => 'パスワードが一致しません';

  @override
  String get authEnterEmailAndPassword => 'メールアドレスとパスワードを入力してください。';

  @override
  String get authTermsPrefix => '';

  @override
  String get authTermsOfService => '利用規約';

  @override
  String get authTermsAnd => 'と';

  @override
  String get authPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get authAcceptTermsRequired => '続行するには利用規約とプライバシーポリシーに同意してください。';

  @override
  String get authFailedGoogle => 'Googleログインに失敗しました。もう一度お試しください。';

  @override
  String get authFailedApple => 'Appleログインに失敗しました。もう一度お試しください。';

  @override
  String get authFailedSignIn => 'ログインに失敗しました。認証情報を確認してもう一度お試しください。';

  @override
  String get authFailedCreateAccount => 'アカウントの作成に失敗しました。もう一度お試しください。';

  @override
  String authFailedSignUpWithProvider(String provider) {
    return '$providerでの登録に失敗しました。もう一度お試しください。';
  }

  @override
  String authFailedSignInWithProvider(String provider) {
    return '$providerでのログインに失敗しました。もう一度お試しください。';
  }

  @override
  String get authPasswordResetSuccess =>
      'パスワードリセットメールを送信しました！受信トレイを確認し、指示に従ってパスワードをリセットしてください。';

  @override
  String get authPasswordResetFailed =>
      'リセットメールの送信に失敗しました。メールアドレスを確認してもう一度お試しください。';

  @override
  String get authSignInWarningTitle => 'ログインに関する警告';

  @override
  String get authSignInWarningMessage =>
      '現在、このデバイスにStockpot Plusのサブスクリプションが紐づけられています。既存のアカウントにログインすると：\n\n• ローカルのレシピがアカウントのデータに置き換えられます\n• ログイン後に購入の復元が必要です\n\n先にレシピをエクスポートすることをお勧めします。';

  @override
  String get authSignInAnyway => 'ログインする';

  @override
  String get authReplaceLocalDataTitle => 'ローカルデータを置き換えますか？';

  @override
  String get authReplaceLocalDataMessage =>
      'ログインすると、ローカルのレシピがアカウントのデータに置き換えられます。先にレシピをエクスポートすることをお勧めします。';

  @override
  String get authAccountExistsTitle => 'アカウントが既に存在します';

  @override
  String authAccountExistsMessage(String provider) {
    return 'この$providerアカウントは既に別のユーザーに紐づけられています。そのアカウントにアクセスするにはログインしてください。';
  }

  @override
  String get authGoToSignIn => 'ログインへ';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonOk => 'OK';

  @override
  String get commonDelete => '削除';

  @override
  String get commonAdd => '追加';

  @override
  String get commonClear => 'クリア';

  @override
  String get commonError => 'エラー';

  @override
  String get commonLoading => '...';

  @override
  String get commonComingSoon => '近日公開';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsHomeScreen => 'ホーム画面';

  @override
  String get settingsLayoutAppearance => 'レイアウトと外観';

  @override
  String get settingsManageTags => 'タグを管理';

  @override
  String get settingsAccount => 'アカウント';

  @override
  String get settingsImportRecipes => 'レシピをインポート';

  @override
  String get settingsExportRecipes => 'レシピをエクスポート';

  @override
  String get settingsHelp => 'ヘルプ';

  @override
  String get settingsSupport => 'サポート';

  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get settingsTermsOfUse => '利用規約';

  @override
  String get settingsAcknowledgements => '謝辞';

  @override
  String get settingsHomeScreenRecipes => 'レシピ';

  @override
  String get settingsHomeScreenShopping => '買い物';

  @override
  String get settingsHomeScreenMealPlan => '献立';

  @override
  String get settingsHomeScreenPantry => 'パントリー';

  @override
  String get settingsHomeScreenDescription =>
      'アプリ起動時に開くタブを選択してください。変更は次回起動時に反映されます。';

  @override
  String get settingsAccountNoEmail => 'メールなし';

  @override
  String get settingsAccountSignOutError => 'サインアウトエラー';

  @override
  String settingsAccountSignOutErrorMessage(String error) {
    return 'サインアウトに失敗しました: $error';
  }

  @override
  String get settingsAccountUnsavedChanges => '未保存の変更';

  @override
  String get settingsAccountUnsavedChangesMessage =>
      '一部のデータがクラウドに同期されていません。今サインアウトすると、これらの変更が失われる可能性があります。\n\nサインアウトしてもよろしいですか？';

  @override
  String get settingsAccountSignOut => 'サインアウト';

  @override
  String get settingsAccountSignOutAnyway => 'サインアウトする';

  @override
  String get settingsAccountNotLinked => 'アカウント未連携';

  @override
  String get settingsAccountNotLinkedMessage =>
      'Stockpot Plusをお持ちですが、アカウントが連携されていません。デバイス間でレシピを同期し、データ損失を防ぐためにアカウントを作成してください。';

  @override
  String get settingsLayoutRecipesPage => 'レシピページ';

  @override
  String get settingsLayoutShowFolders => 'フォルダを表示';

  @override
  String get settingsLayoutSortFolders => 'フォルダを並び替え';

  @override
  String get settingsLayoutAppearanceSection => '外観';

  @override
  String get settingsLayoutColorTheme => 'カラーテーマ';

  @override
  String get settingsLayoutRecipeFontSize => 'レシピのフォントサイズ';

  @override
  String get settingsShowFoldersAll => 'すべてのフォルダ';

  @override
  String settingsShowFoldersFirst(int count) {
    return '最初の$countフォルダ';
  }

  @override
  String get settingsShowFoldersFirstN => '最初のNフォルダ';

  @override
  String get settingsShowFoldersNumberHeader => 'フォルダ数';

  @override
  String get settingsShowFoldersNumberDescription => 'レシピページに表示するフォルダの数。';

  @override
  String get settingsSortFoldersAlphaAZ => 'アルファベット順 (A-Z)';

  @override
  String get settingsSortFoldersAlphaZA => 'アルファベット順 (Z-A)';

  @override
  String get settingsSortFoldersNewest => '新しい順';

  @override
  String get settingsSortFoldersOldest => '古い順';

  @override
  String get settingsSortFoldersCustom => 'カスタム';

  @override
  String get settingsSortFoldersError => 'フォルダの読み込みエラー';

  @override
  String get settingsSortFoldersCustomOrder => 'カスタム順序';

  @override
  String get settingsSortFoldersDragDescription => 'フォルダをドラッグして順序を設定してください。';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeLightDescription => '常にライトモードを使用';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsThemeDarkDescription => '常にダークモードを使用';

  @override
  String get settingsThemeSystem => 'システム';

  @override
  String get settingsThemeSystemDescription => 'デバイスの設定に合わせる';

  @override
  String get settingsFontSizeTitle => 'フォントサイズ';

  @override
  String get settingsFontSizeSmall => '小';

  @override
  String get settingsFontSizeMedium => '中';

  @override
  String get settingsFontSizeLarge => '大';

  @override
  String get settingsFontSizeDescription => 'レシピの材料と手順のテキストサイズを調整します。';

  @override
  String get settingsFontSizePreview => 'プレビュー';

  @override
  String get settingsFontSizePreviewIngredients => '材料';

  @override
  String get settingsFontSizePreviewItem1 => '薄力粉 2カップ';

  @override
  String get settingsFontSizePreviewItem2 => 'ベーキングパウダー 小さじ1';

  @override
  String get settingsFontSizePreviewItem3 => '無塩バター 1/2カップ（室温）';

  @override
  String get settingsTagsNoTagsTitle => 'タグがありません';

  @override
  String get settingsTagsNoTagsDescription =>
      'タグはレシピを整理するのに役立ちます。\nレシピ編集時にタグを追加して最初のタグを作成してください。';

  @override
  String get settingsTagsYourTags => 'あなたのタグ';

  @override
  String get settingsTagsDescription =>
      '色の円をタップしてタグの色を変更できます。タグを削除すると、すべてのレシピからそのタグが削除されます。';

  @override
  String settingsTagsDeleteTitle(String tagName) {
    return '「$tagName」を削除しますか？';
  }

  @override
  String settingsTagsDeleteMessageWithRecipes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countつのレシピ',
      one: '1つのレシピ',
    );
    return 'このタグは$_temp0で使用されています。削除すると、すべてのレシピからこのタグが削除されます。';
  }

  @override
  String get settingsTagsDeleteMessageNoRecipes => 'この操作は元に戻せません。';

  @override
  String settingsTagsRecipeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countつのレシピ',
      one: '1つのレシピ',
      zero: 'レシピなし',
    );
    return '$_temp0';
  }

  @override
  String get settingsSupportDiagnostics => '診断';

  @override
  String get settingsSupportExportLogs => 'ログをエクスポート';

  @override
  String get settingsSupportClearLogs => 'ログをクリア';

  @override
  String get settingsSupportContact => 'お問い合わせ';

  @override
  String get settingsSupportEmailSupport => 'メールサポート';

  @override
  String get settingsSupportNoLogs => 'ログがありません';

  @override
  String get settingsSupportNoLogsMessage => 'エクスポートするログがまだありません。';

  @override
  String get settingsSupportClearLogsTitle => 'ログをクリアしますか？';

  @override
  String get settingsSupportClearLogsMessage => 'すべての診断ログが削除されます。この操作は元に戻せません。';

  @override
  String get settingsSupportLogsCleared => 'ログをクリアしました';

  @override
  String get settingsSupportLogsClearedMessage => 'すべての診断ログが削除されました。';

  @override
  String get settingsSupportLogsClearFailed => 'ログのクリアに失敗しました。もう一度お試しください。';

  @override
  String get settingsSupportEmailError => 'メールを開けません';

  @override
  String get settingsSupportEmailErrorMessage =>
      'support@stockpot.app までメールでお問い合わせください';

  @override
  String get settingsSupportEmailSubject => 'Stockpot サポートリクエスト';

  @override
  String get settingsSupportNotSignedIn => 'サインインしていません';

  @override
  String settingsSupportEmailBody(
      String userId, String appVersion, String platform, String osVersion) {
    return 'この行より上に問題を記述してください\n\n---\nユーザーID: $userId\nアプリバージョン: $appVersion\nプラットフォーム: $platform\nOSバージョン: $osVersion';
  }

  @override
  String get settingsAcknowledgementsOSSLicenses => 'オープンソースソフトウェアライセンス';

  @override
  String get settingsAcknowledgementsSoundCredits =>
      '使用音源: OtoLogic (https://otologic.jp)';

  @override
  String get settingsImportDescription => '他のアプリやウェブサイトからレシピをインポートします。';

  @override
  String get settingsExportDescription => 'レシピをエクスポートして共有またはバックアップします。';

  @override
  String get importTitle => 'レシピをインポート';

  @override
  String get importFromHeader => 'インポート元:';

  @override
  String get importSourceStockpot => 'Stockpot';

  @override
  String get importSourceStockpotDesc => '以前のバックアップからインポート';

  @override
  String get importSourcePaprika => 'Paprika';

  @override
  String get importSourcePaprikaDesc => 'Paprika Recipe Managerからインポート';

  @override
  String get importSourceCrouton => 'Crouton';

  @override
  String get importSourceCroutonDesc => 'Croutonアプリからインポート';

  @override
  String get importInvalidFile => '無効なファイル';

  @override
  String get importInvalidPaprikaFile =>
      'Paprikaからエクスポートした.paprikarecipesファイルを選択してください。';

  @override
  String get importPreviewTitle => 'インポートプレビュー';

  @override
  String get importAnalyzing => 'インポートファイルを解析中...';

  @override
  String get importParseFailed => 'インポートの解析に失敗';

  @override
  String get importUnknownError => '不明なエラー';

  @override
  String importReadyFrom(String source) {
    return '$sourceからインポート準備完了:';
  }

  @override
  String importRecipeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のレシピ',
    );
    return '$_temp0';
  }

  @override
  String importTagCount(int total, int newCount, int existingCount) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total個のタグ',
    );
    return '$_temp0 ($newCount個が新規、$existingCount個が既存)';
  }

  @override
  String importFolderCount(int total, int newCount, int existingCount) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total個のフォルダ',
    );
    return '$_temp0 ($newCount個が新規、$existingCount個が既存)';
  }

  @override
  String get importPaprikaCategoriesHeader => 'Paprikaカテゴリ';

  @override
  String get importPaprikaCategoriesFooter =>
      'Paprikaのカテゴリをタグまたはフォルダとしてインポートするか選択してください。';

  @override
  String get importAsTags => 'タグ（推奨）';

  @override
  String get importAsFolders => 'フォルダ';

  @override
  String get importButton => 'レシピをインポート';

  @override
  String get importComplete => 'インポート完了';

  @override
  String get importFinished => 'インポート終了';

  @override
  String importSuccessMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のレシピをインポートしました',
    );
    return '$_temp0！';
  }

  @override
  String importSuccessUpgradeMessage(int count) {
    return '$count件のレシピをインポートしました。アップグレードして全コレクションをアンロックしてください。';
  }

  @override
  String importPartialMessage(int success, int failed) {
    return '$success件のレシピをインポートしました。$failed件が失敗しました。';
  }

  @override
  String get importFailed => 'インポート失敗';

  @override
  String importFailedMessage(String error) {
    return 'レシピのインポートに失敗しました: $error';
  }

  @override
  String get exportTitle => 'レシピをエクスポート';

  @override
  String get exportOptionsHeader => 'エクスポートオプション';

  @override
  String get exportAllRecipes => 'すべてのレシピをエクスポート';

  @override
  String get exportExporting => 'エクスポート中...';

  @override
  String get exportComingSoon => '追加のエクスポート形式（HTML、PDFなど）は近日公開予定です。';

  @override
  String get exportNoRecipes => 'レシピがありません';

  @override
  String get exportNoRecipesMessage => 'エクスポートするレシピがありません。';

  @override
  String get exportShareSubject => 'マイレシピエクスポート';

  @override
  String get exportComplete => 'エクスポート完了';

  @override
  String exportSuccessMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のレシピをエクスポートしました',
    );
    return '$_temp0。';
  }

  @override
  String get exportFailed => 'エクスポート失敗';

  @override
  String exportFailedMessage(String error) {
    return 'レシピのエクスポートに失敗しました: $error';
  }

  @override
  String get helpTitle => 'ヘルプ';

  @override
  String get helpLoadError => 'ヘルプトピックの読み込みに失敗しました';

  @override
  String get helpSectionAddingRecipes => 'レシピの追加';

  @override
  String get helpSectionQuickQuestions => 'よくある質問';

  @override
  String get helpSectionLearnMore => '詳しく知る';

  @override
  String get helpSectionTroubleshooting => 'トラブルシューティング';

  @override
  String get recipesTitle => 'レシピ';

  @override
  String get recipesFolders => 'レシピフォルダ';

  @override
  String get recipesAddFolder => 'フォルダを追加';

  @override
  String get recipesAddSmartFolder => 'スマートフォルダを追加';

  @override
  String get recipesRecentlyViewed => '最近見たレシピ';

  @override
  String get recipesPinnedRecipes => 'ピン留めしたレシピ';

  @override
  String get recipesViewAll => 'すべて見る';

  @override
  String get recipesNotFound => 'レシピが見つかりません';

  @override
  String recipesLoadError(String error) {
    return 'レシピの読み込みエラー: $error';
  }

  @override
  String get recipeCreateTitle => 'レシピを作成';

  @override
  String get recipeCreateManually => '手動で作成';

  @override
  String get recipeCreateManuallyDesc => '最初から作成';

  @override
  String get recipeImportFromUrl => 'URLからインポート';

  @override
  String get recipeImportFromUrlDesc => 'レシピリンクを貼り付け';

  @override
  String get recipeGenerateWithAi => 'AIで生成';

  @override
  String get recipeGenerateWithAiDesc => '食べたいものを説明';

  @override
  String get recipeImportFromSocial => 'SNSからインポート';

  @override
  String get recipeImportFromSocialDesc => 'Instagram、TikTok、YouTube';

  @override
  String get recipeImportFromCamera => 'カメラからインポート';

  @override
  String get recipeImportFromCameraDesc => 'レシピを撮影';

  @override
  String get recipeImportFromPhotos => '写真からインポート';

  @override
  String get recipeImportFromPhotosDesc => 'ライブラリから選択';

  @override
  String get recipeDiscoverRecipes => 'レシピを探す';

  @override
  String get recipeDiscoverRecipesDesc => 'ウェブから閲覧・インポート';

  @override
  String get recipePlus => 'PLUS';

  @override
  String get recipeSocialImportTitle => 'SNSからインポート';

  @override
  String get recipeSocialImportInstructions =>
      'Instagram、TikTok、YouTubeからレシピをインポートするには：';

  @override
  String get recipeSocialImportStep1 => 'アプリを開いてレシピ動画を見つける';

  @override
  String get recipeSocialImportStep2 => '共有ボタンをタップ';

  @override
  String get recipeSocialImportStep3 => '共有メニューから「Stockpot」を選択';

  @override
  String get recipeSocialImportStep4 => 'レシピを自動的に抽出します';

  @override
  String get recipeGotIt => '了解';

  @override
  String get recipeFolderNew => '新しいレシピフォルダ';

  @override
  String get recipeFolderEnterName => 'フォルダ名を入力';

  @override
  String get recipeFolderNameRequired => 'フォルダ名は必須です';

  @override
  String get recipeFolderCreateNew => '新しいフォルダを作成';

  @override
  String get recipeFolderRename => 'フォルダ名を変更';

  @override
  String get recipeFolderName => 'フォルダ名';

  @override
  String get recipeFolderRenameButton => '名前を変更';

  @override
  String get recipeFolderDelete => 'フォルダを削除';

  @override
  String get recipeFolderNoFolders => 'フォルダなし';

  @override
  String get recipeFolders => 'フォルダ';

  @override
  String get recipeAiTitle => 'AIで生成';

  @override
  String get recipeAiDescribe => '食べたいものを説明してください';

  @override
  String get recipeAiPlaceholder => '例：「鶏肉を使った温かいスープが食べたい」';

  @override
  String get recipeAiUsePantry => 'パントリーのアイテムを使う';

  @override
  String recipeAiItemsInStock(int count) {
    return '$count個の在庫アイテム';
  }

  @override
  String recipeAiSelected(int count) {
    return '$count個選択中';
  }

  @override
  String get recipeAiGenerateIdeas => 'アイデアを生成';

  @override
  String get recipeAiRecipeIdeas => 'レシピのアイデア';

  @override
  String get recipeAiSelectToGenerate => '生成するレシピを選択';

  @override
  String get recipeAiBrainstorming => 'レシピを考案中...';

  @override
  String get recipeAiConsidering => 'お好みを考慮中...';

  @override
  String get recipeAiFinding => 'おいしいアイデアを探索中...';

  @override
  String get recipeAiGenerating => 'レシピを生成中...';

  @override
  String get recipeAiWritingIngredients => '材料を書き出し中...';

  @override
  String get recipeAiCraftingInstructions => '手順を作成中...';

  @override
  String get recipeAiLimitReached => '上限に達しました';

  @override
  String get recipeAiGenerationFailed => '生成に失敗しました';

  @override
  String get recipeAiUpgradeToPlus => 'Plusにアップグレード';

  @override
  String get recipeAiTryAgain => 'もう一度試す';

  @override
  String get recipeAiSelectPantryItems => 'パントリーアイテムを選択';

  @override
  String get recipeAiSelectAll => 'すべて選択';

  @override
  String get recipeAiDeselectAll => 'すべて解除';

  @override
  String get recipeAiNoPantryItems => 'パントリーにアイテムがありません';

  @override
  String get recipeAiDifficultyEasy => '簡単';

  @override
  String get recipeAiDifficultyMedium => '普通';

  @override
  String get recipeAiDifficultyHard => '難しい';

  @override
  String get recipeUrlImportTitle => 'URLからインポート';

  @override
  String get recipeUrlImportSubtitle => 'レシピのURLを貼り付けてインポート';

  @override
  String get recipeUrlImportPlaceholder => 'https://example.com/recipe';

  @override
  String get recipeUrlImportButton => 'レシピをインポート';

  @override
  String get recipeUrlImporting => 'レシピをインポート中';

  @override
  String get recipeUrlFetching => 'レシピを取得中...';

  @override
  String get recipeUrlExtracting => 'レシピを抽出中...';

  @override
  String get recipeUrlExtractionFailed => '抽出に失敗しました';

  @override
  String get recipeUrlOffline => 'オフラインです。インターネット接続を確認してください。';

  @override
  String get recipeUrlInvalid => '有効なURLを入力してください。';

  @override
  String get recipeUrlNoRecipe => 'このページにはレシピ情報が含まれていないようです。';

  @override
  String get recipeUrlPreviewLimitReached => 'プレビュー上限に達しました';

  @override
  String get recipeUrlImportFailed => 'インポートに失敗しました';

  @override
  String get recipeUrlPreviewLimit =>
      '無料ユーザーはレシピのプレビューが制限されています。Plusにアップグレードすると無制限でインポートできます。';

  @override
  String get recipeUrlPlusRequired => 'このページのレシピ抽出にはPlusサブスクリプションが必要です。';

  @override
  String get recipeUrlSomethingWrong => 'エラーが発生しました。もう一度お試しください。';

  @override
  String get recipeUrlNoRecipeFound => 'このページにレシピが見つかりませんでした。';

  @override
  String get recipeUrlFailedExtract => 'レシピの抽出に失敗しました。もう一度お試しください。';

  @override
  String get recipePhotoProcessing => '写真を処理中';

  @override
  String get recipePhotoReading => '写真を読み取り中...';

  @override
  String get recipePhotoProcessingStatus => '写真を処理中...';

  @override
  String get recipePhotoExtracting => 'レシピを抽出中...';

  @override
  String get recipePhotoNoRecipe =>
      '写真にレシピが見つかりませんでした。\n\nレシピカードや料理本のページの写真をお試しください。';

  @override
  String get recipePhotoFailed => '画像の処理に失敗しました。もう一度お試しください。';

  @override
  String get recipePhotoOffline => 'オフラインです。インターネット接続を確認して、もう一度お試しください。';

  @override
  String get recipeEditorNewRecipe => '新しいレシピ';

  @override
  String get recipeEditorAddImages => '画像を追加';

  @override
  String get recipeEditorAddIngredients => '材料を追加';

  @override
  String get recipeEditorAddInstructions => '手順を追加';

  @override
  String get recipeEditorAddNotes => 'メモを追加';

  @override
  String get recipeEditorNotesPlaceholder => 'このレシピに関するメモ';

  @override
  String get recipeEditorSourcePlaceholder => '出典（任意）';

  @override
  String get recipeEditorRating => '評価';

  @override
  String get recipeEditorClearAllIngredients => 'すべての材料をクリア？';

  @override
  String get recipeEditorClearAllSteps => 'すべての手順をクリア？';

  @override
  String recipeEditorClearConfirm(int count, String type) {
    return '$count個の$typeがすべて削除されます。この操作は取り消せません。';
  }

  @override
  String get recipeEditorClearAll => 'すべてクリア';

  @override
  String get recipeEditorNewSection => '新しいセクション';

  @override
  String recipeEditorSaveFailed(String error) {
    return 'レシピの保存に失敗しました: $error';
  }

  @override
  String get recipeViewIngredients => '材料';

  @override
  String get recipeViewInstructions => '手順';

  @override
  String get recipeViewScaleConvert => '分量の変換';

  @override
  String get recipeViewNoIngredients => '材料が登録されていません。';

  @override
  String get recipeViewNoInstructions => '手順が登録されていません。';

  @override
  String get recipeTagSelectTitle => 'タグを選択';

  @override
  String get recipeTagCreateNew => '新しいタグを作成';

  @override
  String get recipeTagNoTags => 'タグがありません';

  @override
  String get recipeTagCreateFirst => '上のボタンから最初のタグを作成してください';

  @override
  String get recipeTagName => 'タグ名';

  @override
  String get recipeTagEnterName => 'タグ名を入力';

  @override
  String get recipeTagColor => 'タグの色';

  @override
  String get recipeTagCreate => '作成';

  @override
  String get recipeTagExists => 'この名前のタグは既に存在します';

  @override
  String get recipeFolderSelectTitle => 'レシピをフォルダに追加';

  @override
  String get recipeFolderCreateFirst => '上のボタンから最初のフォルダを作成してください';

  @override
  String get recipeFolderExists => 'この名前のフォルダは既に存在します';

  @override
  String get recipeFilterResetAll => 'すべてリセット';

  @override
  String get recipeFilterApply => '変更を適用';

  @override
  String get recipeFilterCookTime => '調理時間';

  @override
  String get recipeFilterRating => '評価';

  @override
  String get recipeFilterPantryMatch => 'パントリー一致';

  @override
  String get recipeFilterTags => 'タグ';

  @override
  String get recipeFilterMustHaveAllTags => 'すべてのタグを含む';

  @override
  String get recipeFilterSort => '並び替え';

  @override
  String recipeFilterSortBy(String option) {
    return '$optionで並び替え';
  }

  @override
  String get recipeFilterMatchAny => 'すべてのレシピを表示（在庫不要）';

  @override
  String get recipeFilterFewIngredients => '一部の材料が在庫あり（25%）';

  @override
  String get recipeFilterHalfIngredients => '半分以上の材料が在庫あり（50%）';

  @override
  String get recipeFilterMostIngredients => 'ほとんどの材料が在庫あり（75%）';

  @override
  String get recipeFilterAllIngredients => 'すべての材料が在庫あり（100%）';

  @override
  String recipeFilterPercentMatch(int percent) {
    return '$percent%一致';
  }

  @override
  String get recipeCookAddRecipe => 'レシピを追加';

  @override
  String get recipeCookComplete => '調理完了';

  @override
  String get recipeCookAddRecipeTitle => '調理するレシピを追加';

  @override
  String get recipeCookNoSteps => 'このレシピには手順がありません';

  @override
  String get recipeCookPrevious => '前へ';

  @override
  String get recipeCookNext => '次へ';

  @override
  String get recipeIngredientLinkToRecipe => 'レシピにリンク';

  @override
  String get recipeIngredientConvertToIngredient => '材料に変換';

  @override
  String get recipeIngredientSectionName => 'セクション名';

  @override
  String get recipeIngredientLinkExisting => '既存のレシピにリンク';

  @override
  String get recipeIngredientChangeLinked => 'リンク先のレシピを変更';

  @override
  String get recipeIngredientRemoveLink => 'レシピリンクを削除';

  @override
  String get recipeIngredientNoRecipesFound => 'レシピが見つかりません';

  @override
  String get recipeIngredientNoRecipesMatch => '検索に一致するレシピがありません';

  @override
  String get recipeStepNextStep => '次のステップ';

  @override
  String get recipeStepConvertToStep => '手順に変換';

  @override
  String get recipeStepConvertToSection => 'セクションに変換';

  @override
  String get recipeStepDescribe => 'この手順を説明してください';

  @override
  String get recipeEditIngredientsTitle => '材料を編集';

  @override
  String get recipeEditStepsTitle => '手順を編集';

  @override
  String get recipeEditUpdate => '更新';

  @override
  String get recipeAddToShoppingList => '買い物リストに追加';

  @override
  String get recipeAddToShoppingListButton => '買い物リストに追加';

  @override
  String get recipeAddToShoppingListAdding => '追加中...';

  @override
  String get recipeAddToShoppingListNoIngredients => '追加する材料がありません';

  @override
  String get recipeAddToShoppingListDefault => '買い物リスト';

  @override
  String get recipeWelcomeGettingStarted => 'はじめに';

  @override
  String get recipeWelcomeTitle => 'Stockpotへようこそ！';

  @override
  String get recipeWelcomeSubtitle => '最初のレシピを作成して\nコレクションを始めましょう';

  @override
  String get recipeTileEdit => 'レシピを編集';

  @override
  String get recipeTileDelete => 'レシピを削除';

  @override
  String get recipeSearchPlaceholder => '追加するレシピを検索';

  @override
  String get recipeSearchNoResults => 'レシピが見つかりません';

  @override
  String get recipeSearchTryDifferent => '別の検索ワードをお試しください';

  @override
  String get recipeSearchClearFilters => 'フィルターをクリア';

  @override
  String get recipeSearchFilterSort => 'フィルターと並び替え';

  @override
  String get recipeAddRecipeButton => 'レシピを追加';

  @override
  String get recipeFolderNoRecipesMatch => '現在のフィルターに一致するレシピはありません';

  @override
  String get recipeFolderNoTagsMatch => '選択したタグに一致するレシピはありません';

  @override
  String get recipeFolderNoIngredientsMatch => '選択した材料に一致するレシピはありません';

  @override
  String get recipeEditSmartFolder => 'スマートフォルダを編集';

  @override
  String get recipeCookTimeUnder30 => '30分未満';

  @override
  String get recipeCookTime30To60 => '30〜60分';

  @override
  String get recipeCookTime1To2Hours => '1〜2時間';

  @override
  String get recipeCookTimeOver2Hours => '2時間以上';

  @override
  String get recipeSortPantryMatch => 'パントリーマッチ %';

  @override
  String get recipeSortAlphabetical => 'アルファベット順';

  @override
  String get recipeSortRating => '評価';

  @override
  String get recipeSortTime => '時間';

  @override
  String get recipeSortAddedDate => '追加日';

  @override
  String get recipeSortUpdatedDate => '更新日';

  @override
  String recipeSearchError(String error) {
    return 'エラー: $error';
  }

  @override
  String get recipeAddModalNew => '新しいレシピ';

  @override
  String get recipeAddModalEdit => 'レシピを編集';

  @override
  String get recipeAddModalCreate => '作成';

  @override
  String get recipeAddModalUpdate => '更新';

  @override
  String recipeAddModalFailed(String message) {
    return 'レシピの追加に失敗しました: $message';
  }

  @override
  String get recipeAddModalCannotAdd => 'レシピを追加できません';

  @override
  String get recipeAddModalAdd => '追加';

  @override
  String get commonSave => '保存';

  @override
  String get commonDone => '完了';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonBack => '戻る';

  @override
  String get commonIngredient => '材料';

  @override
  String get commonIngredients => '材料';

  @override
  String get commonStep => '手順';

  @override
  String get commonSteps => '手順';

  @override
  String get recipeStepAddStep => '手順を追加';

  @override
  String get recipeStepAddSection => 'セクションを追加';

  @override
  String get recipeStepEditAsText => 'テキストとして編集';

  @override
  String get recipeStepClearAll => 'すべての手順をクリア';

  @override
  String get recipeStepNoSteps => '手順がまだ追加されていません。';

  @override
  String get recipePinnedTitle => 'ピン留めしたレシピ';

  @override
  String recipePinnedNoMatch(String query) {
    return '「$query」に一致するピン留めレシピはありません';
  }

  @override
  String get recipePinnedEmpty =>
      'ピン留めしたレシピはまだありません。\nお気に入りのレシピをピン留めしてここに表示しましょう。';

  @override
  String get recipePinnedNoResults => 'レシピが見つかりません';

  @override
  String get recipeMatchTitle => 'パントリーマッチ';

  @override
  String recipeMatchSummary(int matched, int total) {
    return 'パントリーマッチ: $total材料中$matched個';
  }

  @override
  String recipeMatchMatchedWith(String name) {
    return 'マッチ: $name';
  }

  @override
  String get recipeMatchTermsTitle => 'マッチング用語';

  @override
  String get recipeMatchAddTerm => '用語を追加';

  @override
  String get recipeMatchNoTerms =>
      'この材料には追加の用語がありません。パントリーマッチを改善するには用語を追加してください。';

  @override
  String get recipeMatchTip => 'ヒント: パントリーアイテム名に一致する用語を追加してマッチングを改善しましょう。';

  @override
  String recipeMatchSource(String source) {
    return 'ソース: $source';
  }

  @override
  String get recipeMatchAddTermTitle => 'マッチング用語を追加';

  @override
  String get recipeMatchTermLabel => '用語';

  @override
  String get recipeMatchTermHint => 'マッチング用語を入力（例: パントリーアイテム名）';

  @override
  String get recipeEditorRecipeTitle => 'レシピタイトル';

  @override
  String get recipeEditorDescriptionOptional => '説明（任意）';

  @override
  String get recipeEditorPrepTime => '下準備時間';

  @override
  String get recipeEditorCookTime => '調理時間';

  @override
  String get recipeEditorServings => '人数';

  @override
  String get recipeEditorFolders => 'フォルダ';

  @override
  String get recipeEditorNoFolders => 'フォルダなし';

  @override
  String get recipeEditorOneFolder => '1つのフォルダ';

  @override
  String recipeEditorFolderCount(int count) {
    return '$count個のフォルダ';
  }

  @override
  String get recipeEditorTakePhoto => '写真を撮る';

  @override
  String get recipeEditorChooseFromGallery => 'ギャラリーから選択';

  @override
  String get recipeEditorDeleteImage => '画像を削除';

  @override
  String get recipeEditorDeleteImageConfirm => 'この画像を削除してもよろしいですか？';

  @override
  String get recipeEditorTags => 'タグ';

  @override
  String get recipeEditorEditTags => 'タグを編集';

  @override
  String get recipeEditorNoTagsAssigned => 'タグが設定されていません';

  @override
  String get commonEnterValue => '値を入力';

  @override
  String get commonUpdate => '更新';

  @override
  String get durationPickerTitle => '時間を選択';

  @override
  String get durationPickerHours => '時間';

  @override
  String get durationPickerMinutes => '分';

  @override
  String get durationPickerSeconds => '秒';

  @override
  String get folderUncategorized => '未分類';

  @override
  String get folderNoRecipes => 'レシピなし';

  @override
  String get folderOneRecipe => '1件のレシピ';

  @override
  String folderRecipeCount(int count) {
    return '$count件のレシピ';
  }

  @override
  String get folderRename => 'フォルダ名を変更';

  @override
  String get folderEditSmart => 'スマートフォルダを編集';

  @override
  String get folderDelete => 'フォルダを削除';

  @override
  String get commonViewAll => 'すべて表示';

  @override
  String get recipeRecentlyViewedTitle => '最近見たレシピ';

  @override
  String get recipeRecentlyViewedEmpty => '最近見たレシピはありません。\nレシピを探索してここに表示しましょう。';

  @override
  String durationMinutesShort(int count) {
    return '$count分';
  }

  @override
  String durationHoursShort(int count) {
    return '$count時間';
  }

  @override
  String durationHoursMinutesShort(int hours, int minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String recipeServingsCount(int count) {
    return '$count人前';
  }

  @override
  String get recipeMetadataServings => '人数';

  @override
  String get recipeMetadataPrepTime => '下準備';

  @override
  String get recipeMetadataCookTime => '調理時間';

  @override
  String get recipeMetadataTotal => '合計';

  @override
  String get recipeMetadataRating => '評価';

  @override
  String get recipeMetadataNotes => 'メモ';

  @override
  String recipeMetadataSource(String source) {
    return '出典: $source';
  }

  @override
  String get recipeMetadataSourceLabel => '出典: ';

  @override
  String get recipeCookStartCooking => '調理を開始';

  @override
  String get recipeCookResumeCooking => '調理を再開';

  @override
  String get recipePageEditRecipe => 'レシピを編集';

  @override
  String get recipePageCheckPantryStock => 'パントリー在庫を確認';

  @override
  String get scaleConvertReset => 'リセット';

  @override
  String get scaleConvertScale => '倍率';

  @override
  String get scaleConvertConvert => '単位変換';

  @override
  String get scaleConvertIngredient => '材料';

  @override
  String get scaleConvertSelectIngredient => '材料を選択';

  @override
  String get scaleTypeAmount => '倍率';

  @override
  String get scaleTypeServings => '人数';

  @override
  String scaleSliderAmount(String value) {
    return '倍率: ${value}x';
  }

  @override
  String scaleSliderServings(int count) {
    return '人数: $count';
  }

  @override
  String scaleSliderIngredientAmount(String value) {
    return '分量: $value';
  }

  @override
  String get conversionModeOriginal => 'オリジナル';

  @override
  String get conversionModeImperial => 'ヤード・ポンド法';

  @override
  String get conversionModeMetric => 'メートル法';

  @override
  String cookStepProgress(int current, int total) {
    return 'ステップ $current / $total';
  }

  @override
  String cookPercentComplete(int percent) {
    return '$percent% 完了';
  }

  @override
  String get cookRecipeNotFound => 'レシピが見つかりません';

  @override
  String get cookNoStepsValidation =>
      'このレシピにはまだ調理手順がありません。調理を開始する前にレシピに手順を追加してください。';

  @override
  String get ingredientsSheetTitle => '材料';

  @override
  String get ingredientsSheetScaleConvert => '分量変換';

  @override
  String get timerStartTitle => 'タイマーを開始しますか？';

  @override
  String timerStartMessage(
      String duration, String recipeName, int stepNumber, int totalSteps) {
    return '$recipeNameの\nステップ $stepNumber / $totalSteps\n$durationのタイマーを開始';
  }

  @override
  String get timerStart => '開始';

  @override
  String get timerStartFailed => 'タイマーの開始に失敗しました。もう一度お試しください。';

  @override
  String get timerNotificationsTitle => 'タイマー通知を有効にする';

  @override
  String get timerNotificationsMessage =>
      'アプリがバックグラウンドにあっても、調理タイマーが完了したときに通知を受け取れます。';

  @override
  String get timerNotificationsNotNow => '後で';

  @override
  String get timerNotificationsEnable => '有効にする';
}
