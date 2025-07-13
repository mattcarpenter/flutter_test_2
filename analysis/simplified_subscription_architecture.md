# Simplified Account-Based Subscription Architecture

## Overview
A clean, PowerSync-driven approach to account-based subscriptions that leverages existing sync infrastructure without complex client-side APIs.

## Simplified Architecture

### Core Principle
**"Webhook → Supabase → PowerSync → Client"**

1. **RevenueCat webhook** updates Supabase user metadata
2. **PowerSync** automatically syncs user metadata to client 
3. **Client** reads subscription status from local PowerSync data
4. **No client-side subscription APIs needed**

### Data Flow
```
[Purchase] → [RevenueCat] → [Webhook] → [Supabase User Metadata] → [PowerSync Sync] → [Local Client Data]
```

## Implementation Plan

### Server-Side Infrastructure

#### 1.1 Supabase User Metadata Schema

**Update auth.users metadata column to include subscription info:**

```json
-- Example user metadata structure:
{
  "subscription": {
    "status": "active",           // active, cancelled, expired, trial, none
    "entitlements": ["plus"],     // array of entitlement IDs
    "expires_at": "2024-02-15T10:30:00Z",
    "trial_ends_at": null,
    "product_id": "stockpot_plus_monthly",
    "store": "app_store",         // app_store, play_store, stripe
    "revenuecat_customer_id": "customer_123",
    "last_updated": "2024-01-15T10:30:00Z"
  }
}
```

#### 1.2 RevenueCat Webhook Handler

**File**: `/users/matt/repos/recipe_app_server/supabase/functions/revenuecat-webhook/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

serve(async (req) => {
  try {
    // Verify webhook signature
    const signature = req.headers.get('Authorization')
    if (!signature || !await verifyWebhookSignature(req, signature)) {
      return new Response('Unauthorized', { status: 401 })
    }

    const payload = await req.json()
    console.log('Processing RevenueCat webhook:', payload.event.type, payload.event.app_user_id)

    await processSubscriptionEvent(payload)

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('Webhook processing error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

async function processSubscriptionEvent(payload: any) {
  const { event } = payload
  const userId = event.app_user_id // This is the Supabase user ID
  
  // Build subscription metadata based on event
  const subscriptionData = buildSubscriptionMetadata(event)
  
  // Update user metadata in Supabase auth.users
  const { error } = await supabase.auth.admin.updateUserById(userId, {
    user_metadata: {
      subscription: subscriptionData
    }
  })

  if (error) {
    throw new Error(`Failed to update user metadata: ${error.message}`)
  }

  console.log(`Updated subscription metadata for user ${userId}`)
  
  // Log event for audit purposes (optional)
  await logSubscriptionEvent(event, subscriptionData)
}

function buildSubscriptionMetadata(event: any): any {
  const now = new Date().toISOString()
  
  switch (event.type) {
    case 'INITIAL_PURCHASE':
    case 'RENEWAL':
    case 'UNCANCELLATION':
      return {
        status: 'active',
        entitlements: event.entitlement_ids || [],
        expires_at: event.expiration_at_ms ? new Date(event.expiration_at_ms).toISOString() : null,
        trial_ends_at: event.period_type === 'TRIAL' && event.expiration_at_ms 
          ? new Date(event.expiration_at_ms).toISOString() 
          : null,
        product_id: event.product_id,
        store: mapStoreString(event.store),
        revenuecat_customer_id: event.aliases?.[0] || event.app_user_id,
        last_updated: now
      }
      
    case 'CANCELLATION':
      return {
        status: 'cancelled',
        entitlements: event.entitlement_ids || [],
        expires_at: event.expiration_at_ms ? new Date(event.expiration_at_ms).toISOString() : null,
        cancelled_at: now,
        product_id: event.product_id,
        store: mapStoreString(event.store),
        revenuecat_customer_id: event.aliases?.[0] || event.app_user_id,
        last_updated: now
      }
      
    case 'EXPIRATION':
      return {
        status: 'expired',
        entitlements: [],
        expires_at: event.expiration_at_ms ? new Date(event.expiration_at_ms).toISOString() : null,
        product_id: event.product_id,
        store: mapStoreString(event.store),
        revenuecat_customer_id: event.aliases?.[0] || event.app_user_id,
        last_updated: now
      }
      
    case 'BILLING_ISSUE':
      return {
        status: 'billing_retry',
        entitlements: event.entitlement_ids || [],
        expires_at: event.expiration_at_ms ? new Date(event.expiration_at_ms).toISOString() : null,
        product_id: event.product_id,
        store: mapStoreString(event.store),
        revenuecat_customer_id: event.aliases?.[0] || event.app_user_id,
        last_updated: now
      }
      
    default:
      console.log(`Unhandled event type: ${event.type}`)
      return null
  }
}

function mapStoreString(store: string): string {
  switch (store) {
    case 'APP_STORE':
    case 'MAC_APP_STORE':
      return 'app_store'
    case 'PLAY_STORE':
      return 'play_store'
    case 'STRIPE':
      return 'stripe'
    default:
      return store.toLowerCase()
  }
}

async function logSubscriptionEvent(event: any, subscriptionData: any) {
  // Optional: Log to a separate events table for audit purposes
  // This could be useful for analytics and debugging
  try {
    await supabase.from('subscription_events').insert({
      user_id: event.app_user_id,
      event_type: event.type.toLowerCase(),
      revenuecat_event_id: event.id,
      product_id: event.product_id,
      raw_event_data: event,
      processed_metadata: subscriptionData,
      processed_at: new Date().toISOString()
    })
  } catch (error) {
    console.error('Failed to log subscription event:', error)
    // Don't throw - logging failure shouldn't break webhook processing
  }
}

async function verifyWebhookSignature(req: Request, signature: string): Promise<boolean> {
  const expectedToken = Deno.env.get('REVENUECAT_WEBHOOK_SECRET')
  return signature === `Bearer ${expectedToken}`
}
```

#### 1.3 Optional: Subscription Events Table

**For audit/analytics purposes (not required for core functionality):**

```sql
-- Optional table for subscription event logging
create table if not exists subscription_events (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users(id),
    event_type text not null,
    revenuecat_event_id text,
    product_id text,
    raw_event_data jsonb,
    processed_metadata jsonb,
    processed_at timestamp with time zone default now()
);

create index if not exists idx_subscription_events_user_id on subscription_events(user_id);
create index if not exists idx_subscription_events_type on subscription_events(event_type);

-- RLS for subscription events
alter table subscription_events enable row level security;

create policy "Users can view own subscription events" on subscription_events
    for select using (auth.uid() = user_id);

create policy "Service role can manage subscription events" on subscription_events
    for all using (auth.jwt() ->> 'role' = 'service_role');
```

### Client-Side Implementation

#### 2.1 Subscription Service (Simplified)

**Update**: `lib/src/services/subscription_service.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  static const String _apiKey = 'appl_SPuDBCvjoalGuumyxdYEfRZKEXt';
  static const String _plusEntitlementId = 'plus';
  
  final SupabaseClient _supabase;
  bool _isInitialized = false;
  
  SubscriptionService() : _supabase = Supabase.instance.client;

  /// Initialize RevenueCat SDK
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('SubscriptionService: Initializing RevenueCat');
      
      final configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);
      
      _isInitialized = true;
      debugPrint('SubscriptionService: Initialization complete');
    } catch (e) {
      debugPrint('SubscriptionService: Initialization failed: $e');
      rethrow;
    }
  }

  /// Check if user has Plus subscription from local PowerSync data
  bool hasPlus() {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      // Read from user metadata (synced by PowerSync)
      final metadata = user.userMetadata;
      final subscription = metadata?['subscription'] as Map<String, dynamic>?;
      
      if (subscription == null) return false;
      
      // Check if subscription is active
      final status = subscription['status'] as String?;
      final entitlements = subscription['entitlements'] as List<dynamic>?;
      final expiresAt = subscription['expires_at'] as String?;
      
      // Check if subscription is in active state
      if (!['active', 'trial', 'cancelled'].contains(status)) {
        return false;
      }
      
      // Check if subscription has Plus entitlement
      if (entitlements?.contains(_plusEntitlementId) != true) {
        return false;
      }
      
      // Check if subscription is not expired (for cancelled subscriptions)
      if (status == 'cancelled' && expiresAt != null) {
        final expiry = DateTime.parse(expiresAt);
        if (expiry.isBefore(DateTime.now())) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('SubscriptionService: Error checking Plus access: $e');
      return false; // Fail closed
    }
  }

  /// Get subscription metadata from local data
  Map<String, dynamic>? getSubscriptionMetadata() {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      
      final metadata = user.userMetadata;
      return metadata?['subscription'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('SubscriptionService: Error getting subscription metadata: $e');
      return null;
    }
  }

  /// Present paywall using RevenueCat's built-in UI
  Future<bool> presentPaywall() async {
    try {
      await initialize();
      
      debugPrint('SubscriptionService: Presenting paywall');
      final result = await RevenueCatUI.presentPaywall();
      
      debugPrint('SubscriptionService: Paywall result: ${result.name}');
      return result == PaywallResult.purchased;
    } catch (e) {
      debugPrint('SubscriptionService: Error presenting paywall: $e');
      rethrow;
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    try {
      await initialize();
      
      debugPrint('SubscriptionService: Restoring purchases');
      await Purchases.restorePurchases();
      
      debugPrint('SubscriptionService: Purchases restored');
    } catch (e) {
      debugPrint('SubscriptionService: Error restoring purchases: $e');
      rethrow;
    }
  }

  /// Sync user ID with RevenueCat
  Future<void> syncUserId() async {
    try {
      await initialize();
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        debugPrint('SubscriptionService: No authenticated user, logging out from RevenueCat');
        await Purchases.logOut();
        return;
      }
      
      debugPrint('SubscriptionService: Syncing user ID: ${currentUser.id}');
      await Purchases.logIn(currentUser.id);
      debugPrint('SubscriptionService: User ID sync complete');
    } catch (e) {
      debugPrint('SubscriptionService: Error syncing user ID: $e');
      rethrow;
    }
  }

  /// Force refresh subscription status (triggers RevenueCat sync)
  Future<void> refreshSubscriptionStatus() async {
    try {
      await initialize();
      
      debugPrint('SubscriptionService: Refreshing subscription status');
      final customerInfo = await Purchases.getCustomerInfo();
      
      debugPrint('SubscriptionService: Customer info refreshed, entitlements: ${customerInfo.entitlements.active.keys}');
      
      // The webhook will update Supabase metadata when RevenueCat processes this
      // PowerSync will then sync the updated user metadata to the client
      
    } catch (e) {
      debugPrint('SubscriptionService: Error refreshing subscription: $e');
      rethrow;
    }
  }
}
```

#### 2.2 Subscription Provider (Simplified)

**Update**: `lib/src/providers/subscription_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/subscription_state.dart';
import '../services/subscription_service.dart';
import 'auth_provider.dart';

/// Service provider
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

/// Main subscription state provider
final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return SubscriptionNotifier(
    subscriptionService: subscriptionService,
    ref: ref,
  );
});

/// Convenience providers
final hasPlusProvider = Provider<bool>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  return subscription.hasPlus;
});

final subscriptionMetadataProvider = Provider<Map<String, dynamic>?>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return service.getSubscriptionMetadata();
});

final subscriptionStatusProvider = Provider<String>((ref) {
  final metadata = ref.watch(subscriptionMetadataProvider);
  return metadata?['status'] as String? ?? 'none';
});

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SubscriptionService _subscriptionService;
  final Ref _ref;
  
  SubscriptionNotifier({
    required SubscriptionService subscriptionService,
    required Ref ref,
  })  : _subscriptionService = subscriptionService,
        _ref = ref,
        super(const SubscriptionState()) {
    _initializeSubscriptionState();
  }

  void _initializeSubscriptionState() {
    // Listen to auth state changes
    _ref.listen(authNotifierProvider, (previous, next) {
      debugPrint('SubscriptionNotifier: Auth state changed');
      _updateSubscriptionState();
    });

    // Check initial subscription state
    _updateSubscriptionState();
  }

  void _updateSubscriptionState() {
    try {
      final hasPlus = _subscriptionService.hasPlus();
      final metadata = _subscriptionService.getSubscriptionMetadata();
      
      state = state.copyWith(
        hasPlus: hasPlus,
        subscriptionMetadata: metadata,
        error: null,
      );
      
      debugPrint('SubscriptionNotifier: Updated state - hasPlus: $hasPlus');
    } catch (e) {
      debugPrint('SubscriptionNotifier: Error updating state: $e');
      state = state.copyWith(
        error: e.toString(),
      );
    }
  }

  /// Initialize RevenueCat and sync user ID
  Future<void> initialize() async {
    try {
      state = state.copyWith(isLoading: true);
      
      await _subscriptionService.initialize();
      await _subscriptionService.syncUserId();
      
      _updateSubscriptionState();
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('SubscriptionNotifier: Initialization failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Present paywall
  Future<bool> presentPaywall() async {
    try {
      state = state.copyWith(isShowingPaywall: true);
      
      final purchased = await _subscriptionService.presentPaywall();
      
      if (purchased) {
        // Wait a moment for webhook to process, then update state
        await Future.delayed(const Duration(seconds: 2));
        _updateSubscriptionState();
      }
      
      return purchased;
    } catch (e) {
      debugPrint('SubscriptionNotifier: Paywall error: $e');
      state = state.copyWith(error: e.toString());
      return false;
    } finally {
      state = state.copyWith(isShowingPaywall: false);
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    try {
      state = state.copyWith(isRestoring: true);
      
      await _subscriptionService.restorePurchases();
      
      // Wait for webhook to process, then update state
      await Future.delayed(const Duration(seconds: 2));
      _updateSubscriptionState();
      
    } catch (e) {
      debugPrint('SubscriptionNotifier: Restore error: $e');
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isRestoring: false);
    }
  }

  /// Manual refresh
  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true);
      
      await _subscriptionService.refreshSubscriptionStatus();
      
      // Wait for webhook and PowerSync to process
      await Future.delayed(const Duration(seconds: 3));
      _updateSubscriptionState();
      
    } catch (e) {
      debugPrint('SubscriptionNotifier: Refresh error: $e');
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
```

#### 2.3 Updated Subscription State Model

**Update**: `lib/src/models/subscription_state.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_state.freezed.dart';

@freezed
class SubscriptionState with _$SubscriptionState {
  const factory SubscriptionState({
    @Default(false) bool hasPlus,
    @Default(false) bool isLoading,
    @Default(false) bool isShowingPaywall,
    @Default(false) bool isRestoring,
    String? error,
    Map<String, dynamic>? subscriptionMetadata,
  }) = _SubscriptionState;
}

extension SubscriptionStateExtensions on SubscriptionState {
  bool get isBusy => isLoading || isShowingPaywall || isRestoring;
  
  String get status => subscriptionMetadata?['status'] as String? ?? 'none';
  
  List<String> get entitlements => 
      List<String>.from(subscriptionMetadata?['entitlements'] ?? []);
  
  DateTime? get expiresAt {
    final expiresAtString = subscriptionMetadata?['expires_at'] as String?;
    return expiresAtString != null ? DateTime.parse(expiresAtString) : null;
  }
  
  bool get isTrialActive {
    if (status != 'trial') return false;
    final trialEndsAt = subscriptionMetadata?['trial_ends_at'] as String?;
    if (trialEndsAt == null) return true;
    return DateTime.parse(trialEndsAt).isAfter(DateTime.now());
  }
  
  bool get isCancelledButActive {
    if (status != 'cancelled') return false;
    final expiresAt = this.expiresAt;
    return expiresAt?.isAfter(DateTime.now()) ?? false;
  }
}
```

### PowerSync Integration (Automatic)

**PowerSync automatically syncs user metadata changes, so no additional PowerSync configuration is needed!**

The user's subscription status will be available immediately in the client through:
- `Supabase.instance.client.auth.currentUser?.userMetadata`
- This data is automatically kept in sync by PowerSync

### Household Integration (Future Enhancement)

Household subscription sharing can be implemented using existing household system with subscription triggers, following the same PowerSync-driven pattern.

## Benefits of This Approach

1. **Simple**: Leverages existing PowerSync infrastructure
2. **Real-time**: Subscription changes sync automatically 
3. **Offline**: Works offline using local PowerSync data
4. **No APIs**: No client-side subscription API calls needed
5. **Cross-platform**: Works identically on all platforms
6. **Audit trail**: Optional event logging for analytics

## Testing Strategy

1. **Webhook testing**: Use RevenueCat sandbox to test webhook events
2. **Metadata verification**: Check user metadata updates in Supabase
3. **PowerSync sync**: Verify metadata syncs to client automatically
4. **Offline testing**: Ensure subscription checks work offline

This approach is much cleaner and leverages your existing PowerSync infrastructure perfectly!