import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_state.freezed.dart';

@freezed
class SubscriptionState with _$SubscriptionState {
  const factory SubscriptionState({
    @Default(false) bool hasPlus,
    @Default(false) bool isLoading,
    @Default(false) bool isRestoring,
    String? error,
    DateTime? lastChecked,
    Map<String, bool>? entitlements,
  }) = _SubscriptionState;
  
  const SubscriptionState._();
  
  /// Whether the user has an active subscription
  bool get isActive => hasPlus;
  
  /// Whether there's an error state
  bool get hasError => error != null;
  
  /// Whether any operation is in progress
  bool get isBusy => isLoading || isRestoring;
  
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
  SubscriptionState updateAccess({
    required bool hasPlus,
    Map<String, bool>? entitlements,
  }) => copyWith(
    hasPlus: hasPlus,
    entitlements: entitlements,
    lastChecked: DateTime.now(),
    isLoading: false,
    isRestoring: false,
    error: null,
  );
}

@freezed
class PaywallContext with _$PaywallContext {
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