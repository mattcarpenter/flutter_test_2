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
}
