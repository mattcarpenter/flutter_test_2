# Proposal: Anonymous User IAP Support

**Date:** December 12, 2025
**Status:** Draft
**Author:** Claude Code

---

## Executive Summary

This proposal outlines how to support in-app purchases (IAP) for unauthenticated users by creating Supabase anonymous accounts at purchase time. The goal is to reduce friction in the purchase funnel while maintaining full functionality for authenticated users.

### Key Principles

1. **Minimize MAU Impact**: Only create anonymous accounts when a user initiates a purchase
2. **Preserve UX for "Logged Out" Users**: Anonymous users appear logged out in the UI
3. **Seamless Account Upgrade**: Anonymous → registered preserves entitlements automatically
4. **Feature Gating**: Certain features (household sharing) require full registration
5. **Data Safety**: Warn users about data loss when signing into existing accounts

---

## Current State Analysis

### How Authentication Works Today

```
┌─────────────────────────────────────────────────────────────────┐
│                    CURRENT AUTH FLOW                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  App Launch                                                     │
│      │                                                          │
│      ├─ Has Supabase session? ──┬── YES ─→ isAuthenticated=true │
│      │                          │                               │
│      │                          └── NO ──→ isAuthenticated=false│
│      │                                                          │
│  UI Decision:                                                   │
│      isAuthenticated=true  → Show user email, "Sign Out"        │
│      isAuthenticated=false → Show "Sign In" option              │
│                                                                 │
│  IAP Decision:                                                  │
│      hasUser=true  → Purchases.logIn(userId), grants work       │
│      hasUser=false → No logIn(), purchases orphaned             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Current Files & Key Logic

| File | Current Behavior |
|------|------------------|
| `auth_provider.dart` | `isAuthenticated = currentUser != null` |
| `subscription_service.dart:134-137` | Only calls `Purchases.logIn()` if `currentUser != null` |
| `subscription_service.dart:159` | `hasPlus()` returns `false` if no user |
| `webhookController.ts:72-76` | Silently skips if `user_id` not in Supabase auth |

### The Problem

When an unauthenticated user completes a purchase:
1. RevenueCat assigns a device-generated anonymous ID (not a Supabase UUID)
2. Webhook fires with `app_user_id` = RevenueCat's anonymous ID
3. Backend tries `getUserById(app_user_id)` → user not found → **skips subscription creation**
4. Purchase is orphaned - no way to claim it

---

## Proposed Solution

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      NEW ANONYMOUS IAP FLOW                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  User taps "Upgrade" (no Supabase session)                                  │
│      │                                                                      │
│      ▼                                                                      │
│  ┌─────────────────────────────────────────┐                                │
│  │  1. Create Supabase Anonymous User      │  ◄── NEW STEP                  │
│  │     signInAnonymously()                 │                                │
│  │     Returns: UUID (e.g., abc123...)     │                                │
│  └─────────────────────────────────────────┘                                │
│      │                                                                      │
│      ▼                                                                      │
│  ┌─────────────────────────────────────────┐                                │
│  │  2. Log into RevenueCat                 │                                │
│  │     Purchases.logIn(anonUserId)         │                                │
│  └─────────────────────────────────────────┘                                │
│      │                                                                      │
│      ▼                                                                      │
│  ┌─────────────────────────────────────────┐                                │
│  │  3. Present Paywall                     │                                │
│  │     RevenueCatUI.presentPaywall()       │                                │
│  └─────────────────────────────────────────┘                                │
│      │                                                                      │
│      ▼                                                                      │
│  Purchase completes → Webhook fires                                         │
│      │                                                                      │
│      ▼                                                                      │
│  ┌─────────────────────────────────────────┐                                │
│  │  4. Backend: app_user_id = anonUserId   │                                │
│  │     getUserById(anonUserId) → EXISTS    │  ◄── Now succeeds!             │
│  │     Upserts user_subscriptions          │                                │
│  └─────────────────────────────────────────┘                                │
│      │                                                                      │
│      ▼                                                                      │
│  PowerSync syncs → User has Plus entitlement                                │
│                                                                             │
│  UI: Still shows "Sign In" (anonymous users appear logged out)              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### New Concept: "Effective Authentication"

We need to distinguish between:

| Concept | Definition | Use Case |
|---------|------------|----------|
| **System Auth** | `currentUser != null` | PowerSync, RevenueCat, backend |
| **Effective Auth** | `currentUser != null && !isAnonymous` | UI display, feature gating |

```dart
// New providers
final isSystemAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).currentUser != null;
});

final isEffectivelyAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(authNotifierProvider).currentUser;
  if (user == null) return false;

  // Check is_anonymous claim in JWT or user metadata
  final isAnonymous = user.userMetadata?['is_anonymous'] == true ||
                      user.appMetadata?['provider'] == 'anonymous';
  return !isAnonymous;
});
```

---

## Detailed Implementation Plan

### Phase 1: Enable Supabase Anonymous Auth

#### 1.1 Supabase Dashboard Configuration

1. Go to Project Settings → Authentication
2. Enable "Anonymous Sign-Ins" under User Signups
3. Consider enabling CAPTCHA/Turnstile for abuse prevention
4. Note: IP-based rate limit is 30 anonymous sign-ins per hour

#### 1.2 Add Anonymous Auth to AuthService

**File:** `lib/src/services/auth_service.dart`

```dart
/// Create an anonymous Supabase user (for IAP without registration)
/// Returns the anonymous user's ID
Future<String> createAnonymousUser() async {
  try {
    final response = await _supabase.auth.signInAnonymously();

    if (response.user == null) {
      throw AuthApiException(
        message: 'Failed to create anonymous user',
        type: AuthErrorType.unknown,
      );
    }

    AppLogger.info('Created anonymous user: ${response.user!.id}');
    return response.user!.id;
  } on AuthException catch (e) {
    AppLogger.error('Anonymous sign-in failed', e);
    throw AuthApiException.fromAuthException(e);
  }
}

/// Check if current user is anonymous
bool get isAnonymousUser {
  final user = _supabase.auth.currentUser;
  if (user == null) return false;

  // Supabase sets is_anonymous in the JWT claims
  // Access via user metadata or check identities
  return user.identities?.isEmpty ?? true;
}
```

#### 1.3 Update AuthProvider

**File:** `lib/src/providers/auth_provider.dart`

```dart
// Add to AuthState model
@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    User? currentUser,
    @Default(false) bool isAnonymous,  // NEW
    // ... existing fields
  }) = _AuthState;

  // Update getter
  bool get isEffectivelyAuthenticated => currentUser != null && !isAnonymous;
}

// Update listener to track anonymous status
void _initializeAuthState() {
  _authSubscription = _authService.authStateChangesWithSession.listen((authState) {
    switch (authState.event) {
      case AuthChangeEvent.signedIn:
        final user = authState.session?.user;
        final isAnon = user?.identities?.isEmpty ?? true;

        state = state.copyWith(
          currentUser: user,
          isAnonymous: isAnon,
          // ...
        );
        break;
      // ...
    }
  });
}
```

#### 1.4 Add New Providers

**File:** `lib/src/providers/auth_provider.dart`

```dart
/// True if user has ANY Supabase session (including anonymous)
final isSystemAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).currentUser != null;
});

/// True only if user has a REAL account (not anonymous)
final isEffectivelyAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.currentUser != null && !authState.isAnonymous;
});

/// Check if current session is anonymous
final isAnonymousUserProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAnonymous;
});

// DEPRECATED: Keep for backwards compatibility, maps to isEffectivelyAuthenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(isEffectivelyAuthenticatedProvider);
});
```

---

### Phase 2: Update IAP Flow for Anonymous Users

#### 2.1 Modify SubscriptionService.presentPaywall()

**File:** `lib/src/services/subscription_service.dart`

```dart
/// Present paywall - creates anonymous user if needed
Future<bool> presentPaywall() async {
  try {
    // STEP 1: Ensure we have a Supabase user (anonymous or real)
    String? userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      // Create anonymous user for IAP
      AppLogger.info('No user session, creating anonymous user for IAP');
      userId = await _createAnonymousUserForPurchase();
    }

    // STEP 2: Ensure RevenueCat is initialized with user ID
    await _ensureInitialized();

    // STEP 3: Ensure RevenueCat knows about this user
    final currentRevenueCatUser = await Purchases.appUserID;
    if (currentRevenueCatUser != userId) {
      AppLogger.info('Syncing RevenueCat user ID: $userId');
      await Purchases.logIn(userId);
    }

    // STEP 4: Present paywall
    final result = await RevenueCatUI.presentPaywall();
    AppLogger.info('Paywall result: $result');

    final success = result == PaywallResult.purchased ||
                    result == PaywallResult.restored;

    if (success) {
      await refreshRevenueCatState();
    }

    return success;
  } on PlatformException catch (e) {
    // ... error handling
  }
}

/// Create anonymous Supabase user specifically for purchase
Future<String> _createAnonymousUserForPurchase() async {
  try {
    final response = await _supabase.auth.signInAnonymously();

    if (response.user == null) {
      throw SubscriptionApiException(
        message: 'Failed to create anonymous user for purchase',
        type: SubscriptionErrorType.unknown,
      );
    }

    final userId = response.user!.id;
    AppLogger.info('Created anonymous user for IAP: $userId');

    return userId;
  } catch (e) {
    AppLogger.error('Failed to create anonymous user for IAP', e);
    rethrow;
  }
}
```

#### 2.2 Update RevenueCat Initialization

**File:** `lib/src/services/subscription_service.dart`

```dart
Future<void> initialize() async {
  if (_isInitialized) return;

  // ... existing completer logic

  try {
    final configuration = PurchasesConfiguration(_apiKey);
    await Purchases.configure(configuration);

    // UPDATED: Log in with user ID if we have ANY session (including anonymous)
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      await Purchases.logIn(currentUser.id);
      AppLogger.info('RevenueCat logged in with user: ${currentUser.id}');
    }

    _isInitialized = true;
    _initCompleter!.complete();
  } catch (e) {
    // ... error handling
  }
}
```

---

### Phase 3: Update UI to Handle Anonymous Users

#### 3.1 Update Menu Widget

**File:** `lib/src/widgets/menu/menu.dart`

The menu should show "Sign In" for anonymous users, not their email.

```dart
Widget build(BuildContext context, WidgetRef ref) {
  // Use effective auth for UI display
  final isEffectivelyAuthenticated = ref.watch(isEffectivelyAuthenticatedProvider);
  final user = ref.watch(currentUserProvider);

  // ...

  if (isEffectivelyAuthenticated && user != null) {
    // Show user email and sign out option
    _buildUserSection(user.email);
  } else {
    // Show "Sign In" option (even if we have anonymous session)
    _buildSignInOption();
  }
}
```

#### 3.2 Update Account Page

**File:** `lib/src/features/settings/views/account_page.dart`

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final isEffectivelyAuthenticated = ref.watch(isEffectivelyAuthenticatedProvider);
  final isAnonymous = ref.watch(isAnonymousUserProvider);
  final user = ref.watch(currentUserProvider);

  return AdaptiveSliverPage(
    title: 'Account',
    slivers: [
      SliverToBoxAdapter(
        child: Column(
          children: [
            if (isEffectivelyAuthenticated && user != null) ...[
              // Full user info with sign out
              _UserInfoRow(email: user.email ?? 'No email'),
              _SignOutRow(onSignOut: () => _handleSignOut(context, ref)),
            ] else ...[
              // Show sign in/sign up options
              // Include warning if anonymous user has a subscription
              if (isAnonymous) ...[
                _AnonymousUserNotice(),  // NEW: Explains they have Plus but no account
              ],
              SettingsRowCondensed(
                title: 'Sign In',
                onTap: () => context.push('/auth'),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
```

#### 3.3 Create Anonymous User Notice Widget

```dart
class _AnonymousUserNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      margin: EdgeInsets.all(AppSpacing.lg),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.exclamationmark_triangle,
                   color: colors.warning, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text('Account Not Linked',
                   style: AppTypography.bodyBold.copyWith(color: colors.warning)),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'You have Stockpot Plus but no account. Create an account to '
            'access your subscription on other devices and enable features '
            'like household sharing.',
            style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
```

---

### Phase 4: Handle Sign-In / Sign-Up for Anonymous Users

#### 4.1 Sign-Up Flow (Anonymous → Registered)

When an anonymous user signs up, we **upgrade** their account using Supabase's identity linking.

**File:** `lib/src/services/auth_service.dart`

```dart
/// Sign up - upgrades anonymous user if currently anonymous
Future<AuthResponse> signUpWithEmail({
  required String email,
  required String password,
  Map<String, dynamic>? metadata,
}) async {
  final currentUser = _supabase.auth.currentUser;
  final isAnonymous = currentUser?.identities?.isEmpty ?? false;

  if (isAnonymous && currentUser != null) {
    // UPGRADE: Link email identity to anonymous account
    // This preserves the user ID, so all subscriptions stay linked
    AppLogger.info('Upgrading anonymous user ${currentUser.id} to email account');

    final response = await _supabase.auth.updateUser(
      UserAttributes(
        email: email,
        password: password,
        data: metadata,
      ),
    );

    // User needs to verify email
    if (response.user != null) {
      AppLogger.info('Anonymous user upgraded to email account: ${response.user!.id}');
    }

    return AuthResponse(session: _supabase.auth.currentSession, user: response.user);
  }

  // Standard sign-up for non-anonymous users
  final response = await _supabase.auth.signUp(
    email: email,
    password: password,
    data: metadata,
  );

  return response;
}
```

**Important:** When upgrading an anonymous user:
- The user ID remains the same
- All `user_subscriptions` records stay linked
- RevenueCat purchases stay associated
- No data loss

#### 4.2 Sign-In Flow (Anonymous User Signing into Existing Account)

This is the tricky case. The user has:
- An anonymous Supabase account (possibly with a subscription)
- An existing registered account they want to sign into

We need to warn them about data implications.

**File:** `lib/src/features/auth/views/sign_in_page.dart`

```dart
Future<void> _handleEmailSignIn() async {
  final isAnonymous = ref.read(isAnonymousUserProvider);
  final hasPlus = ref.read(hasPlusProvider);

  // Check if anonymous user with subscription
  if (isAnonymous && hasPlus) {
    final shouldContinue = await _showAnonymousSubscriptionWarning(context);
    if (!shouldContinue) return;
  } else if (isAnonymous) {
    // Anonymous without subscription - still warn about local data
    final shouldContinue = await _showDataLossWarning(context);
    if (!shouldContinue) return;
  }

  // Proceed with sign-in
  try {
    await ref.read(authNotifierProvider.notifier).signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    // Success handling...
  } catch (e) {
    // Error handling...
  }
}

Future<bool> _showAnonymousSubscriptionWarning(BuildContext context) async {
  return await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text('Sign In Warning'),
      content: Text(
        'You currently have a Stockpot Plus subscription tied to this device. '
        'If you sign in to an existing account:\n\n'
        '• Your local recipes will be replaced with the account\'s data\n'
        '• You\'ll need to restore your purchase after signing in\n\n'
        'We recommend exporting your recipes first.',
      ),
      actions: [
        CupertinoDialogAction(
          child: Text('Cancel'),
          onPressed: () => Navigator.pop(context, false),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          child: Text('Sign In Anyway'),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  ) ?? false;
}

Future<bool> _showDataLossWarning(BuildContext context) async {
  return await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text('Replace Local Data?'),
      content: Text(
        'Signing in will replace your local recipes with the account\'s data. '
        'We recommend exporting your recipes first.',
      ),
      actions: [
        CupertinoDialogAction(
          child: Text('Cancel'),
          onPressed: () => Navigator.pop(context, false),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          child: Text('Sign In'),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  ) ?? false;
}
```

---

### Phase 5: Update Restore Purchases Flow

#### 5.1 Restore Flow for Anonymous Users

When an anonymous user restores purchases, RevenueCat will automatically transfer any purchases from previous anonymous IDs to the current user.

**File:** `lib/src/services/subscription_service.dart`

```dart
/// Restore purchases - creates anonymous user if needed
Future<void> restorePurchases() async {
  try {
    // Ensure we have a user (anonymous or real)
    String? userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      // Create anonymous user for restore
      AppLogger.info('Creating anonymous user for purchase restoration');
      userId = await _createAnonymousUserForPurchase();
    }

    await _ensureInitialized();

    // Ensure RevenueCat has correct user
    final currentRevenueCatUser = await Purchases.appUserID;
    if (currentRevenueCatUser != userId) {
      // This triggers RevenueCat's automatic purchase transfer
      await Purchases.logIn(userId);
    }

    // Restore purchases
    final customerInfo = await Purchases.restorePurchases();
    final hasActiveEntitlements = customerInfo.entitlements.active.isNotEmpty;

    if (hasActiveEntitlements) {
      AppLogger.info('Purchases restored successfully');
      await refreshRevenueCatState();
    } else {
      throw SubscriptionApiException(
        message: 'No active purchases found to restore',
        type: SubscriptionErrorType.missingReceipt,
      );
    }
  } catch (e) {
    // ... error handling
  }
}
```

#### 5.2 Post Sign-In Restore Prompt

After a user signs into an existing account (when they previously had an anonymous subscription), prompt them to restore.

**File:** `lib/src/providers/auth_provider.dart`

```dart
Future<void> signInWithEmail({
  required String email,
  required String password,
}) async {
  // Track if user was anonymous with subscription before sign-in
  final wasAnonymousWithSubscription =
      state.isAnonymous && await _checkHadSubscription();

  state = state.copyWith(isSigningIn: true);

  try {
    await _authService.signInWithEmail(email: email, password: password);

    // If user was anonymous with subscription, set flag for restore prompt
    if (wasAnonymousWithSubscription) {
      state = state.copyWith(
        shouldPromptRestore: true,  // NEW field
      );
    }
  } catch (e) {
    // ... error handling
  }
}
```

Then in the UI, check `shouldPromptRestore` and show a dialog prompting to restore purchases.

---

### Phase 6: Feature Gating for Anonymous Users

Certain features require a fully registered account.

#### 6.1 Define Feature Requirements

**File:** `lib/src/utils/feature_flags.dart`

```dart
/// Features that require full registration (not anonymous)
static const Set<String> _requiresRegistration = {
  'household_sharing',
  'household_create',
  'household_join',
  'household_manage',
  'account_settings',
  'export_data',  // Need account to export properly
};

/// Check if feature is available for current user
static bool isFeatureAvailable(String feature, WidgetRef ref) {
  final isEffectivelyAuth = ref.read(isEffectivelyAuthenticatedProvider);
  final hasPlus = ref.read(hasPlusProvider);

  // Check if feature requires registration
  if (_requiresRegistration.contains(feature) && !isEffectivelyAuth) {
    return false;
  }

  // Check if feature requires Plus subscription
  if (_requiresPlus.contains(feature) && !hasPlus) {
    return false;
  }

  return true;
}
```

#### 6.2 Create Registration Required Gate

```dart
class RegistrationRequiredGate extends ConsumerWidget {
  final Widget child;
  final String feature;

  const RegistrationRequiredGate({
    required this.child,
    required this.feature,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEffectivelyAuth = ref.watch(isEffectivelyAuthenticatedProvider);

    if (isEffectivelyAuth) {
      return child;
    }

    // Show prompt to create account
    return _RegistrationPrompt(feature: feature);
  }
}

class _RegistrationPrompt extends StatelessWidget {
  final String feature;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.person_badge_plus, size: 48),
          SizedBox(height: AppSpacing.lg),
          Text('Account Required', style: AppTypography.h4),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Create an account to access $feature',
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'Create Account',
            onPressed: () => context.push('/auth/signup'),
          ),
        ],
      ),
    );
  }
}
```

---

### Phase 7: Backend Updates

#### 7.1 Update Webhook Handler

The backend already handles anonymous users correctly (since Supabase anonymous users are real users in the auth system). However, we should add logging:

**File:** `recipe_app_server/src/controllers/webhookController.ts`

```typescript
async function upsertUserSubscription(subscriptionData: any) {
  try {
    const { data: user, error: getUserError } = await supabase.auth.admin.getUserById(subscriptionData.user_id);

    if (getUserError || !user) {
      console.warn(`User ${subscriptionData.user_id} not found in Supabase, skipping subscription update`);
      return;
    }

    // Log if this is an anonymous user
    const isAnonymous = !user.identities || user.identities.length === 0;
    if (isAnonymous) {
      console.log(`Processing subscription for anonymous user: ${subscriptionData.user_id}`);
    }

    // ... rest of upsert logic
  } catch (error) {
    // ... error handling
  }
}
```

#### 7.2 Consider: Anonymous User Cleanup

Anonymous users without subscriptions could accumulate. Consider a scheduled job:

```typescript
// Cleanup anonymous users older than 30 days with no subscription
async function cleanupStaleAnonymousUsers() {
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  // Get anonymous users without subscriptions
  const { data: users } = await supabase.auth.admin.listUsers();

  for (const user of users) {
    const isAnonymous = !user.identities || user.identities.length === 0;
    const isOld = new Date(user.created_at) < thirtyDaysAgo;

    if (isAnonymous && isOld) {
      // Check if they have a subscription
      const { data: subscription } = await supabase
        .from('user_subscriptions')
        .select('id')
        .eq('user_id', user.id)
        .single();

      if (!subscription) {
        // Safe to delete
        await supabase.auth.admin.deleteUser(user.id);
        console.log(`Deleted stale anonymous user: ${user.id}`);
      }
    }
  }
}
```

---

## Edge Cases & Considerations

### 1. Device-to-Device Transfer

**Scenario:** User purchases on Device A (anonymous), installs app on Device B.

**Solution:** On Device B, user must "Restore Purchases":
1. App creates anonymous user on Device B
2. `Purchases.logIn(newAnonId)` is called
3. `Purchases.restorePurchases()` finds App Store receipt
4. RevenueCat validates receipt and grants entitlements
5. Webhook fires with Device B's anonymous user ID
6. Backend creates subscription for Device B's user

**Issue:** User now has subscriptions on two anonymous accounts.

**Mitigation:** Encourage users to create real accounts. Show periodic prompts.

### 2. Anonymous User Signs Into Existing Account WITH Subscription

**Scenario:** User has anonymous subscription, signs into account that ALSO has a subscription.

**Solution:** The existing account's subscription takes precedence. The anonymous subscription is orphaned (but RevenueCat still has the receipt). User can contact support if needed.

### 3. Family Sharing

RevenueCat handles family sharing at the App Store level. The `is_family_share` field in webhooks indicates this. Anonymous users can still benefit from family sharing.

### 4. Multiple Anonymous Users on Same Device

**Scenario:** User A creates anonymous account, purchases. User B clears app data, creates new anonymous account.

**Solution:** User A's subscription is orphaned. User B would need to restore (but can't restore User A's purchase since it's tied to User A's Apple ID, not the anonymous ID).

This is actually correct behavior - App Store purchases are tied to Apple ID, not our user ID.

### 5. Rate Limiting

Supabase limits anonymous sign-ins to 30/hour per IP. For most users, this is fine. Heavy testing may hit this limit.

**Mitigation:**
- Enable Turnstile/CAPTCHA in Supabase dashboard for production
- Only create anonymous user when actually needed (at purchase time)

---

## Migration Plan

### For Existing Users

No migration needed. Existing authenticated users continue to work as-is.

### For App Store Reviewers

Ensure the flow works:
1. Fresh install → no account
2. Tap "Labs" → paywall shows
3. Complete purchase → Labs accessible
4. User appears "logged out" but has Plus

### Rollout Strategy

1. **Phase 1:** Enable anonymous auth in Supabase dashboard (non-breaking)
2. **Phase 2:** Deploy backend changes (logging only, non-breaking)
3. **Phase 3:** Deploy Flutter app update with anonymous IAP support
4. **Phase 4:** Monitor MAUs and anonymous user metrics
5. **Phase 5:** Implement anonymous user cleanup job if needed

---

## Testing Checklist

### Anonymous Purchase Flow
- [ ] Unauthenticated user can complete purchase
- [ ] Anonymous Supabase user is created at purchase time
- [ ] RevenueCat receives correct user ID
- [ ] Webhook processes successfully
- [ ] User sees Plus features after purchase
- [ ] User still appears "logged out" in UI

### Sign-Up Flow (Anonymous → Registered)
- [ ] Anonymous user can sign up with email
- [ ] User ID is preserved (check database)
- [ ] Subscription remains linked
- [ ] User now appears "logged in" in UI
- [ ] Household features become available

### Sign-In Flow (Anonymous → Existing Account)
- [ ] Warning dialog shows for anonymous user with subscription
- [ ] Warning dialog shows for anonymous user without subscription
- [ ] User can cancel sign-in
- [ ] After sign-in, local data is replaced
- [ ] Restore purchases prompt appears if applicable

### Restore Purchases
- [ ] Works for authenticated users
- [ ] Works for anonymous users
- [ ] Creates anonymous user if needed
- [ ] Transfers purchases from previous anonymous IDs

### Feature Gating
- [ ] Anonymous users cannot access household features
- [ ] Anonymous users see "Create Account" prompts
- [ ] Authenticated users can access all features

---

## Files to Modify

| File | Changes |
|------|---------|
| `lib/src/services/auth_service.dart` | Add `createAnonymousUser()`, `isAnonymousUser`, update `signUpWithEmail()` |
| `lib/src/providers/auth_provider.dart` | Add `isAnonymous` to state, add new providers |
| `lib/src/features/auth/models/auth_state.dart` | Add `isAnonymous` field |
| `lib/src/services/subscription_service.dart` | Update `presentPaywall()`, `restorePurchases()` |
| `lib/src/widgets/menu/menu.dart` | Use `isEffectivelyAuthenticatedProvider` |
| `lib/src/features/settings/views/account_page.dart` | Handle anonymous users, show notice |
| `lib/src/features/auth/views/sign_in_page.dart` | Add warnings for anonymous users |
| `lib/src/features/auth/views/sign_up_page.dart` | Handle anonymous → registered upgrade |
| `lib/src/utils/feature_flags.dart` | Add registration requirements |
| `recipe_app_server/src/controllers/webhookController.ts` | Add logging for anonymous users |

---

## Summary

This proposal enables unauthenticated users to purchase subscriptions by:

1. **Creating anonymous Supabase users at purchase time** - preserves MAUs by only creating accounts when needed
2. **Treating anonymous users as "logged out" in UI** - no visible change for users who don't want accounts
3. **Seamless account upgrade** - sign-up preserves user ID and subscription
4. **Safe sign-in flow** - warns users about data implications
5. **Feature gating** - household features still require registration

The key insight is separating "system authentication" (has any Supabase session) from "effective authentication" (has a real account), allowing anonymous users to have full subscription benefits while appearing logged out.