# Subscription & Feature Gating Guide

**Purpose:** Reference guide for implementing subscription checks, feature gating, and paywall presentation in the Stockpot app.

---

## Quick Reference

### Check if User Has Plus Subscription

```dart
// In a widget - reactive (rebuilds when subscription changes)
final hasPlus = ref.watch(effectiveHasPlusProvider);

// In a callback/handler - one-time read
final hasPlus = ref.read(effectiveHasPlusProvider);
```

### Show Paywall

```dart
// Present paywall and get result
final purchased = await ref.read(subscriptionProvider.notifier).presentPaywall(context);
if (purchased) {
  // User subscribed - proceed with premium action
}
```

### Gate a Feature with FeatureGate Widget

```dart
FeatureGate(
  feature: 'labs',
  child: PremiumContent(),
  fallback: LockedContentPlaceholder(), // Optional
)
```

---

## Architecture Overview

```
Purchase Flow:
[User taps upgrade] → [PaywallPage] → [App Store] → [RevenueCat] → [Webhook] → [Supabase DB] → [PowerSync] → [Client]

Entitlement Check Flow:
[effectiveHasPlusProvider] → [hasPlusProvider (DB)] OR [optimisticHasPlus (immediate)]
```

### Key Files

| File | Purpose |
|------|---------|
| `lib/src/providers/subscription_provider.dart` | State management, all subscription providers |
| `lib/src/services/subscription_service.dart` | RevenueCat SDK integration, paywall presentation |
| `lib/src/utils/feature_flags.dart` | Feature gating logic, `FeatureGate` widget |
| `lib/src/features/subscription/views/paywall_page.dart` | Custom paywall page wrapper |
| `lib/src/models/subscription_state.dart` | Subscription state model (Freezed) |

---

## Providers Reference

### Primary Providers

| Provider | Type | Use Case |
|----------|------|----------|
| `effectiveHasPlusProvider` | `Provider<bool>` | **Use this for UI gating** - includes optimistic access |
| `hasPlusProvider` | `Provider<bool>` | Database-only check (reactive stream) |
| `subscriptionProvider` | `StateNotifierProvider` | Full subscription state + notifier for actions |

### Convenience Providers

| Provider | Type | Returns |
|----------|------|---------|
| `subscriptionLoadingProvider` | `Provider<bool>` | `true` if loading |
| `subscriptionBusyProvider` | `Provider<bool>` | `true` if any operation in progress |
| `subscriptionErrorProvider` | `Provider<String?>` | Error message or null |
| `subscriptionMetadataProvider` | `Provider<Map?>` | Full subscription metadata |
| `entitlementProvider.family` | `Provider.family<bool, String>` | Check specific entitlement by ID |

---

## Common Patterns

### Pattern 1: Gate Access to a Page/Screen

**Option A: Check in route guard (recommended for full pages)**

```dart
// In your router configuration or navigation handler
onTap: () async {
  final hasPlus = ref.read(effectiveHasPlusProvider);

  if (hasPlus) {
    context.push('/premium-page');
  } else {
    final purchased = await ref.read(subscriptionProvider.notifier).presentPaywall(context);
    if (purchased) {
      context.push('/premium-page');
    }
    // If not purchased, user stays where they are
  }
}
```

**Option B: Use FeatureGate widget (for inline content)**

```dart
// The entire page content is gated
class PremiumPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureGate(
      feature: 'premium_feature_name',
      child: ActualPremiumContent(),
      // Optional: custom fallback instead of default upgrade prompt
      fallback: CustomLockedView(),
    );
  }
}
```

### Pattern 2: Gate a Specific Action (Button Tap)

```dart
ElevatedButton(
  onPressed: () async {
    final hasPlus = ref.read(effectiveHasPlusProvider);

    if (hasPlus) {
      // Do the premium action
      _performPremiumAction();
    } else {
      // Show paywall first
      final purchased = await ref.read(subscriptionProvider.notifier).presentPaywall(context);
      if (purchased) {
        _performPremiumAction();
      }
    }
  },
  child: Text('Premium Action'),
)
```

### Pattern 3: Show Premium Badge/Lock Icon

```dart
// Shows "PLUS" badge if subscribed, lock icon if premium feature, nothing if free
PremiumBadge(feature: 'labs')

// Or just show badge when user has Plus
PremiumBadge() // No feature = just shows Plus badge if subscribed
```

### Pattern 4: Conditional UI Based on Subscription

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final hasPlus = ref.watch(effectiveHasPlusProvider);

  return Column(
    children: [
      // Always visible
      BasicFeatureWidget(),

      // Only visible for Plus users
      if (hasPlus) ...[
        PremiumFeature1(),
        PremiumFeature2(),
      ],

      // Show upgrade prompt for free users
      if (!hasPlus)
        UpgradePromptBanner(
          onTap: () => ref.read(subscriptionProvider.notifier).presentPaywall(context),
        ),
    ],
  );
}
```

### Pattern 5: Features Requiring Registration (Not Just Subscription)

Some features require a real account (not anonymous), regardless of subscription:

```dart
// Check both registration and subscription
final isAuthenticated = ref.watch(isAuthenticatedProvider);
final hasPlus = ref.watch(effectiveHasPlusProvider);

if (!isAuthenticated) {
  // Redirect to auth
  context.push('/auth');
} else if (!hasPlus) {
  // Show paywall
  ref.read(subscriptionProvider.notifier).presentPaywall(context);
} else {
  // Full access
  context.push('/household');
}
```

Or use `FeatureFlags.checkFeatureAccess()`:

```dart
final access = FeatureFlags.checkFeatureAccess(
  feature: 'household',
  hasPlus: hasPlus,
  isEffectivelyAuthenticated: isAuthenticated,
);

if (!access.hasAccess) {
  if (access.blockedReason == 'registration_required') {
    // Show auth flow
  } else if (access.blockedReason == 'subscription_required') {
    // Show paywall
  }
}
```

---

## Adding a New Premium Feature

### Step 1: Register the Feature

Add to `lib/src/utils/feature_flags.dart`:

```dart
// In hasFeatureSync() switch statement
case 'my_new_feature':
  return subscription.hasPlus;

// In getRequiredTier()
case 'my_new_feature':
  return 'plus';

// In getFeatureDescription()
case 'my_new_feature':
  return 'Description shown in upgrade prompt';

// In premiumFeatures list
static List<String> get premiumFeatures => [
  // ... existing features
  'my_new_feature',
];
```

### Step 2: Gate the Feature

Use any of the patterns above with your feature name:

```dart
FeatureGate(
  feature: 'my_new_feature',
  child: MyNewFeatureWidget(),
)
```

---

## Optimistic Access

After a purchase or restore, users get **immediate access** before the database syncs:

1. `presentPaywall()` returns `true` on successful purchase
2. `optimisticHasPlus` flag is set to `true` in `SubscriptionState`
3. `effectiveHasPlusProvider` returns `true` (database OR optimistic)
4. User sees premium content immediately
5. When webhook processes and PowerSync syncs, `hasPlusProvider` becomes `true`
6. `optimisticHasPlus` is auto-cleared (no longer needed)

**Always use `effectiveHasPlusProvider`** for UI gating to ensure immediate access after purchase.

---

## Paywall Presentation

The paywall is presented via a custom `PaywallPage` that wraps RevenueCat's `PaywallView`:

```dart
// This is what happens internally when you call presentPaywall()
final result = await Navigator.of(context).push<bool>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (context) => const PaywallPage(),
  ),
);
```

### Paywall Callbacks

The `PaywallPage` handles these RevenueCat callbacks:
- `onPurchaseCompleted` - Sets success flag
- `onRestoreCompleted` - Sets success flag, auto-dismisses on success
- `onDismiss` - Returns result to caller
- `onPurchaseError` / `onRestoreError` - Logs error, lets user retry

### Presenting Paywall Only If Needed

```dart
// Returns true if user already has Plus OR successfully purchases
final hasAccess = await ref.read(subscriptionProvider.notifier).presentPaywallIfNeeded(context);
```

---

## Subscription State Model

```dart
SubscriptionState({
  bool hasPlus,              // From database
  bool optimisticHasPlus,    // Temporary flag after purchase
  bool isLoading,
  bool isRestoring,
  bool isShowingPaywall,
  String? error,
  Map<String, dynamic>? subscriptionMetadata,
})
```

### Useful Getters

```dart
final state = ref.watch(subscriptionProvider);

state.isActive        // hasPlus
state.hasError        // error != null
state.isBusy          // isLoading || isRestoring || isShowingPaywall
state.subscriptionStatus  // 'active', 'cancelled', etc.
state.expiresAt       // DateTime?
state.isTrialActive   // bool
```

---

## Entitlements

Currently we have one entitlement:

| Entitlement ID | Name | Features |
|----------------|------|----------|
| `plus` | Stockpot Plus | Labs, advanced features, priority support |

Entitlements are stored in the `user_subscriptions.entitlements` column as a JSON array: `["plus"]`

### Checking Specific Entitlements

```dart
// Check if user has a specific entitlement
final hasLabs = ref.watch(entitlementProvider('plus'));
```

---

## Error Handling

```dart
try {
  final purchased = await ref.read(subscriptionProvider.notifier).presentPaywall(context);
  // Handle result
} catch (e) {
  // Paywall presentation failed
  // Error is also stored in subscriptionErrorProvider
}

// Check for errors
final error = ref.watch(subscriptionErrorProvider);
if (error != null) {
  // Show error UI
}
```

---

## Testing Subscriptions

### Sandbox Testing
1. Use a sandbox Apple ID / Google test account
2. Purchases complete quickly but may not trigger webhooks in sandbox
3. Use `restorePurchases()` to sync state after sandbox purchases

### Manual State Verification
```dart
// Debug provider shows what's in the database
final debug = ref.watch(subscriptionDebugProvider);
print(debug); // "DEBUG: Found 1 subscriptions - Status=active, Entitlements=[plus]..."
```

---

## Data Flow Details

### Purchase → Access Timeline

```
T+0s    User completes purchase in PaywallPage
T+0.1s  onPurchaseCompleted callback fires
T+0.2s  PaywallPage returns true
T+0.3s  optimisticHasPlus set to true → UI shows access immediately
T+0.5s  RevenueCat webhook sent to backend
T+1-3s  Backend upserts to user_subscriptions table
T+3-10s PowerSync syncs to device
T+10s   hasPlusProvider emits true from database
T+10s   optimisticHasPlus auto-cleared (database is now source of truth)
```

### Why Two Sources of Truth?

- **Database (PowerSync)**: Authoritative, works offline, syncs across devices
- **Optimistic flag**: Immediate UX after purchase while waiting for webhook → PowerSync

The `effectiveHasPlusProvider` combines both, ensuring users never see a "locked" state after purchasing.

---

## Related Documentation

- `analysis/iap_entitlements_architecture.md` - Detailed architecture deep-dive
- `analysis/anonymous_iap_proposal.md` - Anonymous purchase flow design
- `analysis/restore_purchases_transfer_proposal.md` - Restore/transfer handling