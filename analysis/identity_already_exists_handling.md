# Handling "Identity Already Exists" Error for Anonymous Users

## The Problem

When an anonymous user taps Google/Apple sign-in, we use `linkIdentity()` to upgrade their account. If the OAuth identity is already linked to a different Stockpot account, the deep link returns with `error_code=identity_already_exists`.

Currently:
- The error is logged by Supabase but not surfaced to the UI
- User remains on anonymous account with no feedback
- User is confused because they know they have an account

## Desired Behavior

Show a warning dialog explaining the situation and offering to sign into the existing account (with data loss warning for anonymous user's local data).

## Scope

This affects:
- Google OAuth on Sign Up page
- Google OAuth on Sign In page
- Apple OAuth on Sign Up page
- Apple OAuth on Sign In page

Note: Email/password sign-in is NOT affected - it directly signs into the existing account without linkIdentity.

## Proposed Solution

### Overview

1. Track which OAuth provider is pending when linkIdentity is launched
2. Detect the error from the deep link URL in GoRouter
3. Redirect back to auth page with error info
4. Auth page shows warning dialog
5. User confirms → sign in with native OAuth (forceNativeOAuth: true)

### Implementation Details

#### 1. Add State Tracking in AuthState

Add field to track the pending linkIdentity provider:

```dart
// In auth_state.dart
@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    // ... existing fields ...

    /// The OAuth provider for a pending linkIdentity operation.
    /// Used to retry with native OAuth if linkIdentity fails.
    OAuthProvider? pendingLinkIdentityProvider,
  }) = _AuthState;
}
```

#### 2. Set Provider Before linkIdentity

In `auth_provider.dart`, set the pending provider before calling signInWithGoogle/Apple:

```dart
Future<void> signInWithGoogle({bool forceNativeOAuth = false}) async {
  // Track pending provider for anonymous users using linkIdentity
  if (!forceNativeOAuth && _authService.isAnonymousUser) {
    state = state.copyWith(pendingLinkIdentityProvider: OAuthProvider.google);
  }

  state = state.copyWith(
    isSigningInWithGoogle: true,
    error: null,
    successMessage: null,
  );
  // ... rest of method
}
```

Same for `signInWithApple` with `OAuthProvider.apple`.

#### 3. Clear Provider on Success

In `_initializeAuthState`, when auth state changes to signedIn with non-anonymous user:

```dart
case AuthChangeEvent.signedIn:
case AuthChangeEvent.userUpdated:
  if (authState.session?.user != null) {
    final user = authState.session!.user;
    final isAnon = AuthService.isUserAnonymous(user);
    state = state.copyWith(
      currentUser: user,
      isAnonymous: isAnon,
      // Clear pending provider on successful auth
      pendingLinkIdentityProvider: isAnon ? state.pendingLinkIdentityProvider : null,
      // ... other fields
    );
  }
```

#### 4. Handle Error in GoRouter

Modify the `/auth-callback` route to detect errors:

```dart
GoRoute(
  path: '/auth-callback',
  redirect: (context, state) {
    final errorCode = state.uri.queryParameters['error_code'];

    if (errorCode == 'identity_already_exists') {
      // Redirect to auth page with error flag
      // The auth page will show the dialog
      return '/auth?identity_exists_error=true';
    }

    // Success case - go to recipes
    return '/recipes';
  },
),
```

#### 5. Handle Error in Sign Up Page

In `sign_up_page.dart`, check for the error query param and show dialog:

```dart
@override
void initState() {
  super.initState();

  // Check for identity exists error from deep link
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final uri = GoRouterState.of(context).uri;
    if (uri.queryParameters['identity_exists_error'] == 'true') {
      _handleIdentityExistsError();
    }
  });
}

Future<void> _handleIdentityExistsError() async {
  final pendingProvider = ref.read(authNotifierProvider).pendingLinkIdentityProvider;
  if (pendingProvider == null) return;

  // Clear the pending provider
  ref.read(authNotifierProvider.notifier).clearPendingLinkIdentityProvider();

  // Show warning dialog
  final shouldContinue = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('Account Already Exists'),
      content: Text(
        'This ${pendingProvider == OAuthProvider.google ? 'Google' : 'Apple'} account '
        'is already linked to a Stockpot account.\n\n'
        'If you continue, your current local recipes will be replaced with that account\'s data.',
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          child: const Text('Sign In Anyway'),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  ) ?? false;

  if (!shouldContinue) return;

  // Sign in with native OAuth (bypasses linkIdentity)
  try {
    if (pendingProvider == OAuthProvider.google) {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle(forceNativeOAuth: true);
    } else {
      await ref.read(authNotifierProvider.notifier).signInWithApple(forceNativeOAuth: true);
    }
    if (mounted) {
      context.go('/recipes');
    }
  } catch (e) {
    if (mounted) {
      await ErrorDialog.show(
        context,
        message: 'Failed to sign in. Please try again.',
      );
    }
  }
}
```

#### 6. Same Handling in Sign In Page

Add the same error handling to `sign_in_page.dart`. The dialog text can be slightly different since they're explicitly signing in:

```dart
content: Text(
  'This ${providerName} account is already linked to a Stockpot account.\n\n'
  'Your current local data will be replaced with that account\'s data.',
),
```

#### 7. Add Helper Method to AuthNotifier

```dart
void clearPendingLinkIdentityProvider() {
  state = state.copyWith(pendingLinkIdentityProvider: null);
}
```

### Files to Modify

| File | Changes |
|------|---------|
| `lib/src/features/auth/models/auth_state.dart` | Add `pendingLinkIdentityProvider` field |
| `lib/src/providers/auth_provider.dart` | Set/clear pending provider, add helper method |
| `lib/src/mobile/adaptive_app.dart` | Update auth-callback route to detect error |
| `lib/src/features/auth/views/sign_up_page.dart` | Handle identity_exists_error param, show dialog |
| `lib/src/features/auth/views/sign_in_page.dart` | Handle identity_exists_error param, show dialog |

### Edge Cases

1. **User navigates away before dialog appears** - The pendingLinkIdentityProvider state persists until cleared, so if they come back to auth page, we should clear it to avoid showing stale dialogs.

2. **Multiple rapid taps** - The guard `if (authState.isSigningInWithGoogle) return;` prevents this.

3. **Deep link arrives while app is backgrounded** - GoRouter handles the deep link when app resumes, redirect logic still works.

### Testing Plan

1. Create anonymous account
2. Create separate real account with Google
3. From anonymous, tap Google sign-in
4. Complete OAuth with the same Google account
5. Verify error dialog appears
6. Tap "Sign In Anyway"
7. Verify signed into real account

Repeat for Apple OAuth on both sign-up and sign-in pages.