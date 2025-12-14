import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database.dart';
import '../../database/powersync.dart';
import '../../database/models/user_subscriptions.dart';
import '../models/subscription_state.dart';
import '../services/subscription_service.dart';
import '../services/logging/app_logger.dart';
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
      }).catchError((e) {
        AppLogger.error('Error refreshing subscription state', e);
        state = state.setError(e.toString());
      });
    } catch (e) {
      AppLogger.error('Error updating subscription state', e);
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
      AppLogger.error('Subscription initialization failed', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Present paywall
  Future<bool> presentPaywall(BuildContext context) async {
    try {
      state = state.copyWith(isShowingPaywall: true);

      final purchased = await _subscriptionService.presentPaywall(context);

      if (purchased) {
        // Grant immediate optimistic access (before database syncs)
        state = state.copyWith(optimisticHasPlus: true);

        // Invalidate hybrid provider to refresh with new RevenueCat state
        _ref.invalidate(hasPlusHybridProvider);

        // Also update local state (database may take time to sync)
        _updateSubscriptionState();
      }

      return purchased;
    } catch (e) {
      AppLogger.error('Paywall error', e);
      state = state.copyWith(error: e.toString());
      return false;
    } finally {
      state = state.copyWith(isShowingPaywall: false);
    }
  }

  /// Present paywall only if user doesn't have Plus subscription
  Future<bool> presentPaywallIfNeeded(BuildContext context) async {
    // Check hybrid state to ensure we have the most current status
    final hasPlus = await _subscriptionService.hasPlus();

    if (hasPlus) {
      return true;
    }

    return await presentPaywall(context);
  }

  /// Get current subscription metadata
  Map<String, dynamic>? get subscriptionMetadata => state.subscriptionMetadata;

  /// Restore purchases
  /// Returns the result of the restore operation
  Future<RestoreResult> restorePurchases() async {
    try {
      state = state.copyWith(isRestoring: true, error: null);

      final result = await _subscriptionService.restorePurchases();

      switch (result) {
        case RestoreResult.success:
          // Immediate success - grant optimistic access and invalidate provider
          _ref.invalidate(hasPlusHybridProvider);
          state = state.copyWith(
            isRestoring: false,
            hasPlus: true,
            optimisticHasPlus: true,
          );
          break;

        case RestoreResult.transferPending:
          // Transfer in progress - grant optimistic access while waiting for webhook
          state = state.copyWith(
            isRestoring: false,
            optimisticHasPlus: true,
          );
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
    const maxAttempts = 6; // 30 seconds total
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
      AppLogger.error('Subscription refresh error', e);
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}

// Provider for SubscriptionService instance
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

// All subscriptions stream provider - gets ALL subscriptions that PowerSync synced down
final allSubscriptionsStreamProvider = StreamProvider<List<UserSubscriptionEntry>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value([]);
  }

  // Get ALL subscriptions that PowerSync synced down
  // PowerSync sync rules ensure user only gets subscriptions they're entitled to
  return appDb.select(appDb.userSubscriptions).watch();
});

// Debug provider to see what's in the database
final subscriptionDebugProvider = Provider<String>((ref) {
  final subscriptionsAsync = ref.watch(allSubscriptionsStreamProvider);
  
  return subscriptionsAsync.when(
    data: (subscriptions) {
      if (subscriptions.isEmpty) {
        return "DEBUG: No subscriptions found in database";
      }
      final subscription = subscriptions.first;
      return "DEBUG: Found ${subscriptions.length} subscriptions - Status=${subscription.status.name}, Entitlements=${subscription.entitlements}, ExpiresAt=${subscription.expiresAt}";
    },
    loading: () => "DEBUG: Loading subscriptions...",
    error: (error, _) => "DEBUG: Error loading subscriptions: $error",
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

// Reactive provider for checking Plus access - checks ALL subscriptions (database only)
final hasPlusProvider = Provider<bool>((ref) {
  final subscriptionsAsync = ref.watch(allSubscriptionsStreamProvider);

  return subscriptionsAsync.when(
    data: (subscriptions) {
      // Check if ANY subscription has plus entitlement and is active
      return subscriptions.any((subscription) =>
          subscription.entitlements.contains('plus') &&
          subscription.status == SubscriptionStatus.active);
    },
    loading: () => false, // Default to no access while loading
    error: (error, _) => false, // Default to no access on error
  );
});

// Effective provider that combines database truth with optimistic access
// Use this for UI gating - provides immediate access after purchase while database syncs
final effectiveHasPlusProvider = Provider<bool>((ref) {
  final dbHasPlus = ref.watch(hasPlusProvider);
  final optimisticHasPlus = ref.watch(subscriptionProvider).optimisticHasPlus;
  return dbHasPlus || optimisticHasPlus;
});

// Hybrid provider that combines database and RevenueCat for immediate access
final hasPlusHybridProvider = FutureProvider<bool>((ref) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);

  // First ensure we have fresh database cache
  await subscriptionService.refreshSubscriptionStatus();

  // Use hybrid check with RevenueCat fallback
  return await subscriptionService.hasPlus(allowRevenueCatFallback: true);
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
  final hasPlus = ref.watch(effectiveHasPlusProvider);
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