import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database.dart';
import '../../database/powersync.dart';
import '../../database/models/user_subscriptions.dart';
import '../models/subscription_state.dart';
import '../services/subscription_service.dart';
import 'auth_provider.dart';

/// StateNotifier for managing subscription state and operations
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SubscriptionService _subscriptionService;
  final Ref _ref;
  
  late final StreamSubscription _authSubscription;

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
      // Refresh cache from database first
      _subscriptionService.refreshSubscriptionStatus().then((_) {
        final hasPlus = _subscriptionService.hasPlusSync();
        final metadata = _subscriptionService.getSubscriptionMetadata();
        
        // Build entitlements map from metadata
        final entitlements = <String, bool>{};
        if (metadata != null) {
          final entitlementsList = metadata['entitlements'] as List<dynamic>?;
          if (entitlementsList != null) {
            for (final entitlement in entitlementsList) {
              entitlements[entitlement.toString()] = true;
            }
          }
        }
        // Always include plus entitlement
        entitlements['plus'] = hasPlus;
        
        state = state.updateAccess(
          hasPlus: hasPlus,
          subscriptionMetadata: metadata,
          entitlements: entitlements,
        );
        
        debugPrint('SubscriptionNotifier: Updated state - hasPlus: $hasPlus, entitlements: $entitlements');
      }).catchError((e) {
        debugPrint('SubscriptionNotifier: Error refreshing subscription: $e');
        state = state.setError(e.toString());
      });
    } catch (e) {
      debugPrint('SubscriptionNotifier: Error updating state: $e');
      state = state.setError(e.toString());
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
        // Invalidate hybrid provider to refresh with new RevenueCat state
        _ref.invalidate(hasPlusHybridProvider);
        
        // Also update local state (database may take time to sync)
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

  /// Present paywall only if user doesn't have Plus subscription
  Future<bool> presentPaywallIfNeeded() async {
    // Check hybrid state to ensure we have the most current status
    final hasPlus = await _subscriptionService.hasPlus();
    
    if (hasPlus) {
      return true;
    }
    
    return await presentPaywall();
  }

  /// Get current subscription metadata
  Map<String, dynamic>? get subscriptionMetadata => state.subscriptionMetadata;

  /// Restore purchases
  Future<void> restorePurchases() async {
    try {
      state = state.copyWith(isRestoring: true);
      
      await _subscriptionService.restorePurchases();
      
      // Invalidate hybrid provider to refresh with new RevenueCat state
      _ref.invalidate(hasPlusHybridProvider);
      
      // Update local state (database may take time to sync)
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
      await _subscriptionService.refreshRevenueCatState();
      
      // Invalidate hybrid provider to refresh with latest state
      _ref.invalidate(hasPlusHybridProvider);
      
      _updateSubscriptionState();
      
    } catch (e) {
      debugPrint('SubscriptionNotifier: Refresh error: $e');
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  @override
  void dispose() {
    debugPrint('SubscriptionNotifier: Disposing');
    _authSubscription.cancel();
    super.dispose();
  }
}

// Provider for SubscriptionService instance
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

// Direct database watch provider for user subscription
final userSubscriptionStreamProvider = StreamProvider<UserSubscriptionEntry?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    debugPrint('userSubscriptionStreamProvider: No current user');
    return Stream.value(null);
  }
  
  debugPrint('userSubscriptionStreamProvider: Watching subscription for user ${currentUser.id}');
  return (appDb.select(appDb.userSubscriptions)
    ..where((tbl) => tbl.userId.equals(currentUser.id)))
    .watchSingleOrNull();
});

// Debug provider to see what's in the database
final subscriptionDebugProvider = Provider<String>((ref) {
  final subscriptionAsync = ref.watch(userSubscriptionStreamProvider);
  
  return subscriptionAsync.when(
    data: (subscription) {
      if (subscription == null) {
        return "DEBUG: No subscription found in database";
      }
      return "DEBUG: Status=${subscription.status.name}, Entitlements=${subscription.entitlements}, ExpiresAt=${subscription.expiresAt}";
    },
    loading: () => "DEBUG: Loading subscription...",
    error: (error, _) => "DEBUG: Error loading subscription: $error",
  );
});

// Main subscription state provider
final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  
  return SubscriptionNotifier(
    subscriptionService: subscriptionService,
    ref: ref,
  );
});

// Reactive provider for checking Plus access - directly watches database
final hasPlusProvider = Provider<bool>((ref) {
  final subscriptionAsync = ref.watch(userSubscriptionStreamProvider);
  
  return subscriptionAsync.when(
    data: (subscription) {
      if (subscription == null) {
        debugPrint('hasPlusProvider: No subscription found');
        return false;
      }
      
      // Simply check if the required entitlement is present
      // RevenueCat webhook removes entitlements when subscription expires
      final hasPlus = subscription.entitlements.contains('plus');
      
      debugPrint('hasPlusProvider: status=${subscription.status.name}, entitlements=${subscription.entitlements}, hasPlus=$hasPlus');
      return hasPlus;
    },
    loading: () {
      debugPrint('hasPlusProvider: Loading subscription data...');
      return false; // Default to no access while loading
    },
    error: (error, _) {
      debugPrint('hasPlusProvider: Error loading subscription: $error');
      return false; // Default to no access on error
    },
  );
});

// Hybrid provider that combines database and RevenueCat for immediate access
final hasPlusHybridProvider = FutureProvider<bool>((ref) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  
  debugPrint('hasPlusHybridProvider: Starting hybrid check');
  
  // First ensure we have fresh database cache
  await subscriptionService.refreshSubscriptionStatus();
  
  // Use hybrid check with RevenueCat fallback
  final result = await subscriptionService.hasPlus(allowRevenueCatFallback: true);
  
  debugPrint('hasPlusHybridProvider: Result = $result');
  return result;
});

// Convenience provider for loading states
final subscriptionLoadingProvider = Provider<bool>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.isLoading;
});

// Convenience provider for error state
final subscriptionErrorProvider = Provider<String?>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.error;
});

// Convenience provider for checking if any subscription operation is in progress
final subscriptionBusyProvider = Provider<bool>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.isBusy;
});

// Convenience provider for checking if user is actively restoring purchases
final subscriptionRestoringProvider = Provider<bool>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.isRestoring;
});

// Convenience provider for checking if paywall is currently showing
final subscriptionShowingPaywallProvider = Provider<bool>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.isShowingPaywall;
});

// Convenience provider for last checked timestamp
final subscriptionLastCheckedProvider = Provider<DateTime?>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.lastChecked;
});

// Convenience provider for all entitlements map
final subscriptionEntitlementsProvider = Provider<Map<String, bool>?>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.entitlements;
});

// Helper provider for checking specific entitlements
final entitlementProvider = Provider.family<bool, String>((ref, entitlementId) {
  final entitlements = ref.watch(subscriptionEntitlementsProvider);
  return entitlements?[entitlementId] ?? false;
});

// Provider for subscription status summary (useful for UI display)
final subscriptionStatusProvider = Provider<String>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  
  if (subscriptionState.hasError) {
    return 'Error';
  } else if (subscriptionState.isBusy) {
    return 'Loading...';
  } else if (subscriptionState.hasPlus) {
    return 'Plus Active';
  } else {
    return 'Free';
  }
});

// Convenience provider for subscription metadata
final subscriptionMetadataProvider = Provider<Map<String, dynamic>?>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.subscriptionMetadata;
});

// Convenience provider for subscription status
final subscriptionStatusStringProvider = Provider<String?>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.subscriptionStatus;
});

// Convenience provider for trial status
final subscriptionTrialActiveProvider = Provider<bool>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.isTrialActive;
});

// Convenience provider for expiration date
final subscriptionExpiresAtProvider = Provider<DateTime?>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.expiresAt;
});

// Provider for determining if paywall should be shown for feature access
final shouldShowPaywallProvider = Provider.family<bool, String>((ref, feature) {
  final hasPlus = ref.watch(hasPlusProvider);
  final isLoading = ref.watch(subscriptionLoadingProvider);
  
  // Don't show paywall while loading to avoid flickering
  if (isLoading) return false;
  
  // For now, all premium features require Plus
  // This can be expanded for different tiers
  switch (feature) {
    case 'labs':
    case 'advanced_search':
    case 'unlimited_recipes':
    case 'cloud_sync':
      return !hasPlus;
    default:
      return false;
  }
});