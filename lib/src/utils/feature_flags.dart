import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription_state.dart';

/// Utility class for checking feature access based on subscription status
class FeatureFlags {
  /// Check if user has access to a specific feature
  static bool hasFeature(String feature, WidgetRef ref) {
    final subscription = ref.read(subscriptionProvider);
    return hasFeatureSync(feature, subscription);
  }
  
  /// Synchronous version for widgets that already have subscription state
  static bool hasFeatureSync(String feature, SubscriptionState subscription) {
    switch (feature) {
      case 'labs':
      case 'advanced_analytics':
      case 'premium_recipes':
      case 'experimental_features':
      case 'enhanced_pantry':
      case 'smart_recommendations':
      case 'advanced_meal_planning':
      case 'premium_export':
      case 'priority_support':
        return subscription.hasPlus;
      default:
        return true; // Free features - allow access by default
    }
  }
  
  /// Get the subscription tier required for a feature
  static String getRequiredTier(String feature) {
    switch (feature) {
      case 'labs':
      case 'advanced_analytics':
      case 'premium_recipes':
      case 'experimental_features':
      case 'enhanced_pantry':
      case 'smart_recommendations':
      case 'advanced_meal_planning':
      case 'premium_export':
      case 'priority_support':
        return 'plus';
      default:
        return 'free';
    }
  }
  
  /// Get user-friendly description of what a feature provides
  static String getFeatureDescription(String feature) {
    switch (feature) {
      case 'labs':
        return 'Access to experimental features and early previews';
      case 'advanced_analytics':
        return 'Detailed insights into your cooking patterns and habits';
      case 'premium_recipes':
        return 'Exclusive premium recipe collections';
      case 'experimental_features':
        return 'Beta features and cutting-edge functionality';
      case 'enhanced_pantry':
        return 'Advanced pantry management with smart suggestions';
      case 'smart_recommendations':
        return 'AI-powered recipe recommendations based on your preferences';
      case 'advanced_meal_planning':
        return 'Enhanced meal planning with nutritional insights';
      case 'premium_export':
        return 'Export recipes and meal plans in multiple formats';
      case 'priority_support':
        return 'Priority customer support and direct feedback channel';
      default:
        return 'Premium feature';
    }
  }
  
  /// Get all available premium features
  static List<String> get premiumFeatures => [
    'labs',
    'advanced_analytics',
    'premium_recipes',
    'experimental_features',
    'enhanced_pantry',
    'smart_recommendations',
    'advanced_meal_planning',
    'premium_export',
    'priority_support',
  ];
  
  /// Get all free features (for documentation purposes)
  static List<String> get freeFeatures => [
    'recipes',
    'pantry',
    'shopping_list',
    'meal_plans',
    'basic_search',
    'recipe_creation',
    'recipe_sharing',
    'basic_household',
  ];
}

/// Feature gate widget for easy premium feature protection
class FeatureGate extends ConsumerWidget {
  final String feature;
  final Widget child;
  final Widget? fallback;
  final bool showUpgradeButton;
  final String? customUpgradeText;
  
  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.fallback,
    this.showUpgradeButton = true,
    this.customUpgradeText,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    final isLoading = ref.watch(subscriptionLoadingProvider);
    final error = ref.watch(subscriptionErrorProvider);
    
    // Show loading indicator if checking subscription
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    
    // Show error widget if there's an error
    if (error != null) {
      return _buildErrorWidget(context, ref, error);
    }
    
    // Check feature access
    final hasAccess = FeatureFlags.hasFeatureSync(feature, subscription);
    if (hasAccess) {
      return child;
    }
    
    // User doesn't have access, show fallback or upgrade prompt
    return fallback ?? _buildUpgradePrompt(context, ref);
  }
  
  Widget _buildUpgradePrompt(BuildContext context, WidgetRef ref) {
    if (!showUpgradeButton) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.lock_fill,
            size: 48,
            color: CupertinoColors.systemOrange.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Premium Feature',
            style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            FeatureFlags.getFeatureDescription(feature),
            style: CupertinoTheme.of(context).textTheme.textStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: () async {
              await ref.read(subscriptionProvider.notifier).presentPaywall();
            },
            child: Text(customUpgradeText ?? 'Upgrade to Stockpot Plus'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 48,
            color: CupertinoColors.systemRed.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to verify subscription status',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: () {
              // Try to refresh subscription status
              ref.read(subscriptionProvider.notifier).refresh();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

/// Simple widget to conditionally show content based on subscription
class PremiumBadge extends ConsumerWidget {
  final String? feature;
  final Widget? child;
  final bool showWhenFree;
  
  const PremiumBadge({
    super.key,
    this.feature,
    this.child,
    this.showWhenFree = false,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPlus = ref.watch(hasPlusProvider);
    
    // If user has plus, show premium badge or custom child
    if (hasPlus) {
      return child ?? Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGreen.resolveFrom(context),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'PLUS',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    // If feature is specified and is premium, show lock icon
    if (feature != null && !FeatureFlags.hasFeatureSync(feature!, SubscriptionState(hasPlus: false))) {
      return Icon(
        CupertinoIcons.lock_fill,
        size: 16,
        color: CupertinoColors.systemOrange.resolveFrom(context),
      );
    }
    
    // Show when free or hide completely
    return showWhenFree ? (child ?? const SizedBox.shrink()) : const SizedBox.shrink();
  }
}

/// Utility function to check if a feature should show paywall
bool shouldShowPaywallForFeature(String feature, SubscriptionState subscription) {
  return !FeatureFlags.hasFeatureSync(feature, subscription) && 
         FeatureFlags.getRequiredTier(feature) != 'free';
}