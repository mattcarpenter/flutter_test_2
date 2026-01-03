import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Custom Japanese Cupertino localizations that provides a shorter
/// cancel button label to fit in the search bar's fixed-width button.
///
/// Flutter's default Japanese uses "キャンセル" (5 chars) which gets
/// clipped in the 67px cancel button. We use "戻る" (2 chars) instead.
class CustomJapaneseCupertinoLocalizations implements CupertinoLocalizations {
  final CupertinoLocalizations _delegate;

  CustomJapaneseCupertinoLocalizations(this._delegate);

  // Override only the cancel button label
  @override
  String get cancelButtonLabel => '戻る';

  // Delegate everything else to the default implementation
  @override
  String get alertDialogLabel => _delegate.alertDialogLabel;
  @override
  String get anteMeridiemAbbreviation => _delegate.anteMeridiemAbbreviation;
  @override
  String get backButtonLabel => _delegate.backButtonLabel;
  @override
  String get clearButtonLabel => _delegate.clearButtonLabel;
  @override
  String get collapsedHint => _delegate.collapsedHint;
  @override
  String get copyButtonLabel => _delegate.copyButtonLabel;
  @override
  String get cutButtonLabel => _delegate.cutButtonLabel;
  @override
  DatePickerDateOrder get datePickerDateOrder => _delegate.datePickerDateOrder;
  @override
  DatePickerDateTimeOrder get datePickerDateTimeOrder => _delegate.datePickerDateTimeOrder;
  @override
  String datePickerDayOfMonth(int dayIndex, [int? weekDay]) => _delegate.datePickerDayOfMonth(dayIndex, weekDay);
  @override
  String datePickerHour(int hour) => _delegate.datePickerHour(hour);
  @override
  String? datePickerHourSemanticsLabel(int hour) => _delegate.datePickerHourSemanticsLabel(hour);
  @override
  String datePickerMediumDate(DateTime date) => _delegate.datePickerMediumDate(date);
  @override
  String datePickerMinute(int minute) => _delegate.datePickerMinute(minute);
  @override
  String? datePickerMinuteSemanticsLabel(int minute) => _delegate.datePickerMinuteSemanticsLabel(minute);
  @override
  String datePickerMonth(int monthIndex) => _delegate.datePickerMonth(monthIndex);
  @override
  String datePickerStandaloneMonth(int monthIndex) => _delegate.datePickerStandaloneMonth(monthIndex);
  @override
  String datePickerYear(int yearIndex) => _delegate.datePickerYear(yearIndex);
  @override
  String get expandedHint => _delegate.expandedHint;
  @override
  String get expansionTileCollapsedHint => _delegate.expansionTileCollapsedHint;
  @override
  String get expansionTileCollapsedTapHint => _delegate.expansionTileCollapsedTapHint;
  @override
  String get expansionTileExpandedHint => _delegate.expansionTileExpandedHint;
  @override
  String get expansionTileExpandedTapHint => _delegate.expansionTileExpandedTapHint;
  @override
  String get lookUpButtonLabel => _delegate.lookUpButtonLabel;
  @override
  String get menuDismissLabel => _delegate.menuDismissLabel;
  @override
  String get modalBarrierDismissLabel => _delegate.modalBarrierDismissLabel;
  @override
  String get noSpellCheckReplacementsLabel => _delegate.noSpellCheckReplacementsLabel;
  @override
  String get pasteButtonLabel => _delegate.pasteButtonLabel;
  @override
  String get postMeridiemAbbreviation => _delegate.postMeridiemAbbreviation;
  @override
  String get searchTextFieldPlaceholderLabel => _delegate.searchTextFieldPlaceholderLabel;
  @override
  String get searchWebButtonLabel => _delegate.searchWebButtonLabel;
  @override
  String get selectAllButtonLabel => _delegate.selectAllButtonLabel;
  @override
  String get shareButtonLabel => _delegate.shareButtonLabel;
  @override
  String tabSemanticsLabel({required int tabIndex, required int tabCount}) =>
      _delegate.tabSemanticsLabel(tabIndex: tabIndex, tabCount: tabCount);
  @override
  String timerPickerHour(int hour) => _delegate.timerPickerHour(hour);
  @override
  String? timerPickerHourLabel(int hour) => _delegate.timerPickerHourLabel(hour);
  @override
  List<String> get timerPickerHourLabels => _delegate.timerPickerHourLabels;
  @override
  String timerPickerMinute(int minute) => _delegate.timerPickerMinute(minute);
  @override
  String? timerPickerMinuteLabel(int minute) => _delegate.timerPickerMinuteLabel(minute);
  @override
  List<String> get timerPickerMinuteLabels => _delegate.timerPickerMinuteLabels;
  @override
  String timerPickerSecond(int second) => _delegate.timerPickerSecond(second);
  @override
  String? timerPickerSecondLabel(int second) => _delegate.timerPickerSecondLabel(second);
  @override
  List<String> get timerPickerSecondLabels => _delegate.timerPickerSecondLabels;
  @override
  String get todayLabel => _delegate.todayLabel;
}

/// Delegate that provides custom Japanese Cupertino localizations.
/// For Japanese locale, it wraps the default localizations with our custom one.
/// For other locales, it returns null to fall back to GlobalCupertinoLocalizations.
class CustomCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const CustomCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ja';

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    // Load the default Japanese localizations first
    final defaultLocalizations = await GlobalCupertinoLocalizations.delegate.load(locale);
    // Wrap with our custom implementation
    return CustomJapaneseCupertinoLocalizations(defaultLocalizations);
  }

  @override
  bool shouldReload(CustomCupertinoLocalizationsDelegate old) => false;
}
