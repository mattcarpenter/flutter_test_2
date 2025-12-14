import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_state.freezed.dart';

@freezed
abstract class SubscriptionState with _$SubscriptionState {
  const factory SubscriptionState({
    @Default(false) bool hasPlus,
    @Default(false) bool isLoading,
    @Default(false) bool isRestoring,
    @Default(false) bool isShowingPaywall,
    /// Temporary optimistic access granted immediately after purchase/restore,
    /// before the database has synced. Cleared when database confirms.
    @Default(false) bool optimisticHasPlus,
    String? error,
    DateTime? lastChecked,
    Map<String, bool>? entitlements,
    Map<String, dynamic>? subscriptionMetadata,
  }) = _SubscriptionState;

  const SubscriptionState._();

  /// Whether the user has an active subscription
  bool get isActive => hasPlus;

  /// Whether there's an error state
  bool get hasError => error != null;

  /// Whether any operation is in progress
  bool get isBusy => isLoading || isRestoring || isShowingPaywall;

  /// Clear error state
  SubscriptionState clearError() => copyWith(error: null);

  /// Set loading state
  SubscriptionState setLoading(bool loading) => copyWith(isLoading: loading);

  /// Set restoring state
  SubscriptionState setRestoring(bool restoring) => copyWith(isRestoring: restoring);

  /// Set error state
  SubscriptionState setError(String error) => copyWith(
    error: error,
    isLoading: false,
    isRestoring: false,
  );

  /// Update subscription status
  /// If database confirms hasPlus, clears the optimistic flag (no longer needed)
  SubscriptionState updateAccess({
    required bool hasPlus,
    Map<String, bool>? entitlements,
    Map<String, dynamic>? subscriptionMetadata,
  }) => copyWith(
    hasPlus: hasPlus,
    entitlements: entitlements,
    subscriptionMetadata: subscriptionMetadata,
    lastChecked: DateTime.now(),
    isLoading: false,
    isRestoring: false,
    isShowingPaywall: false,
    error: null,
    // Clear optimistic flag when database confirms subscription
    optimisticHasPlus: hasPlus ? false : optimisticHasPlus,
  );

  /// Get subscription status from metadata
  String? get subscriptionStatus => subscriptionMetadata?['status'] as String?;

  /// Get subscription expires date from metadata
  DateTime? get expiresAt {
    final expiresAtStr = subscriptionMetadata?['expires_at'] as String?;
    if (expiresAtStr == null) return null;
    return DateTime.tryParse(expiresAtStr);
  }

  /// Get subscription product ID from metadata
  String? get productId => subscriptionMetadata?['product_id'] as String?;

  /// Get subscription store from metadata
  String? get store => subscriptionMetadata?['store'] as String?;

  /// Whether subscription is in trial period
  bool get isTrialActive {
    final trialEndsAtStr = subscriptionMetadata?['trial_ends_at'] as String?;
    if (trialEndsAtStr == null) return false;
    final trialEndsAt = DateTime.tryParse(trialEndsAtStr);
    return trialEndsAt != null && DateTime.now().isBefore(trialEndsAt);
  }
}

@freezed
abstract class PaywallContext with _$PaywallContext {
  const factory PaywallContext({
    required String source,
    String? redirectPath,
    Map<String, dynamic>? parameters,
    DateTime? timestamp,
  }) = _PaywallContext;

  const PaywallContext._();

  /// Create context for feature gate
  factory PaywallContext.featureGate(String feature) => PaywallContext(
    source: 'feature_gate',
    parameters: {'feature': feature},
    timestamp: DateTime.now(),
  );

  /// Create context for route protection
  factory PaywallContext.routeProtection(String route) => PaywallContext(
    source: 'route_protection',
    redirectPath: route,
    timestamp: DateTime.now(),
  );

  /// Create context for upgrade prompt
  factory PaywallContext.upgradePrompt() => PaywallContext(
    source: 'upgrade_prompt',
    timestamp: DateTime.now(),
  );
}
