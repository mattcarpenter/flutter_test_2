import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription_state.dart';

/// Utility class for checking feature access based on subscription status
class FeatureFlags {
  /// Check if user has access to a specific feature
  /// NOTE: This method uses ref.watch and should only be used in build methods
  /// For non-reactive checks, use hasFeatureSync directly with subscription state
  static bool hasFeature(String feature, WidgetRef ref) {
    final hasPlus = ref.watch(effectiveHasPlusProvider);
    return hasFeatureSync(feature, SubscriptionState(hasPlus: hasPlus));
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
      case 'unlimited_recipes':
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
      case 'unlimited_recipes':
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
      case 'unlimited_recipes':
        return 'Unlimited recipe storage with no restrictions';
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
    'unlimited_recipes',
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
  ];

  /// Features that require full registration (not available to anonymous users)
  static List<String> get registrationRequiredFeatures => [
    'household',
    'household_sharing',
    'household_invites',
    'recipe_sharing', // Sharing recipes requires registration to link ownership
  ];

  /// Check if a feature requires full registration (not anonymous)
  static bool requiresRegistration(String feature) {
    return registrationRequiredFeatures.contains(feature);
  }

  /// Check if user has access to a feature considering both subscription and registration
  /// Returns a tuple of (hasAccess, blockedReason)
  static ({bool hasAccess, String? blockedReason}) checkFeatureAccess({
    required String feature,
    required bool hasPlus,
    required bool isEffectivelyAuthenticated,
  }) {
    // First check registration requirement
    if (requiresRegistration(feature) && !isEffectivelyAuthenticated) {
      return (hasAccess: false, blockedReason: 'registration_required');
    }

    // Then check subscription requirement
    if (!hasFeatureSync(feature, SubscriptionState(hasPlus: hasPlus))) {
      return (hasAccess: false, blockedReason: 'subscription_required');
    }

    return (hasAccess: true, blockedReason: null);
  }
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
    // Use effectiveHasPlusProvider for immediate access after purchase (includes optimistic state)
    final hasPlus = ref.watch(effectiveHasPlusProvider);
    final isEffectivelyAuthenticated = ref.watch(isAuthenticatedProvider);
    final error = ref.watch(subscriptionErrorProvider);

    // Show error widget if there's an error
    if (error != null) {
      return _buildErrorWidget(context, ref, error);
    }

    // First check registration requirement (synchronous check)
    if (FeatureFlags.requiresRegistration(feature) && !isEffectivelyAuthenticated) {
      return fallback ?? _buildRegistrationPrompt(context, ref);
    }

    // Check feature access using reactive provider
    final hasAccess = FeatureFlags.hasFeatureSync(feature, SubscriptionState(hasPlus: hasPlus));

    if (hasAccess) {
      return child;
    }

    // User doesn't have access, show fallback or upgrade prompt
    return fallback ?? _buildUpgradePrompt(context, ref);
  }

  Widget _buildRegistrationPrompt(BuildContext context, WidgetRef ref) {
    if (!showUpgradeButton) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedUserCircle,
            size: 48,
            color: CupertinoColors.systemBlue.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Account Required',
            style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Create an account to access ${_getFeatureDisplayName(feature)} and sync your data across devices.',
            style: CupertinoTheme.of(context).textTheme.textStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: () {
              // Navigate to auth flow
              Navigator.of(context).pushNamed('/auth');
            },
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }

  String _getFeatureDisplayName(String feature) {
    switch (feature) {
      case 'household':
      case 'household_sharing':
      case 'household_invites':
        return 'Household features';
      case 'recipe_sharing':
        return 'recipe sharing';
      default:
        return feature.replaceAll('_', ' ');
    }
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
              await ref.read(subscriptionProvider.notifier).presentPaywall(context);
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
    final hasPlus = ref.watch(effectiveHasPlusProvider);
    
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