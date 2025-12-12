# In-App Purchase & Entitlements Architecture

**Date:** December 12, 2025
**Purpose:** Document how IAP and entitlements work in the Stockpot app to inform decisions about anonymous purchase flows.

---

## Executive Summary

The current IAP implementation **requires users to be authenticated before purchasing**. Purchases made by unauthenticated users would be orphaned with no way to claim them. This is by design - the entire subscription system is built around the Supabase user ID being the link between RevenueCat purchases and backend entitlements.

### Key Findings

| Aspect | Current State |
|--------|---------------|
| **Can unauthenticated users purchase?** | Yes - paywall shows, but entitlements are orphaned |
| **RevenueCat user ID** | Set to Supabase UUID via `Purchases.logIn()` |
| **Entitlement source of truth** | RevenueCat webhook → Supabase → PowerSync |
| **Anonymous auth support** | None currently implemented |
| **Purchase-to-account linking** | No mechanism exists for orphaned purchases |

---

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              PURCHASE FLOW                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                  │
│  │   User Taps  │───▶│   Paywall    │───▶│  App Store/  │                  │
│  │   "Upgrade"  │    │  (RevenueCat)│    │  Play Store  │                  │
│  └──────────────┘    └──────────────┘    └──────────────┘                  │
│                                                 │                          │
│        (No auth check blocks paywall)          │ purchase                 │
│                                                 ▼                          │
│                                                 │                          │
│                                                 ▼                          │
│                                          ┌──────────────┐                  │
│                                          │  RevenueCat  │                  │
│                                          │   Backend    │                  │
│                                          └──────────────┘                  │
│                                                 │                          │
│                                                 │ webhook                  │
│                                                 ▼                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                           BACKEND PROCESSING                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                  │
│  │   Webhook    │───▶│   Validate   │───▶│   Upsert     │                  │
│  │   Handler    │    │   app_user_id│    │ Subscription │                  │
│  └──────────────┘    └──────────────┘    └──────────────┘                  │
│                                                 │                          │
│                      app_user_id = Supabase UUID                           │
│                                                 │                          │
│                                                 ▼                          │
│                                          ┌──────────────┐                  │
│                                          │   Supabase   │                  │
│                                          │ user_subscri-│                  │
│                                          │   ptions     │                  │
│                                          └──────────────┘                  │
│                                                 │                          │
│                                                 │ PowerSync                │
│                                                 ▼                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                            CLIENT SYNC                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                  │
│  │  PowerSync   │───▶│  Local SQLite│───▶│   Provider   │                  │
│  │    Sync      │    │   Database   │    │   Updates    │                  │
│  └──────────────┘    └──────────────┘    └──────────────┘                  │
│                                                 │                          │
│                                                 ▼                          │
│                                          ┌──────────────┐                  │
│                                          │  UI Updates  │                  │
│                                          │ (FeatureGate)│                  │
│                                          └──────────────┘                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Part 1: RevenueCat User Identity

### How User IDs Are Set

When the app initializes RevenueCat, it links the RevenueCat user to the Supabase account:

```dart
// subscription_service.dart:117-147
Future<void> initialize() async {
  final configuration = PurchasesConfiguration(_apiKey);
  await Purchases.configure(configuration);

  // CRITICAL: Only sets user ID if authenticated
  final currentUser = _supabase.auth.currentUser;
  if (currentUser != null) {
    await Purchases.logIn(currentUser.id);  // Supabase UUID → RevenueCat
  }
  // If currentUser is null, RevenueCat uses device-generated anonymous ID
}
```

### User ID Lifecycle

| Event | Action | Result |
|-------|--------|--------|
| App launch (authenticated) | `Purchases.logIn(supabaseUUID)` | RevenueCat uses Supabase UUID |
| App launch (unauthenticated) | No `logIn()` call | RevenueCat generates anonymous ID |
| User signs in | `syncUserId()` → `Purchases.logIn()` | Anonymous ID merged to authenticated |
| User signs out | `Purchases.logOut()` | Disconnects RevenueCat session |

### The Identity Chain

```
Supabase Auth → auth.currentUser.id (UUID)
       ↓
RevenueCat SDK → Purchases.logIn(supabaseUUID)
       ↓
RevenueCat Backend → app_user_id stored with purchase
       ↓
Webhook → event.app_user_id sent to our backend
       ↓
Supabase DB → user_subscriptions.user_id = app_user_id
       ↓
PowerSync → Syncs to user where user_id matches
```

**This chain is why authentication is required** - without a Supabase UUID, there's no way to:
1. Tell RevenueCat who is purchasing
2. Process webhooks to the correct user
3. Sync entitlements to the correct device

---

## Part 2: Entitlements System

### What Is an Entitlement?

An entitlement is a string identifier that grants access to features. Currently we have one:

| Entitlement ID | Name | Features Unlocked |
|----------------|------|-------------------|
| `plus` | Stockpot Plus | Labs, advanced features, priority support |

### How Entitlements Are Granted

1. **User purchases subscription** in App Store/Play Store
2. **RevenueCat validates** the purchase receipt
3. **RevenueCat sends webhook** to our backend with `entitlement_ids: ["plus"]`
4. **Backend upserts** to `user_subscriptions` table:
   ```sql
   INSERT INTO user_subscriptions (user_id, status, entitlements, ...)
   VALUES ('supabase-uuid', 'active', '["plus"]', ...)
   ON CONFLICT (user_id) DO UPDATE SET ...
   ```
5. **PowerSync syncs** the row to the user's device
6. **Client reads** local database and grants access

### How Entitlements Are Revoked

| Event | Backend Action | Entitlements |
|-------|----------------|--------------|
| `CANCELLATION` | Status → `cancelled` | Kept until expiry |
| `EXPIRATION` | Status → `expired` | Cleared to `[]` |
| `BILLING_ISSUE` | Status stays `active` | Kept (grace period) |

### Entitlement Storage

**Supabase Table: `user_subscriptions`**
```sql
CREATE TABLE user_subscriptions (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL UNIQUE,      -- One subscription per user
    household_id uuid NULL,            -- For shared subscriptions
    status text NOT NULL,              -- none, active, cancelled, expired
    entitlements jsonb NOT NULL,       -- ["plus"] or []
    expires_at bigint NULL,            -- Unix ms timestamp
    trial_ends_at bigint NULL,
    cancelled_at bigint NULL,
    product_id text NULL,              -- e.g., "stockpot_plus_monthly"
    store text NULL,                   -- app_store, play_store, stripe
    revenuecat_customer_id text NULL,
    created_at bigint NULL,
    updated_at bigint NULL
);
```

---

## Part 3: Client-Side Entitlement Checking

### The Three-Tier Verification System

```
┌─────────────────────────────────────────────────────────────────┐
│                    ENTITLEMENT CHECK FLOW                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Tier 1: Local Database (Primary)                               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  hasPlusProvider watches PowerSync user_subscriptions    │   │
│  │  → Returns true if entitlements.contains('plus')         │   │
│  │  → Status must be 'active'                               │   │
│  │  → Works offline                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                           │                                     │
│                           │ if no data                          │
│                           ▼                                     │
│  Tier 2: RevenueCat Cache (Fallback)                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  hasPlusHybridProvider calls hasPlus()                   │   │
│  │  → Checks CustomerInfo.entitlements.active               │   │
│  │  → Requires network for fresh data                       │   │
│  │  → Used immediately after purchase                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                           │                                     │
│                           │ if SDK not initialized              │
│                           ▼                                     │
│  Tier 3: Fail Closed                                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  return false (deny access on any error)                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Key Providers

```dart
// Reactive check from PowerSync database
final hasPlusProvider = Provider<bool>((ref) {
  final subscriptions = ref.watch(allSubscriptionsStreamProvider);
  return subscriptions.when(
    data: (subs) => subs.any((s) =>
      s.entitlements.contains('plus') &&
      s.status == SubscriptionStatus.active
    ),
    loading: () => false,
    error: (_, __) => false,
  );
});

// Hybrid check with RevenueCat fallback
final hasPlusHybridProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  await service.refreshSubscriptionStatus();
  return await service.hasPlus(allowRevenueCatFallback: true);
});
```

### Feature Gating

```dart
// feature_flags.dart - Maps features to entitlements
static bool hasFeatureSync(String feature, SubscriptionState state) {
  switch (feature) {
    case 'labs':
    case 'advanced_analytics':
    case 'premium_recipes':
    case 'enhanced_pantry':
    case 'smart_recommendations':
      return state.hasPlus;  // Requires Plus subscription
    default:
      return true;  // Free features
  }
}

// FeatureGate widget protects premium content
FeatureGate(
  feature: 'labs',
  child: LabsContent(),  // Only shown if hasPlus == true
)
```

---

## Part 4: Current Auth Requirement

### Where Auth Is Enforced

**Layer 1: Menu UI**
```dart
// menu.dart:161-175
onTap: (_) async {
  if (hasPlus) {
    onRouteGo('/labs/auth');
  } else {
    // presentPaywall() is only called if user doesn't have Plus
    // But presentPaywall() itself checks auth internally
    final purchased = await ref.read(subscriptionProvider.notifier).presentPaywall();
    if (purchased) {
      onRouteGo('/labs/auth');
    }
  }
}
```

**Layer 2: Service Methods**
```dart
// subscription_service.dart:157-161
Future<bool> hasPlus({bool allowRevenueCatFallback = true}) async {
  final user = _supabase.auth.currentUser;
  if (user == null) return false;  // HARD STOP - unauthenticated = no Plus
  // ...
}
```

**Layer 3: RevenueCat Initialization**
```dart
// subscription_service.dart:134-137
final currentUser = _supabase.auth.currentUser;
if (currentUser != null) {
  await Purchases.logIn(currentUser.id);
}
// If null, RevenueCat has no user ID linked to Supabase
```

### What Happens Without Auth

If an unauthenticated user somehow reached the paywall:

1. **RevenueCat assigns anonymous ID** (device-generated)
2. **Purchase succeeds** in App Store/Play Store
3. **Webhook fires** with `app_user_id` = anonymous ID (not a Supabase UUID)
4. **Backend fails** to find user in Supabase (UUID doesn't exist)
5. **Subscription is orphaned** - no way to claim it later
6. **User sees no access** - PowerSync has nothing to sync

---

## Part 5: Household Subscription Sharing

### How It Works

When a user with Plus joins a household, their subscription is shared:

```
User A (has Plus) joins Household X
       ↓
RevenueCat webhook → user_subscriptions.household_id = X
       ↓
User B (in Household X) → PowerSync syncs User A's subscription
       ↓
User B now has Plus access (through household)
```

### PowerSync Sync Rules

```yaml
# User's own subscription
user_subscriptions_belongs_to_user:
  parameters: SELECT request.user_id() as user_id
  data:
    - SELECT * FROM user_subscriptions WHERE user_id = bucket.user_id

# Household subscriptions (shared access)
user_subscriptions_household_access:
  parameters: SELECT household_id FROM household_members
              WHERE user_id = request.user_id() AND is_active = 1
  data:
    - SELECT * FROM user_subscriptions WHERE household_id = bucket.household_id
```

### Metadata Tracking

```dart
// subscription_service.dart:251-252
'is_household_subscription': activeSubscription.userId != user.id,
'subscription_owner': activeSubscription.userId,
```

---

## Part 6: Purchase Flow Timing

### Full Purchase Timeline

```
T+0s    User taps "Upgrade" button
T+0.1s  presentPaywall() called
T+0.2s  RevenueCatUI.presentPaywall() shows native UI
T+5s    User completes purchase in App Store
T+5.1s  PaywallResult.purchased returned
T+5.2s  refreshRevenueCatState() updates local cache
T+5.3s  UI shows Plus access (from RevenueCat cache)

T+6s    RevenueCat backend processes purchase
T+7s    Webhook sent to our backend
T+7.1s  user_subscriptions upserted in Supabase
T+8-15s PowerSync syncs to device
T+15s   Local database updated
T+15.1s hasPlusProvider emits true (now from database)
```

### Immediate vs Synced Access

| Source | Latency | Offline? | Use Case |
|--------|---------|----------|----------|
| RevenueCat SDK cache | Immediate | No | Right after purchase |
| PowerSync database | 5-15 seconds | Yes | Normal usage, offline |

---

## Part 7: Implications for Anonymous Purchases

### Current Blockers

1. **No Supabase anonymous auth** - Users are either fully authenticated or have no session
2. **PowerSync requires session** - `fetchCredentials()` returns null without auth
3. **Webhook keyed to Supabase UUID** - Anonymous RevenueCat IDs aren't mapped
4. **No claim mechanism** - `_claimOrphanedRecords()` handles data, not subscriptions

### What Would Be Needed

To support purchases before explicit registration:

1. **Enable Supabase anonymous auth**
   - User gets temporary UUID on first launch
   - Can upgrade to full account later (email link, OAuth)

2. **Always set RevenueCat user ID**
   - `Purchases.logIn(anonymousUUID)` even for anonymous users
   - Ensures webhook has valid `app_user_id`

3. **Modify webhook handler**
   - Accept anonymous UUIDs
   - Create user_subscriptions for anonymous users

4. **Implement account upgrade flow**
   - When anonymous user registers, Supabase preserves UUID
   - Subscription automatically linked (same UUID)

5. **Handle edge cases**
   - What if user has purchases on multiple devices before registering?
   - What if user already has an account but made anonymous purchase?

### RevenueCat's Built-in Solution

RevenueCat handles anonymous-to-identified transitions:

```dart
// When user signs in after anonymous purchase
await Purchases.logIn(supabaseUUID);
// RevenueCat automatically transfers purchases from anonymous ID
// CustomerInfo will include the previous purchase
```

**But our backend won't know about it** unless:
- A new webhook fires (e.g., renewal)
- We call RevenueCat API to check entitlements
- We add a "sync purchases" button that calls `restorePurchases()`

---

## Summary

### Current State

- **Auth required**: Users must be authenticated to purchase
- **Identity chain**: Supabase UUID → RevenueCat → Webhook → Database → Client
- **Entitlement storage**: `user_subscriptions` table with `entitlements` JSON array
- **Verification**: Hybrid (database-first, RevenueCat fallback)
- **Household sharing**: Automatic via PowerSync sync rules

### Gaps for Anonymous Purchases

1. No Supabase anonymous auth configured
2. RevenueCat user ID not set for unauthenticated users
3. No mechanism to claim orphaned purchases
4. Backend webhook expects valid Supabase UUIDs

### Recommendation

If implementing anonymous purchases:
1. Use Supabase anonymous auth to get a UUID immediately
2. Always call `Purchases.logIn()` with that UUID
3. Leverage RevenueCat's automatic purchase transfer on account upgrade
4. Consider adding explicit "Restore Purchases" flow for edge cases

---

## Files Reference

| File | Purpose |
|------|---------|
| `lib/src/services/subscription_service.dart` | RevenueCat SDK integration, entitlement checking |
| `lib/src/providers/subscription_provider.dart` | State management, providers |
| `lib/src/utils/feature_flags.dart` | Feature gating, FeatureGate widget |
| `lib/database/models/user_subscriptions.dart` | Local database model |
| `recipe_app_server/src/controllers/webhookController.ts` | Webhook processing |
| `ddls/postgres_powersync.sql` | Database schema, RLS policies |
| `docker/config/sync_rules.yaml` | PowerSync sync rules |