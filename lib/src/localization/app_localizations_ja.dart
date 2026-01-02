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
}
