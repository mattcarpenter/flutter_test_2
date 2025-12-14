# Proposal: Fix Restore Purchases with Subscription Transfer (Option A)

**Date:** December 13, 2025
**Status:** Implemented
**Author:** Claude Code

---

## Executive Summary

When a user signs out and later tries to restore purchases, the subscription is not found because it's tied to the original user ID. This proposal implements **Apple's expected behavior**: when a user restores purchases, the subscription transfers to the new user and is revoked from the original owner.

### The Problem

**User Flow:**
1. Register as User A
2. Purchase subscription → tied to User A in RevenueCat
3. Sign out → become anonymous User B (or no user)
4. Tap "Restore Purchases" → logs: `Restored purchases successfully with no subscriptions`

**Root Cause:** RevenueCat's `restorePurchases()` associates restored receipts with the **currently logged-in RevenueCat user**. The default behavior should transfer subscriptions between users, but the backend doesn't handle the `TRANSFER` webhook event that RevenueCat sends when this happens.

---

## Current Architecture Analysis

### How Restore Currently Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        CURRENT RESTORE FLOW                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. User taps "Restore" in app                                              │
│         │                                                                   │
│         ▼                                                                   │
│  2. App creates anonymous user if needed (subscription_service.dart:357)    │
│         │                                                                   │
│         ▼                                                                   │
│  3. Purchases.logIn(newUserId) - logs into RevenueCat as new user           │
│         │                                                                   │
│         ▼                                                                   │
│  4. Purchases.restorePurchases() - queries App Store for receipts           │
│         │                                                                   │
│         ├─── App Store returns receipt(s) tied to Apple ID                  │
│         │                                                                   │
│         ▼                                                                   │
│  5. RevenueCat checks: Does this receipt belong to another user?            │
│         │                                                                   │
│         ├─── YES: Sends TRANSFER webhook (if transfer enabled)              │
│         │         └── Backend: NOT HANDLED ❌                               │
│         │                                                                   │
│         └─── NO: Returns CustomerInfo with entitlements                     │
│                  └── Works correctly ✓                                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Key Files Involved

| File | Current State |
|------|---------------|
| `subscription_service.dart:352-403` | `restorePurchases()` - creates anon user, calls RevenueCat |
| `webhookController.ts:24` | `TRANSFER` defined in interface but **no handler** |
| `webhookController.ts:119-144` | Switch statement missing `TRANSFER` case |
| `sync-rules.yaml:137-146` | Subscription sync rules (working correctly) |

---

## RevenueCat Transfer Behavior

### Dashboard Configuration

RevenueCat has a **Restore Behavior** setting in Project Settings → General:

| Option | Behavior |
|--------|----------|
| **Transfer to new App User ID** (Default) | Transfers subscription, revokes from original user |
| **Transfer if no active subscriptions** | Only transfers if original user's subscription expired |
| **Keep with original App User ID** | Returns error, user must sign into original account |
| **Share between App User IDs** (Legacy) | Both users have access (not recommended) |

**Current Setting:** Likely "Transfer to new App User ID" (default), but backend doesn't handle the `TRANSFER` event.

### What RevenueCat Sends on Transfer

When `restorePurchases()` triggers a transfer, RevenueCat sends a `TRANSFER` webhook with a **minimal payload**:

```json
{
  "api_version": "1.0",
  "event": {
    "type": "TRANSFER",
    "id": "CD489E0E-5D52-4E03-966B-A7F17788E432",
    "event_timestamp_ms": 1702500000000,
    "transferred_from": ["old_user_id"],    // User(s) losing the subscription
    "transferred_to": ["new_user_id"],      // User(s) receiving the subscription
    "store": "APP_STORE",
    "environment": "PRODUCTION"
    // NOTE: No app_user_id, product_id, entitlements, or expiration fields!
  }
}
```

**Critical:** TRANSFER events do NOT include `app_user_id`, `product_id`, `entitlement_ids`, or `expiration_at_ms`. We must:
1. Read the existing subscription from `transferred_from` user
2. Copy it to `transferred_to` user
3. Mark the original as expired

See: [RevenueCat Event Types and Fields](https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields)

---

## Proposed Solution

### Overview

1. **Backend**: Handle the `TRANSFER` webhook event
2. **Backend**: Update both old and new user subscription records
3. **Client**: Improve post-restore feedback and state refresh
4. **Dashboard**: Verify transfer behavior setting

### Implementation Plan

---

## Part 1: Backend - Handle TRANSFER Webhook Event

### 1.1 Add TRANSFER Handler Function

**File:** `/users/matt/repos/recipe_app_server/src/controllers/webhookController.ts`

Add after `handleProductChange()` function (around line 270):

```typescript
/**
 * Handle subscription transfer between users
 *
 * This occurs when:
 * 1. User A purchases subscription
 * 2. User A signs out
 * 3. User B restores purchases on same device
 * 4. RevenueCat transfers subscription from A to B
 *
 * IMPORTANT: TRANSFER events have a MINIMAL payload - they don't include
 * product_id, entitlement_ids, expiration_at_ms, etc.
 * We must COPY these details from the old user's subscription record.
 *
 * We need to:
 * 1. Read the old user's subscription details
 * 2. Copy those details to the new user
 * 3. Mark the old user's subscription as expired
 */
async function handleSubscriptionTransfer(event: any) {
  const oldUserIds = event.transferred_from || [];
  const newUserIds = event.transferred_to || [];

  // TRANSFER events don't have app_user_id - use transferred_to instead
  const newUserId = newUserIds[0];

  if (!newUserId) {
    console.error('TRANSFER event missing transferred_to field');
    return;
  }

  if (oldUserIds.length === 0) {
    console.error('TRANSFER event missing transferred_from field');
    return;
  }

  console.log(`Processing TRANSFER: from [${oldUserIds.join(', ')}] to [${newUserIds.join(', ')}]`);

  // Step 1: Get the subscription details from the first old user
  // (In practice, there's usually only one transferred_from user)
  let sourceSubscription: any = null;

  for (const oldUserId of oldUserIds) {
    const { data: subscription, error } = await supabase
      .from('user_subscriptions')
      .select('*')
      .eq('user_id', oldUserId)
      .single();

    if (!error && subscription && subscription.status === 'active') {
      sourceSubscription = subscription;
      console.log(`Found source subscription from user ${oldUserId}`);
      break;
    }
  }

  if (!sourceSubscription) {
    console.warn('No active source subscription found for transfer - may have already been processed');
    // Still try to deactivate old subscriptions
  }

  // Step 2: Deactivate subscription for old user(s)
  for (const oldUserId of oldUserIds) {
    if (oldUserId === newUserId) continue;

    try {
      const { error: updateError } = await supabase
        .from('user_subscriptions')
        .update({
          status: 'expired',
          entitlements: JSON.stringify([]),
          updated_at: Date.now()
        })
        .eq('user_id', oldUserId);

      if (updateError) {
        console.error(`Failed to deactivate subscription for old user ${oldUserId}:`, updateError);
      } else {
        console.log(`Deactivated subscription for old user ${oldUserId} (transferred to ${newUserId})`);
      }
    } catch (err) {
      console.error(`Error deactivating subscription for old user ${oldUserId}:`, err);
    }
  }

  // Step 3: Create/update subscription for new user
  if (!sourceSubscription) {
    console.warn('Cannot create subscription for new user - no source subscription found');
    return;
  }

  // Check if new user is in a household
  const { data: householdMember } = await supabase
    .from('household_members')
    .select('household_id')
    .eq('user_id', newUserId)
    .eq('is_active', 1)
    .single();

  // Copy subscription details from source, update user_id and household_id
  const subscriptionData = {
    user_id: newUserId,
    household_id: householdMember?.household_id || null,  // New user's household, not old user's
    status: 'active',
    entitlements: sourceSubscription.entitlements,  // Copy from source
    expires_at: sourceSubscription.expires_at,       // Copy from source
    trial_ends_at: sourceSubscription.trial_ends_at, // Copy from source
    product_id: sourceSubscription.product_id,       // Copy from source
    store: sourceSubscription.store,                 // Copy from source
    revenuecat_customer_id: newUserId,               // New user's ID
    updated_at: Date.now()
  };

  await upsertUserSubscription(subscriptionData);
  console.log(`Created transferred subscription for new user ${newUserId}, copied from source, household_id: ${subscriptionData.household_id}`);
}
```

### 1.2 Add TRANSFER Case to Switch Statement

**File:** `/users/matt/repos/recipe_app_server/src/controllers/webhookController.ts`

Update the switch statement in `processSubscriptionEvent()` (around line 119-144):

```typescript
async function processSubscriptionEvent(payload: RevenueCatWebhookEvent) {
  const { event } = payload;

  // Log the raw event first
  await logSubscriptionEvent(event);

  // Process based on event type
  switch (event.type) {
    case 'INITIAL_PURCHASE':
    case 'RENEWAL':
    case 'UNCANCELLATION':
      await handleSubscriptionActivation(event);
      break;

    case 'CANCELLATION':
      await handleSubscriptionCancellation(event);
      break;

    case 'EXPIRATION':
      await handleSubscriptionExpiration(event);
      break;

    case 'BILLING_ISSUE':
      await handleBillingIssue(event);
      break;

    case 'PRODUCT_CHANGE':
      await handleProductChange(event);
      break;

    // NEW: Handle subscription transfers
    case 'TRANSFER':
      await handleSubscriptionTransfer(event);
      break;

    default:
      console.log(`Unhandled event type: ${event.type}`);
  }
}
```

### 1.3 Update RevenueCatWebhookEvent Interface

**File:** `/users/matt/repos/recipe_app_server/src/controllers/webhookController.ts`

Add transfer-related fields to the interface (around line 4-32):

```typescript
interface RevenueCatWebhookEvent {
  api_version: string;
  event: {
    id: string;
    event_timestamp_ms: number;
    product_id: string;
    period_type: 'TRIAL' | 'INTRO' | 'NORMAL';
    purchased_at_ms: number;
    expiration_at_ms?: number;
    environment: 'SANDBOX' | 'PRODUCTION';
    entitlement_id: string;
    entitlement_ids: string[];
    presented_offering_identifier?: string;
    transaction_id: string;
    original_transaction_id: string;
    is_family_share: boolean;
    country_code: string;
    app_user_id: string;
    aliases: string[];
    original_app_user_id: string;
    type: 'INITIAL_PURCHASE' | 'RENEWAL' | 'PRODUCT_CHANGE' | 'CANCELLATION' | 'BILLING_ISSUE' | 'SUBSCRIBER_ALIAS' | 'SUBSCRIPTION_PAUSED' | 'TRANSFER' | 'EXPIRATION' | 'UNCANCELLATION';
    takehome_percentage: number;
    offer_code?: string;
    store: 'APP_STORE' | 'MAC_APP_STORE' | 'PLAY_STORE' | 'STRIPE' | 'PROMOTIONAL';
    price_in_purchased_currency?: number;
    subscriber_attributes?: Record<string, any>;
    currency?: string;
    // Transfer-specific fields
    transferred_from?: string[];  // Array of user IDs subscription was transferred from
    transferred_to?: string[];    // Array of user IDs subscription was transferred to
  };
}
```

---

## Part 2: Client - Improve Restore Flow

### 2.1 Update restorePurchases() for Better Feedback

**File:** `/Users/matt/repos/flutter_test_2/lib/src/services/subscription_service.dart`

The current implementation throws an error if no active entitlements are found immediately. However, with transfers, there's a delay between restore and webhook processing.

Replace `restorePurchases()` method (lines 352-403):

```dart
/// Restore purchases
/// Creates an anonymous Supabase user if needed (for restore without registration)
///
/// Note: If this triggers a subscription transfer (from another RevenueCat user),
/// there will be a delay while the TRANSFER webhook is processed by the backend.
Future<RestoreResult> restorePurchases() async {
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
      AppLogger.info('Syncing RevenueCat user to: $userId');
      await Purchases.logIn(userId);
    }

    // Restore purchases - this may trigger a TRANSFER webhook
    final customerInfo = await Purchases.restorePurchases();
    final hasActiveEntitlements = customerInfo.entitlements.active.isNotEmpty;

    if (hasActiveEntitlements) {
      // Immediate entitlements found
      AppLogger.info('Purchases restored successfully with immediate entitlements');
      await refreshRevenueCatState();
      return RestoreResult.success;
    }

    // No immediate entitlements - could be:
    // 1. No purchases to restore
    // 2. Transfer in progress (webhook not yet processed)
    // 3. Subscription expired

    // Check if we had any transactions restored (indicates transfer may be happening)
    final hasTransactions = customerInfo.nonSubscriptionTransactions.isNotEmpty ||
        customerInfo.allPurchasedProductIdentifiers.isNotEmpty;

    if (hasTransactions) {
      // Transactions exist but no entitlements - likely a transfer in progress
      AppLogger.info('Restore found transactions but no immediate entitlements - transfer may be in progress');
      return RestoreResult.transferPending;
    }

    // No transactions found at all
    AppLogger.info('Restored purchases but no subscriptions found');
    return RestoreResult.noSubscriptionsFound;

  } on PlatformException catch (e) {
    AppLogger.error('Error restoring purchases', e);

    final purchasesError = PurchasesError(
      PurchasesErrorCode.unknownError,
      e.message ?? 'Unknown error',
      '',
      e.details?.toString() ?? '',
    );

    throw SubscriptionApiException.fromPurchasesError(purchasesError);
  } catch (e) {
    if (e is SubscriptionApiException) rethrow;
    AppLogger.error('Error restoring purchases', e);
    throw SubscriptionApiException.fromException(Exception(e.toString()));
  }
}

/// Result of a restore purchases operation
enum RestoreResult {
  /// Subscription restored successfully with immediate access
  success,
  /// No subscriptions found to restore
  noSubscriptionsFound,
  /// Transactions found but transfer is pending (webhook processing)
  transferPending,
}
```

### 2.2 Update Subscription Provider to Handle Restore Results

**File:** `/Users/matt/repos/flutter_test_2/lib/src/providers/subscription_provider.dart`

Update the `restorePurchases()` method (around line 135):

```dart
/// Restore purchases
/// Returns the result of the restore operation
Future<RestoreResult> restorePurchases() async {
  try {
    state = state.copyWith(isRestoring: true, error: null);

    final result = await _subscriptionService.restorePurchases();

    switch (result) {
      case RestoreResult.success:
        // Immediate success - invalidate provider to refresh state
        _ref.invalidate(hasPlusHybridProvider);
        state = state.copyWith(
          isRestoring: false,
          hasPlus: true,
        );
        break;

      case RestoreResult.transferPending:
        // Transfer in progress - wait for webhook, then check again
        state = state.copyWith(isRestoring: false);
        // Start polling for subscription update
        _pollForSubscriptionUpdate();
        break;

      case RestoreResult.noSubscriptionsFound:
        state = state.copyWith(
          isRestoring: false,
          error: 'No purchases found to restore',
        );
        break;
    }

    return result;
  } catch (e) {
    final errorMessage = SubscriptionService.getErrorMessage(e as Exception);
    state = state.copyWith(
      isRestoring: false,
      error: errorMessage,
    );
    rethrow;
  }
}

/// Poll for subscription update after a transfer
/// Called when restore indicates a transfer may be pending
void _pollForSubscriptionUpdate() {
  int attempts = 0;
  const maxAttempts = 6;  // 30 seconds total
  const pollInterval = Duration(seconds: 5);

  Future<void> poll() async {
    attempts++;
    AppLogger.debug('Polling for subscription update (attempt $attempts/$maxAttempts)');

    // Refresh from database
    await _subscriptionService.refreshSubscriptionStatus();
    final hasPlus = _subscriptionService.hasPlusSync();

    if (hasPlus) {
      AppLogger.info('Subscription transfer completed');
      _ref.invalidate(hasPlusHybridProvider);
      state = state.copyWith(hasPlus: true);
      return;
    }

    if (attempts < maxAttempts) {
      await Future.delayed(pollInterval);
      await poll();
    } else {
      AppLogger.warning('Subscription transfer polling timed out');
      // Don't set error - the transfer might still complete
    }
  }

  poll();
}
```

### 2.3 Update RestorePromptListener for Better UX

**File:** `/Users/matt/repos/flutter_test_2/lib/src/widgets/restore_prompt_listener.dart`

Update the restore handling (around line 72-84):

```dart
// If user chose to restore, trigger the restore flow
if (shouldRestore == true && mounted) {
  try {
    final result = await ref.read(subscriptionProvider.notifier).restorePurchases();
    if (mounted) {
      switch (result) {
        case RestoreResult.success:
          _showRestoreSuccessDialog(context);
          break;
        case RestoreResult.transferPending:
          _showTransferPendingDialog(context);
          break;
        case RestoreResult.noSubscriptionsFound:
          _showNoSubscriptionsDialog(context);
          break;
      }
    }
  } catch (e) {
    if (mounted) {
      _showRestoreErrorDialog(context, e.toString());
    }
  }
}

void _showTransferPendingDialog(BuildContext context) {
  showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('Restoring Subscription'),
      content: const Text(
        'Your subscription is being transferred to this account. '
        'This may take a few moments. The app will update automatically.',
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

void _showNoSubscriptionsDialog(BuildContext context) {
  showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('No Subscriptions Found'),
      content: const Text(
        'We couldn\'t find any subscriptions to restore. '
        'Make sure you\'re using the same Apple ID that was used for the original purchase.',
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
```

---

## Part 3: RevenueCat Dashboard Configuration

### 3.1 Verify Transfer Behavior Setting

1. Go to RevenueCat Dashboard → Project Settings → General
2. Find "Restore Behavior" dropdown
3. Ensure it's set to **"Transfer to new App User ID"** (should be default)

### 3.2 Verify Webhook Configuration

1. Go to RevenueCat Dashboard → Integrations → Webhooks
2. Ensure webhook URL is correct
3. Verify `TRANSFER` event is enabled (should be by default)

---

## Part 4: Testing Plan

### 4.1 Test Cases

| # | Scenario | Expected Result |
|---|----------|-----------------|
| 1 | Register → Purchase → Sign Out → Restore | Subscription transfers to new anonymous user |
| 2 | Anonymous Purchase → Sign In to Existing → Restore | Subscription transfers to signed-in user |
| 3 | Restore with no previous purchases | "No subscriptions found" message |
| 4 | Original user checks after transfer | Sees subscription as expired/transferred |
| 5 | Household member when owner transfers | Household loses Plus access |

### 4.2 Test Flow for Primary Case

```
1. Create new account (User A)
2. Purchase subscription via paywall
3. Verify Plus access
4. Sign out
5. As anonymous user (or sign into different account User B)
6. Tap "Restore Purchases"
7. Expected:
   - RevenueCat sends TRANSFER webhook
   - Backend deactivates User A's subscription
   - Backend activates User B's subscription
   - Client polls and shows Plus access
```

### 4.3 Webhook Testing

Use RevenueCat's webhook testing in dashboard:
1. Go to Integrations → Webhooks
2. Click "Send Test Event"
3. Select "TRANSFER" event type
4. Verify backend logs show proper handling

---

## Part 5: Edge Cases & Considerations

### 5.1 Race Conditions

**Scenario:** User rapidly restores on multiple devices.

**Handling:** RevenueCat only allows one owner at a time. The last restore wins.

### 5.2 Household Impact

**Scenario:** User A has subscription shared with household. User B restores and takes subscription.

**Handling:**
- User A's subscription marked expired
- Household loses shared access (household_id was on User A's record)
- User B gets subscription (may be in different/no household)

**Consideration:** This is correct behavior - the subscription follows the Apple ID, not the household.

### 5.3 Data Loss Warning

**Scenario:** Anonymous user with local data restores subscription from another account.

**Current Handling:** Already implemented via warnings in sign-in flow. Same warnings apply to restore.

### 5.4 Sandbox Testing Quirks

Sandbox subscriptions have very short durations and receipts can be transient. For testing:
- Use a fresh sandbox Apple ID
- Purchase immediately before testing restore
- Note: Sandbox renewals happen every few minutes

---

## Implementation Checklist

### Backend (recipe_app_server)

- [ ] Add `handleSubscriptionTransfer()` function to webhookController.ts
- [ ] Add `TRANSFER` case to processSubscriptionEvent switch statement
- [ ] Add transfer fields to RevenueCatWebhookEvent interface
- [ ] Deploy updated backend
- [ ] Test with RevenueCat webhook tester

### Client (flutter_test_2)

- [ ] Create `RestoreResult` enum in subscription_service.dart
- [ ] Update `restorePurchases()` to return RestoreResult
- [ ] Add `_pollForSubscriptionUpdate()` to subscription_provider.dart
- [ ] Update RestorePromptListener with new dialogs
- [ ] Test restore flow end-to-end

### Dashboard

- [ ] Verify RevenueCat restore behavior is "Transfer to new App User ID"
- [ ] Verify TRANSFER webhook event is enabled

---

## Files Changed Summary

| File | Changes |
|------|---------|
| `recipe_app_server/src/controllers/webhookController.ts` | Add TRANSFER handler, update interface |
| `lib/src/services/subscription_service.dart` | Return RestoreResult instead of throwing |
| `lib/src/providers/subscription_provider.dart` | Handle RestoreResult, add polling |
| `lib/src/widgets/restore_prompt_listener.dart` | Add transfer pending dialog |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Webhook delivery failure | Low | High | RevenueCat retries; manual recovery via dashboard |
| Race condition with rapid restores | Low | Medium | RevenueCat handles; last restore wins |
| Household access disruption | Medium | Medium | Document expected behavior; is correct per Apple ID ownership |
| Transfer webhook not sent | Low | High | Verify dashboard settings; test before release |

---

## Conclusion

This proposal implements Apple's expected subscription transfer behavior by:

1. **Handling the TRANSFER webhook** on the backend to properly update both old and new user records
2. **Improving client UX** with appropriate feedback during the transfer process
3. **Polling for updates** when a transfer is detected but not yet processed

The key insight is that RevenueCat already supports transfers by default - we just need to handle the webhook event that it sends.
