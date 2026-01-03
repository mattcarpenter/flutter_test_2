# Localization (i18n) Implementation Plan

**Goal**: Support English (en) and Japanese (ja) for the mobile app
**Scope**: Mobile only (`lib/src/mobile/adaptive_app.dart`) - excludes Windows/macOS/backend
**Out of Scope**: Unit conversions based on locale (e.g., cups to grams)

---

## Executive Summary

This plan outlines a phased approach to localize the Stockpot recipe app. The existing infrastructure is **90% ready** - Flutter's l10n system is configured, dependencies are installed, and generated localization classes exist. The primary work is:

1. Integrating the existing `AppLocalizations` delegate into the app
2. Creating the Japanese ARB file
3. Extracting ~600+ hardcoded strings across ~280 files into ARB format
4. Replacing hardcoded strings with `AppLocalizations.of(context)!.keyName` calls

**Estimated scope**: ~225 feature files + ~59 widget files + ~10 mobile/utility files = **~280-300 files** to process.

---

## Current State

### Infrastructure (Already Configured)

| Component | Status | Location |
|-----------|--------|----------|
| l10n.yaml | Configured | `/l10n.yaml` |
| flutter_localizations | Installed | pubspec.yaml |
| intl package | Installed (0.20.2) | pubspec.yaml |
| ARB directory | Exists | `lib/src/localization/` |
| English ARB | Exists (1 string only) | `lib/src/localization/app_en.arb` |
| Generated classes | Exists | `lib/src/localization/app_localizations.dart` |
| pubspec generate: true | Configured | pubspec.yaml |

### Gap Analysis

| What's Missing | Required Action |
|----------------|-----------------|
| `AppLocalizations.delegate` not in app | Add to localizationsDelegates in adaptive_app.dart |
| Japanese ARB file | Create `app_ja.arb` |
| supportedLocales only has English | Add `Locale('ja')` |
| ~600 hardcoded strings | Extract to ARB files |
| No locale switching UI | Add to settings (optional for MVP) |
| iOS Info.plist locales | Add ja to CFBundleLocalizations |

---

## Phase 1: Infrastructure Setup

**Objective**: Get the localization system fully wired up and testable

### 1.1 Update adaptive_app.dart

File: `lib/src/mobile/adaptive_app.dart`

**Current** (lines 118-126 and 146-154):
```dart
localizationsDelegates: const [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  FlutterQuillLocalizations.delegate,
],
supportedLocales: const [
  Locale('en', ''),
],
```

**Target**:
```dart
import '../localization/app_localizations.dart';

// ... then in both CupertinoApp.router and MaterialApp.router:
localizationsDelegates: const [
  AppLocalizations.delegate,  // ADD THIS
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  FlutterQuillLocalizations.delegate,
],
supportedLocales: const [
  Locale('en'),
  Locale('ja'),  // ADD THIS
],
```

### 1.2 Create Japanese ARB File

File: `lib/src/localization/app_ja.arb`

```json
{
  "@@locale": "ja",
  "appTitle": "Stockpot"
}
```

### 1.3 Update iOS Configuration

File: `ios/Runner/Info.plist`

Add `ja` to CFBundleLocalizations array:
```xml
<key>CFBundleLocalizations</key>
<array>
  <string>en</string>
  <string>ja</string>
</array>
```

### 1.4 Regenerate Localizations

```bash
flutter pub get
flutter gen-l10n
```

This generates:
- `lib/src/localization/app_localizations.dart` (updated)
- `lib/src/localization/app_localizations_en.dart` (updated)
- `lib/src/localization/app_localizations_ja.dart` (new)

### 1.5 Create Helper Extension (Optional but Recommended)

File: `lib/src/localization/l10n_extension.dart`

```dart
import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

/// Convenience extension for accessing localizations
extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
```

This allows cleaner syntax: `context.l10n.keyName` instead of `AppLocalizations.of(context)!.keyName`

---

## Phase 2: Pilot Feature (Validate Infrastructure)

**Objective**: Localize one complete feature to validate the infrastructure works end-to-end

**Recommended pilot**: `auth` feature (12 files, self-contained, high visibility)

### 2.1 Audit auth Feature Strings

Files to process:
- `lib/src/features/auth/views/auth_landing_page.dart`
- `lib/src/features/auth/views/sign_in_page.dart`
- `lib/src/features/auth/views/sign_up_page.dart`
- `lib/src/features/auth/views/forgot_password_page.dart`

### 2.2 Add Strings to ARB Files

Example additions to `app_en.arb`:
```json
{
  "@@locale": "en",
  "appTitle": "Stockpot",

  "authSignIn": "Sign In",
  "authSignUp": "Sign Up",
  "authContinueWithEmail": "Continue with Email",
  "authContinueWithGoogle": "Continue with Google",
  "authContinueWithApple": "Continue with Apple",
  "authAlreadyHaveAccount": "Already have an account?",
  "authDontHaveAccount": "Don't have an account?",
  "authForgotPassword": "Forgot Password?",
  "authResetPassword": "Reset Password",
  "authPasswordResetSent": "Password reset email sent!",
  "authFailedGoogle": "Failed to sign in with Google. Please try again.",
  "authFailedApple": "Failed to sign in with Apple. Please try again.",
  "authEmailLabel": "Email",
  "authPasswordLabel": "Password",
  "authConfirmPasswordLabel": "Confirm Password"
}
```

Corresponding `app_ja.arb`:
```json
{
  "@@locale": "ja",
  "appTitle": "Stockpot",

  "authSignIn": "ログイン",
  "authSignUp": "新規登録",
  "authContinueWithEmail": "メールで続ける",
  "authContinueWithGoogle": "Googleで続ける",
  "authContinueWithApple": "Appleで続ける",
  "authAlreadyHaveAccount": "アカウントをお持ちの方",
  "authDontHaveAccount": "アカウントをお持ちでない方",
  "authForgotPassword": "パスワードをお忘れですか？",
  "authResetPassword": "パスワードをリセット",
  "authPasswordResetSent": "パスワードリセットメールを送信しました",
  "authFailedGoogle": "Googleログインに失敗しました。もう一度お試しください。",
  "authFailedApple": "Appleログインに失敗しました。もう一度お試しください。",
  "authEmailLabel": "メールアドレス",
  "authPasswordLabel": "パスワード",
  "authConfirmPasswordLabel": "パスワード（確認）"
}
```

### 2.3 Replace Hardcoded Strings

Example transformation in `auth_landing_page.dart`:

**Before**:
```dart
Text('Sign In')
```

**After**:
```dart
import '../../localization/l10n_extension.dart';

// In build method:
Text(context.l10n.authSignIn)
```

### 2.4 Test Both Languages

Test by changing device language or using a test override.

---

## Phase 3: Feature-by-Feature Rollout

**Objective**: Systematically localize all features in order of priority/complexity

### Feature Inventory & Prioritization

| Priority | Feature | Files | Complexity | Status | Notes |
|----------|---------|-------|------------|--------|-------|
| 1 | auth | 12 | Low | ✅ Done | Pilot feature, high visibility |
| 2 | settings | 25 | Medium | ✅ Done | User-facing settings, many labels |
| 3 | recipes | 71 | High | ✅ Done | Largest feature, core functionality |
| 4 | shopping_list | 17 | Medium | ✅ Done | Core feature |
| 5 | meal_plans | 22 | Medium | ✅ Done | Core feature |
| 6 | pantry | 11 | Low | ✅ Done | Core feature |
| 7 | clippings | 18 | Medium | ✅ Done | Labs feature |
| 8 | import_export | 22 | Medium | ✅ Done | Utility feature |
| 9 | household | 15 | Medium | ⏳ Pending | Sharing feature |
| 10 | help | 4 | Low | ✅ Done | Help documentation |
| 11 | share | 3 | Low | ⏳ Pending | Share previews |
| 12 | timers | 3 | Low | ✅ Done | Timer UI |
| 13 | discover | 1 | Low | ⏳ Pending | Discovery page |
| 14 | subscription | 1 | Low | ⏳ Pending | Paywall |

### Non-Feature Areas

| Area | Files | Status | Notes |
|------|-------|--------|-------|
| widgets/ | 59 | ⏳ Pending | Shared UI components |
| mobile/ | 7 | ⏳ Pending | Navigation labels, status bar |
| utils/ | ~5 | ⏳ Pending | Utility text (rare) |

---

## Phase 4: Shared Components

**Objective**: Localize shared widgets and mobile shell components

### 4.1 Navigation Labels

File: `lib/src/mobile/main_page_shell.dart`

Bottom navigation labels:
- "More"
- "Recipes"
- "Shopping"
- "Meal Plan"
- "Pantry"

File: `lib/src/mobile/app.dart` (legacy, may not need changes)

### 4.2 Global Status Bar

File: `lib/src/mobile/global_status_bar.dart`

Contains cooking mode text:
- "Cooking"
- "Timers"
- "Instructions"
- "Recipe"
- "Complete"
- "Extend 1 min"
- "Extend 5 min"
- "Cancel Timer"

### 4.3 Shared Widgets

Directory: `lib/src/widgets/`

Common patterns:
- Button labels ("Cancel", "Done", "Save", "Delete", "OK")
- Dialog titles and messages
- Empty state messages
- Error messages

---

## String Naming Conventions

### Key Naming Pattern

Use feature prefix + semantic name:
```
{feature}{Component}{Description}
```

Examples:
- `authSignIn` - Auth feature, Sign In button
- `recipeEditTitle` - Recipe feature, edit screen title
- `settingsAccountHeader` - Settings feature, account section header
- `shoppingListEmptyState` - Shopping list empty state message
- `commonCancel` - Common/shared cancel button
- `commonSave` - Common/shared save button
- `commonDelete` - Common/shared delete button

### ARB Structure Guidelines

```json
{
  "@@locale": "en",

  "// ===== Common/Shared =====": "",
  "commonCancel": "Cancel",
  "commonSave": "Save",
  "commonDone": "Done",
  "commonDelete": "Delete",
  "commonOk": "OK",
  "commonError": "Error",
  "commonRetry": "Retry",

  "// ===== Auth Feature =====": "",
  "authSignIn": "Sign In",
  "authSignUp": "Sign Up",

  "// ===== Recipes Feature =====": "",
  "recipesTitle": "Recipes",
  "recipesEmptyState": "No recipes yet"
}
```

### Parameterized Strings

For strings with dynamic content:
```json
{
  "recipesCount": "{count, plural, =0{No recipes} =1{1 recipe} other{{count} recipes}}",
  "@recipesCount": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

Usage:
```dart
context.l10n.recipesCount(recipes.length)
```

---

## Agentic Refactoring Instructions

When Claude Code processes each feature:

### Step 1: Audit the Feature
1. List all Dart files in the feature directory
2. Search for hardcoded strings using patterns:
   - `Text('` or `Text("`
   - `title: '` or `title: "`
   - `label: '` or `label: "`
   - `hintText: '` or `hintText: "`
   - `errorText: '` or `errorText: "`
   - `content: '` or `content: "`
   - `message: '` or `message: "`
   - `'` followed by English words in dialog/snackbar content

### Step 2: Extract Strings
1. Create a list of all unique user-facing strings
2. Generate ARB keys using naming convention
3. Add to both `app_en.arb` and `app_ja.arb`
4. Regenerate with `flutter gen-l10n`

### Step 3: Replace Strings
1. Add import: `import 'package:recipe_app/src/localization/l10n_extension.dart';`
2. Replace each hardcoded string with `context.l10n.keyName`
3. For strings in callbacks without context, pass context as parameter

### Step 4: Verify
1. Run `flutter analyze` to check for errors
2. Run the app and verify strings display correctly
3. Test with Japanese locale

### Tracking Progress

Use a checklist approach per feature:

```
## Feature: auth (12 files)
- [x] auth_landing_page.dart (15 strings)
- [x] sign_in_page.dart (8 strings)
- [x] sign_up_page.dart (10 strings)
- [x] forgot_password_page.dart (6 strings)
- [x] views/widgets/ subdirectory (if any)
```

---

## Special Considerations

### 1. FlutterQuill Rich Text

The app uses `flutter_quill` which has its own localization. This is already handled with `FlutterQuillLocalizations.delegate`.

### 2. Date/Time Formatting

Use `intl` package for locale-aware date formatting:
```dart
import 'package:intl/intl.dart';

final dateFormat = DateFormat.yMMMd(Localizations.localeOf(context).languageCode);
final formattedDate = dateFormat.format(date);
```

### 3. Number Formatting

Use `NumberFormat` from intl:
```dart
final numberFormat = NumberFormat.decimalPattern(Localizations.localeOf(context).languageCode);
```

### 4. Strings in Providers/Services

For strings that need to be displayed but are generated in providers/services:
- Pass the string key instead of the translated string
- Translate at the UI layer

### 5. Validation Messages

Form validation messages should be localized:
```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return context.l10n.validationRequired;
  }
  return null;
}
```

---

## Implementation Checklist

### Phase 1: Infrastructure ✅
- [x] Add `AppLocalizations.delegate` to `adaptive_app.dart`
- [x] Add `Locale('ja')` to `supportedLocales`
- [x] Create `app_ja.arb` with initial content
- [x] Update `ios/Runner/Info.plist` with ja locale
- [x] Create `l10n_extension.dart` helper
- [x] Run `flutter gen-l10n`
- [x] Verify app builds and runs

### Phase 2: Pilot Feature (auth) ✅
- [x] Audit auth feature for strings
- [x] Add auth strings to ARB files
- [x] Replace hardcoded strings in auth views
- [x] Test with English
- [x] Test with Japanese
- [x] Document any issues/learnings

### Phase 3: Core Features
- [x] settings (25 files) - ✅ Done
- [x] recipes (71 files) - ✅ Done
- [x] shopping_list (17 files) - ✅ Done
- [x] meal_plans (22 files) - ✅ Done
- [x] pantry (11 files) - ✅ Done

### Phase 4: Secondary Features
- [x] clippings (18 files) - ✅ Done
- [x] import_export (22 files) - ✅ Done
- [ ] household (15 files)
- [x] help (4 files) - ✅ Done
- [ ] share (3 files)
- [x] timers (3 files) - ✅ Done
- [ ] discover (1 file)
- [ ] subscription (1 file)

### Phase 5: Shared Components
- [ ] mobile/main_page_shell.dart (nav labels)
- [ ] mobile/global_status_bar.dart (cooking mode)
- [ ] widgets/ directory (59 files)

### Phase 6: Verification
- [ ] Full app test in English
- [ ] Full app test in Japanese
- [ ] Run `flutter analyze`
- [ ] Run existing tests
- [ ] Add locale switching in settings (optional)

---

## File Structure After Completion

```
lib/src/localization/
├── app_en.arb           # English strings (source of truth)
├── app_ja.arb           # Japanese strings
├── app_localizations.dart       # Generated base class
├── app_localizations_en.dart    # Generated English impl
├── app_localizations_ja.dart    # Generated Japanese impl
└── l10n_extension.dart          # Helper extension
```

---

## Notes for Japanese Translation

### General Guidelines
1. Keep translations concise - Japanese can be more compact
2. Use polite form (丁寧語) for user-facing text
3. Use appropriate honorifics where needed
4. Consider character width - Japanese characters are full-width

### Common Translations Reference

| English | Japanese |
|---------|----------|
| Cancel | キャンセル |
| Save | 保存 |
| Done | 完了 |
| Delete | 削除 |
| Edit | 編集 |
| Add | 追加 |
| Search | 検索 |
| Settings | 設定 |
| Error | エラー |
| Loading | 読み込み中 |
| Recipes | レシピ |
| Shopping List | 買い物リスト |
| Meal Plan | 献立 |
| Pantry | パントリー |
| Ingredients | 材料 |
| Instructions | 手順 |

---

## Estimated Effort

| Phase | Effort | Description |
|-------|--------|-------------|
| Phase 1 | 1-2 hours | Infrastructure setup |
| Phase 2 | 2-3 hours | Pilot feature (auth) |
| Phase 3 | 15-20 hours | Core features (~140 files) |
| Phase 4 | 8-10 hours | Secondary features (~60 files) |
| Phase 5 | 6-8 hours | Shared components (~65 files) |
| Phase 6 | 2-3 hours | Verification and testing |

**Total estimated effort**: 35-45 hours of focused work

This can be done incrementally, feature by feature, with the app remaining functional throughout.
