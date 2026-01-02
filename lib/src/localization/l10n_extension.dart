import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

/// Convenience extension for accessing localizations.
///
/// Usage:
/// ```dart
/// import 'package:recipe_app/src/localization/l10n_extension.dart';
///
/// // In a widget's build method:
/// Text(context.l10n.authSignIn)
/// ```
extension L10nExtension on BuildContext {
  /// Access the app's localized strings.
  ///
  /// This is a shorthand for `AppLocalizations.of(context)!`.
  /// The `!` is safe because we always have AppLocalizations.delegate
  /// in our app's localizationsDelegates.
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
