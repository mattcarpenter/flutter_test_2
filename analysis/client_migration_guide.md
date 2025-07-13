# Client-Side Subscription Implementation Guide

## Overview
This guide details the client-side implementation for the PowerSync-driven account-based subscription system.

## Core Implementation

### Subscription Service (PowerSync-Driven)

**Update: `lib/src/services/subscription_service.dart`**

The subscription service uses the PowerSync-driven approach where subscription status is read directly from Supabase user metadata:

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

  /// Check if user has Plus subscription from PowerSync-synced user metadata
  bool hasPlus() {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      // Read from user metadata (synced by PowerSync)
      final metadata = user.userMetadata;
      final subscription = metadata?['subscription'] as Map<String, dynamic>?;
      
      if (subscription == null) return false;
      
      // Check subscription status and entitlements
      final status = subscription['status'] as String?;
      final entitlements = subscription['entitlements'] as List<dynamic>?;
      
      return ['active', 'trial', 'cancelled'].contains(status) && 
             entitlements?.contains(_plusEntitlementId) == true;
    } catch (e) {
      return false; // Fail closed
    }
  }

  /// Get subscription metadata from PowerSync-synced data
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

### Subscription Provider (PowerSync-Driven)

**Update: `lib/src/providers/subscription_provider.dart`**

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

### Updated Subscription State Model

**Update: `lib/src/models/subscription_state.dart`**

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

## Key Benefits

1. **Simple**: Leverages existing PowerSync infrastructure
2. **Real-time**: Subscription changes sync automatically via PowerSync 
3. **Offline**: Works offline using local PowerSync data
4. **No APIs**: No client-side subscription API calls needed
5. **Cross-platform**: Works identically on all platforms
6. **Clean architecture**: Single source of truth in Supabase user metadata

## Implementation Flow

1. **RevenueCat webhook** updates Supabase user metadata when subscription events occur
2. **PowerSync** automatically syncs user metadata changes to client
3. **Client** reads subscription status from local PowerSync-synced data
4. **Feature gates** check subscription status from local metadata

This approach is much cleaner and leverages your existing PowerSync infrastructure perfectly!