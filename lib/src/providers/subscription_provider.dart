import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../models/subscription_state.dart';
import '../services/subscription_service.dart';
import 'auth_provider.dart';

/// StateNotifier for managing subscription state and operations
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SubscriptionService _subscriptionService;
  final Ref _ref;
  
  late final StreamSubscription _authSubscription;
  StreamSubscription<CustomerInfo>? _customerInfoSubscription;
  Timer? _periodicRefreshTimer;

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
    _authSubscription = _ref.watch(authNotifierProvider.notifier).stream.listen((authState) {
      debugPrint('SubscriptionNotifier: Auth state changed, authenticated: ${authState.isAuthenticated}');
      _handleAuthChange(authState.isAuthenticated);
    });

    // Check initial auth state and initialize if authenticated
    final currentAuthState = _ref.read(authNotifierProvider);
    if (currentAuthState.isAuthenticated) {
      _handleAuthChange(true);
    }
  }

  Future<void> _handleAuthChange(bool isAuthenticated) async {
    if (isAuthenticated) {
      await _initializeForAuthenticatedUser();
    } else {
      await _cleanupForUnauthenticatedUser();
    }
  }

  Future<void> _initializeForAuthenticatedUser() async {
    try {
      debugPrint('SubscriptionNotifier: Initializing for authenticated user');
      
      // Initialize RevenueCat and sync user ID
      await _subscriptionService.initialize();
      await _subscriptionService.syncUserId();
      
      // Set up customer info stream for real-time updates
      _setupCustomerInfoStream();
      
      // Set up periodic refresh timer
      _setupPeriodicRefresh();
      
      // Check current subscription status
      await checkSubscriptionStatus();
      
    } catch (e) {
      debugPrint('SubscriptionNotifier: Error initializing for authenticated user: $e');
      state = state.setError(SubscriptionService.getErrorMessage(e as Exception));
    }
  }

  Future<void> _cleanupForUnauthenticatedUser() async {
    debugPrint('SubscriptionNotifier: Cleaning up for unauthenticated user');
    
    // Cancel subscriptions and timers
    _customerInfoSubscription?.cancel();
    _customerInfoSubscription = null;
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = null;
    
    // Reset state
    state = const SubscriptionState();
  }

  void _setupCustomerInfoStream() {
    _customerInfoSubscription?.cancel();
    
    // Use the service's customer info stream for real-time updates
    _customerInfoSubscription = _subscriptionService.customerInfoStream.listen(
      (customerInfo) {
        debugPrint('SubscriptionNotifier: Customer info updated');
        _updateStateFromCustomerInfo(customerInfo);
      },
      onError: (error) {
        debugPrint('SubscriptionNotifier: Customer info stream error: $error');
        // Don't update error state from stream errors to avoid interrupting user flow
      },
    );
  }

  void _setupPeriodicRefresh() {
    _periodicRefreshTimer?.cancel();
    
    // Refresh subscription status every 5 minutes when app is active
    _periodicRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!state.isBusy) {
        debugPrint('SubscriptionNotifier: Periodic refresh triggered');
        checkSubscriptionStatus();
      }
    });
  }

  void _updateStateFromCustomerInfo(CustomerInfo customerInfo) {
    final hasPlus = customerInfo.entitlements.all['plus']?.isActive ?? false;
    
    // Extract all entitlements for comprehensive state
    final entitlements = <String, bool>{};
    for (final entry in customerInfo.entitlements.all.entries) {
      entitlements[entry.key] = entry.value.isActive;
    }
    
    state = state.updateAccess(
      hasPlus: hasPlus,
      entitlements: entitlements,
    );
  }

  /// Check current subscription status
  Future<void> checkSubscriptionStatus() async {
    if (state.isLoading) return;
    
    state = state.setLoading(true);
    
    try {
      debugPrint('SubscriptionNotifier: Checking subscription status');
      final hasPlus = await _subscriptionService.hasPlus();
      
      state = state.updateAccess(hasPlus: hasPlus);
      debugPrint('SubscriptionNotifier: Subscription status updated - hasPlus: $hasPlus');
    } catch (e) {
      debugPrint('SubscriptionNotifier: Error checking subscription status: $e');
      state = state.setError(SubscriptionService.getErrorMessage(e as Exception));
    }
  }

  /// Present paywall to user
  Future<bool> presentPaywall() async {
    if (state.isBusy) return false;
    
    state = state.setLoading(true);
    
    try {
      debugPrint('SubscriptionNotifier: Presenting paywall');
      final purchased = await _subscriptionService.presentPaywall();
      
      if (purchased) {
        // Refresh subscription status after successful purchase
        await checkSubscriptionStatus();
        debugPrint('SubscriptionNotifier: Purchase successful, status refreshed');
      } else {
        state = state.setLoading(false);
        debugPrint('SubscriptionNotifier: Purchase not completed');
      }
      
      return purchased;
    } catch (e) {
      debugPrint('SubscriptionNotifier: Error presenting paywall: $e');
      state = state.setError(SubscriptionService.getErrorMessage(e as Exception));
      return false;
    }
  }

  /// Present paywall only if user doesn't have Plus subscription
  Future<bool> presentPaywallIfNeeded() async {
    if (state.isBusy) return state.hasPlus;
    
    state = state.setLoading(true);
    
    try {
      debugPrint('SubscriptionNotifier: Presenting paywall if needed');
      final result = await _subscriptionService.presentPaywallIfNeeded();
      
      // Refresh subscription status regardless of result
      await checkSubscriptionStatus();
      debugPrint('SubscriptionNotifier: Paywall flow completed, status refreshed');
      
      return result;
    } catch (e) {
      debugPrint('SubscriptionNotifier: Error in paywall if needed: $e');
      state = state.setError(SubscriptionService.getErrorMessage(e as Exception));
      return false;
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    if (state.isRestoring) return;
    
    state = state.setRestoring(true);
    
    try {
      debugPrint('SubscriptionNotifier: Restoring purchases');
      await _subscriptionService.restorePurchases();
      
      // Refresh subscription status after restore
      await checkSubscriptionStatus();
      debugPrint('SubscriptionNotifier: Purchases restored successfully');
    } catch (e) {
      debugPrint('SubscriptionNotifier: Error restoring purchases: $e');
      state = state.setError(SubscriptionService.getErrorMessage(e as Exception));
    }
  }

  /// Refresh subscription status manually
  Future<void> refresh() async {
    debugPrint('SubscriptionNotifier: Manual refresh requested');
    await checkSubscriptionStatus();
  }

  /// Clear error state
  void clearError() {
    state = state.clearError();
  }

  @override
  void dispose() {
    debugPrint('SubscriptionNotifier: Disposing');
    _authSubscription.cancel();
    _customerInfoSubscription?.cancel();
    _periodicRefreshTimer?.cancel();
    super.dispose();
  }
}

// Provider for SubscriptionService instance
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

// Main subscription state provider
final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  
  return SubscriptionNotifier(
    subscriptionService: subscriptionService,
    ref: ref,
  );
});

// Convenience provider for checking Plus access
final hasPlusProvider = Provider<bool>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.hasPlus;
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