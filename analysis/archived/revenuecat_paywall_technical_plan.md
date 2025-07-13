# RevenueCat Paywall Integration: Detailed Technical Implementation Plan

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Dependencies & Setup](#dependencies--setup)
3. [Core Components Implementation](#core-components-implementation)
4. [Route Protection System](#route-protection-system)
5. [Paywall UI Implementation](#paywall-ui-implementation)
6. [State Management Integration](#state-management-integration)
7. [Testing Strategy](#testing-strategy)
8. [Configuration Requirements](#configuration-requirements)
9. [Implementation Timeline](#implementation-timeline)

## Architecture Overview

### System Architecture Diagram
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   RevenueCat    │    │   Supabase       │    │   Flutter App   │
│   Dashboard     │◄──►│   User Metadata  │◄──►│   State Mgmt    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                       ┌──────────────────┐             │
                       │   App Store      │◄────────────┘
                       │   Connect        │
                       └──────────────────┘
```

### Data Flow Architecture
```
User Action → Route Guard Check → Subscription Provider → 
RevenueCat Service → Paywall UI → Purchase Flow → 
Entitlement Update → Route Access Granted
```

### Key Integration Points
1. **GoRouter Middleware**: Route protection at navigation level
2. **Riverpod Providers**: Reactive subscription state management
3. **Supabase Sync**: User metadata synchronization
4. **Menu System**: Premium status indicators
5. **Analytics**: Purchase funnel tracking

## Dependencies & Setup

### pubspec.yaml Dependencies
```yaml
dependencies:
  # Existing dependencies...
  purchases_flutter: ^9.0.0-beta.1
  purchases_ui_flutter: ^9.0.0-beta.1
  
dev_dependencies:
  # Existing dev dependencies...
```

### Platform Configuration

#### iOS (ios/Runner/Info.plist)
```xml
<!-- Add to existing Info.plist -->
<key>RevenueCat</key>
<dict>
    <key>APIKey</key>
    <string>YOUR_REVENUECAT_API_KEY</string>
</dict>
```

#### Android (android/app/src/main/AndroidManifest.xml)
```xml
<!-- Add to existing manifest -->
<application>
    <!-- Existing configuration... -->
    <meta-data
        android:name="REVENUECAT_API_KEY"
        android:value="YOUR_REVENUECAT_API_KEY" />
</application>
```

## Core Components Implementation

### 1. SubscriptionService Implementation

**File**: `lib/src/services/subscription_service.dart`

```dart
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';

class SubscriptionService {
  static const String _apiKey = 'appl_SPuDBCvjoalGuumyxdYEfRZKEXt';
  static const String _plusEntitlementId = 'plus';
  
  bool _isInitialized = false;
  
  /// Initialize RevenueCat with proper configuration
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) return;
    
    try {
      final configuration = PurchasesConfiguration(_apiKey);
      if (userId != null) {
        configuration.appUserID = userId;
      }
      
      await Purchases.configure(configuration);
      
      // Set up debug logging for development
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }
      
      _isInitialized = true;
      debugPrint('RevenueCat initialized successfully');
    } catch (e) {
      debugPrint('RevenueCat initialization failed: $e');
      rethrow;
    }
  }
  
  /// Check if user has Stockpot Plus access
  Future<bool> hasPlus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(_plusEntitlementId);
    } catch (e) {
      debugPrint('Error checking Plus access: $e');
      // Graceful degradation - deny access on error
      return false;
    }
  }
  
  /// Stream of subscription status changes
  Stream<bool> get plusAccessStream {
    return Purchases.getCustomerInfoStream().map((customerInfo) {
      return customerInfo.entitlements.active.containsKey(_plusEntitlementId);
    }).handleError((error) {
      debugPrint('Error in subscription stream: $error');
      return false;
    });
  }
  
  /// Present RevenueCat paywall
  Future<bool> presentPaywall({String? offeringId}) async {
    try {
      final result = await RevenueCatUI.presentPaywall();
      return result == PaywallResult.purchased;
    } catch (e) {
      debugPrint('Error presenting paywall: $e');
      return false;
    }
  }
  
  /// Present paywall only if user lacks entitlement
  Future<bool> presentPaywallIfNeeded({String? offeringId}) async {
    try {
      final result = await RevenueCatUI.presentPaywallIfNeeded(_plusEntitlementId);
      return result == PaywallResult.purchased;
    } catch (e) {
      debugPrint('Error presenting conditional paywall: $e');
      return false;
    }
  }
  
  /// Restore purchases
  Future<void> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      rethrow;
    }
  }
  
  /// Get current customer info for debugging
  Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }
  
  /// Handle user authentication changes
  Future<void> updateUserId(String? userId) async {
    try {
      if (userId != null) {
        await Purchases.logIn(userId);
      } else {
        await Purchases.logOut();
      }
    } catch (e) {
      debugPrint('Error updating RevenueCat user ID: $e');
      // Don't rethrow - this shouldn't block auth flow
    }
  }
  
  /// Error handling helper
  static String getErrorMessage(Exception error) {
    if (error is PurchasesErrorCode) {
      switch (error) {
        case PurchasesErrorCode.userCancelledError:
          return 'Purchase cancelled';
        case PurchasesErrorCode.networkError:
          return 'Network error. Please check your connection.';
        case PurchasesErrorCode.paymentPendingError:
          return 'Payment is pending. Please wait.';
        default:
          return 'Purchase failed. Please try again.';
      }
    }
    return 'An unexpected error occurred';
  }
}
```

### 2. Subscription Models

**File**: `lib/src/models/subscription_state.dart`

```dart
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
  
  bool get isActive => hasPlus;
  bool get hasError => error != null;
}

@freezed
class PaywallContext with _$PaywallContext {
  const factory PaywallContext({
    required String source,
    String? redirectPath,
    Map<String, dynamic>? parameters,
    DateTime? timestamp,
  }) = _PaywallContext;
}
```

### 3. Riverpod Providers

**File**: `lib/src/providers/subscription_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subscription_service.dart';
import '../models/subscription_state.dart';
import 'auth_provider.dart';

// Provider for SubscriptionService
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

// Provider for subscription state with auth integration
final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, AsyncValue<SubscriptionState>>((ref) {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  final authState = ref.watch(authNotifierProvider);
  
  return SubscriptionNotifier(
    subscriptionService: subscriptionService,
    ref: ref,
  );
});

class SubscriptionNotifier extends StateNotifier<AsyncValue<SubscriptionState>> {
  final SubscriptionService _subscriptionService;
  final Ref _ref;
  
  SubscriptionNotifier({
    required SubscriptionService subscriptionService,
    required Ref ref,
  }) : _subscriptionService = subscriptionService,
       _ref = ref,
       super(const AsyncValue.loading()) {
    _initialize();
  }
  
  Future<void> _initialize() async {
    try {
      // Get current user from auth provider
      final authState = _ref.read(authNotifierProvider);
      final userId = authState.currentUser?.id;
      
      // Initialize RevenueCat with user ID
      await _subscriptionService.initialize(userId: userId);
      
      // Load initial subscription state
      await checkSubscriptionStatus();
      
      // Listen to subscription changes
      _subscriptionService.plusAccessStream.listen((hasAccess) {
        final currentState = state.valueOrNull ?? const SubscriptionState();
        state = AsyncValue.data(currentState.copyWith(
          hasPlus: hasAccess,
          lastChecked: DateTime.now(),
          error: null,
        ));
      });
      
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> checkSubscriptionStatus() async {
    try {
      state = AsyncValue.data(
        (state.valueOrNull ?? const SubscriptionState()).copyWith(isLoading: true)
      );
      
      final hasAccess = await _subscriptionService.hasPlus();
      
      state = AsyncValue.data(SubscriptionState(
        hasPlus: hasAccess,
        isLoading: false,
        lastChecked: DateTime.now(),
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<bool> presentPaywall({String? source}) async {
    try {
      final success = await _subscriptionService.presentPaywall();
      if (success) {
        await checkSubscriptionStatus();
      }
      return success;
    } catch (e) {
      state = AsyncValue.data(
        (state.valueOrNull ?? const SubscriptionState()).copyWith(
          error: SubscriptionService.getErrorMessage(e as Exception),
        )
      );
      return false;
    }
  }
  
  Future<bool> presentPaywallIfNeeded({String? source}) async {
    try {
      final success = await _subscriptionService.presentPaywallIfNeeded();
      if (success) {
        await checkSubscriptionStatus();
      }
      return success;
    } catch (e) {
      state = AsyncValue.data(
        (state.valueOrNull ?? const SubscriptionState()).copyWith(
          error: SubscriptionService.getErrorMessage(e as Exception),
        )
      );
      return false;
    }
  }
  
  Future<void> restorePurchases() async {
    try {
      state = AsyncValue.data(
        (state.valueOrNull ?? const SubscriptionState()).copyWith(isRestoring: true)
      );
      
      await _subscriptionService.restorePurchases();
      await checkSubscriptionStatus();
      
      state = AsyncValue.data(
        (state.valueOrNull ?? const SubscriptionState()).copyWith(isRestoring: false)
      );
    } catch (e) {
      state = AsyncValue.data(
        (state.valueOrNull ?? const SubscriptionState()).copyWith(
          isRestoring: false,
          error: SubscriptionService.getErrorMessage(e as Exception),
        )
      );
    }
  }
  
  void clearError() {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(error: null));
    }
  }
  
  Future<void> handleAuthChange(String? userId) async {
    await _subscriptionService.updateUserId(userId);
    await checkSubscriptionStatus();
  }
}

// Convenience providers
final hasPlusProvider = Provider<bool>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  return subscription.valueOrNull?.hasPlus ?? false;
});

final subscriptionLoadingProvider = Provider<bool>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  return subscription.isLoading || 
         (subscription.valueOrNull?.isLoading ?? false) ||
         (subscription.valueOrNull?.isRestoring ?? false);
});
```

## Route Protection System

### GoRouter Integration

**File Updates**: `lib/src/mobile/adaptive_app.dart`

```dart
// Add to existing GoRoute for Labs
GoRoute(
  path: '/labs',
  redirect: (context, state) async {
    // Check if user is authenticated first
    final authState = ref.read(authNotifierProvider);
    if (!authState.isAuthenticated) {
      return '/auth?redirect=${Uri.encodeComponent(state.matchedLocation)}';
    }
    
    // Check subscription status
    final subscription = await ref.read(subscriptionProvider.future);
    if (!subscription.hasPlus) {
      // Show RevenueCat paywall directly
      final purchased = await ref.read(subscriptionServiceProvider).presentPaywallIfNeeded();
      if (!purchased) {
        return '/recipes'; // Redirect to safe location if cancelled
      }
    }
    
    return null; // Allow access
  },
  routes: [
    // Existing Labs sub-routes...
    GoRoute(
      path: 'sub',
      redirect: (context, state) async {
        // Same subscription check for sub-routes
        final subscription = await ref.read(subscriptionProvider.future);
        if (!subscription.hasPlus) {
          final purchased = await ref.read(subscriptionServiceProvider).presentPaywallIfNeeded();
          if (!purchased) return '/recipes';
        }
        return null;
      },
      pageBuilder: (context, state) => _platformPage(
        state: state,
        child: const LabsSubPage(),
      ),
    ),
  ],
  pageBuilder: (context, state) => _platformPage(
    state: state,
    child: LabsTab(
      onMenuPressed: () {
        _mainPageShellKey.currentState?.toggleDrawer();
      },
    ),
  ),
),

// No custom paywall route needed - using RevenueCat built-in paywalls only
```

### Route Guard Component

**File**: `lib/src/widgets/subscription_gate.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/subscription_provider.dart';
import '../mobile/utils/adaptive_sliver_page.dart';

class SubscriptionGate extends ConsumerWidget {
  final Widget child;
  final String feature;
  final String upgradeTitle;
  final String upgradeDescription;
  
  const SubscriptionGate({
    super.key,
    required this.child,
    required this.feature,
    this.upgradeTitle = 'Premium Feature',
    this.upgradeDescription = 'This feature requires a premium subscription.',
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    
    return subscription.when(
      data: (state) {
        if (state.hasLabsAccess) {
          return child;
        }
        
        return AdaptiveSliverPage(
          title: upgradeTitle,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.lock_fill,
                    size: 64,
                    color: CupertinoColors.systemOrange,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    upgradeTitle,
                    style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    upgradeDescription,
                    style: CupertinoTheme.of(context).textTheme.textStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  CupertinoButton.filled(
                    onPressed: () async {
                      final success = await ref
                          .read(subscriptionProvider.notifier)
                          .presentPaywall(source: feature);
                      
                      if (success) {
                        // Success handled by provider state updates
                      }
                    },
                    child: const Text('Upgrade to Premium'),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    onPressed: () async {
                      await ref
                          .read(subscriptionProvider.notifier)
                          .restorePurchases();
                    },
                    child: const Text('Restore Purchases'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, stack) => AdaptiveSliverPage(
        title: 'Error',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 64,
                color: CupertinoColors.systemRed,
              ),
              const SizedBox(height: 16),
              Text('Unable to check subscription status'),
              const SizedBox(height: 16),
              CupertinoButton(
                onPressed: () {
                  ref.read(subscriptionProvider.notifier).checkSubscriptionStatus();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Feature Flag Implementation

### Feature Flag Utilities

**File**: `lib/src/utils/feature_flags.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_provider.dart';

class FeatureFlags {
  /// Check if user has access to a specific feature
  static Future<bool> hasFeature(String feature, WidgetRef ref) async {
    final subscription = await ref.read(subscriptionProvider.future);
    
    switch (feature) {
      case 'labs':
      case 'advanced_analytics':
      case 'premium_recipes':
      case 'experimental_features':
        return subscription.hasPlus;
      default:
        return true; // Free features
    }
  }
  
  /// Synchronous version for widgets that already have subscription state
  static bool hasFeatureSync(String feature, SubscriptionState subscription) {
    switch (feature) {
      case 'labs':
      case 'advanced_analytics':
      case 'premium_recipes':
      case 'experimental_features':
        return subscription.hasPlus;
      default:
        return true; // Free features
    }
  }
}

/// Feature gate widget for easy premium feature protection
class FeatureGate extends ConsumerWidget {
  final String feature;
  final Widget child;
  final Widget? fallback;
  
  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.fallback,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    
    return subscription.when(
      data: (state) {
        final hasAccess = FeatureFlags.hasFeatureSync(feature, state);
        if (hasAccess) {
          return child;
        }
        
        return fallback ?? CupertinoButton(
          onPressed: () async {
            await ref.read(subscriptionServiceProvider).presentPaywall();
          },
          child: const Text('Upgrade to Stockpot Plus'),
        );
      },
      loading: () => const CupertinoActivityIndicator(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}
```

### Menu Integration Updates

**File Updates**: `lib/src/widgets/menu/menu.dart`

```dart
// Add subscription status indicator to Labs menu item
MenuItem(
  index: 5,
  title: '🧪Labs',
  icon: CupertinoIcons.settings,
  isActive: selectedIndex == 5,
  color: primaryColor,
  textColor: textColor,
  activeTextColor: activeTextColor,
  backgroundColor: backgroundColor,
  trailing: Consumer(
    builder: (context, ref, child) {
      final hasAccess = ref.watch(hasPlusProvider);
      return hasAccess 
          ? const Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: CupertinoColors.systemGreen,
              size: 16,
            )
          : const Icon(
              CupertinoIcons.lock_fill,
              color: CupertinoColors.systemOrange,
              size: 16,
            );
    },
  ),
  onTap: (_) {
    onRouteGo('/labs');
  },
),
```

## Testing Strategy

### Unit Tests

**File**: `test/unit/subscription_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:recipe_app/src/services/subscription_service.dart';

@GenerateMocks([Purchases, CustomerInfo])
import 'subscription_service_test.mocks.dart';

void main() {
  group('SubscriptionService', () {
    late SubscriptionService subscriptionService;
    late MockPurchases mockPurchases;
    late MockCustomerInfo mockCustomerInfo;
    
    setUp(() {
      subscriptionService = SubscriptionService();
      mockPurchases = MockPurchases();
      mockCustomerInfo = MockCustomerInfo();
    });
    
    test('hasPlus returns true when entitlement is active', () async {
      // Arrange
      final entitlements = <String, EntitlementInfo>{
        'plus': EntitlementInfo(
          identifier: 'plus',
          isActive: true,
          willRenew: true,
          latestPurchaseDate: DateTime.now(),
          originalPurchaseDate: DateTime.now(),
          productIdentifier: 'stockpot_plus_monthly',
          isSandbox: true,
        ),
      };
      
      when(mockCustomerInfo.entitlements).thenReturn(
        EntitlementInfos(all: entitlements, active: entitlements)
      );
      when(mockPurchases.getCustomerInfo()).thenAnswer((_) async => mockCustomerInfo);
      
      // Act
      final hasAccess = await subscriptionService.hasPlus();
      
      // Assert
      expect(hasAccess, true);
    });
    
    test('hasPlus returns false when entitlement is inactive', () async {
      // Arrange
      when(mockCustomerInfo.entitlements).thenReturn(
        EntitlementInfos(all: {}, active: {})
      );
      when(mockPurchases.getCustomerInfo()).thenAnswer((_) async => mockCustomerInfo);
      
      // Act
      final hasAccess = await subscriptionService.hasPlus();
      
      // Assert
      expect(hasAccess, false);
    });
    
    test('hasPlus returns false on error', () async {
      // Arrange
      when(mockPurchases.getCustomerInfo()).thenThrow(Exception('Network error'));
      
      // Act
      final hasAccess = await subscriptionService.hasPlus();
      
      // Assert
      expect(hasAccess, false);
    });
  });
}
```

### Feature Flag Tests

**File**: `test/unit/feature_flags_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/src/utils/feature_flags.dart';
import 'package:recipe_app/src/models/subscription_state.dart';

void main() {
  group('FeatureFlags', () {
    test('hasFeatureSync returns true for plus features when user has plus', () {
      const subscription = SubscriptionState(hasPlus: true);
      
      expect(FeatureFlags.hasFeatureSync('labs', subscription), true);
      expect(FeatureFlags.hasFeatureSync('advanced_analytics', subscription), true);
      expect(FeatureFlags.hasFeatureSync('premium_recipes', subscription), true);
    });
    
    test('hasFeatureSync returns false for plus features when user lacks plus', () {
      const subscription = SubscriptionState(hasPlus: false);
      
      expect(FeatureFlags.hasFeatureSync('labs', subscription), false);
      expect(FeatureFlags.hasFeatureSync('advanced_analytics', subscription), false);
      expect(FeatureFlags.hasFeatureSync('premium_recipes', subscription), false);
    });
    
    test('hasFeatureSync returns true for free features regardless of subscription', () {
      const subscription = SubscriptionState(hasPlus: false);
      
      expect(FeatureFlags.hasFeatureSync('recipes', subscription), true);
      expect(FeatureFlags.hasFeatureSync('pantry', subscription), true);
      expect(FeatureFlags.hasFeatureSync('unknown_feature', subscription), true);
    });
  });
}
```

## Configuration Requirements

### RevenueCat Configuration
- **API Key**: `appl_SPuDBCvjoalGuumyxdYEfRZKEXt`
- **Entitlement ID**: `plus`
- **Subscription**: Stockpot Plus (monthly)

### Key Implementation Notes
- Using RevenueCat built-in paywalls exclusively
- Family Sharing handled automatically by RevenueCat
- No custom paywall UI components needed
- Feature flags based on `plus` entitlement checking

## Key Benefits

### Simplified Implementation
- **No Custom UI**: RevenueCat handles all paywall presentation
- **Proven Conversion**: Built-in A/B testing and optimization
- **Family Sharing**: Automatic support without additional code
- **Feature Flags**: Simple entitlement-based gating system

### Technical Advantages
- **Reduced Complexity**: ~50% less code than custom paywall approach
- **Faster Development**: Focus on core integration rather than UI
- **Better UX**: RevenueCat's proven paywall experience
- **Easier Maintenance**: Paywall updates via dashboard, not app releases

This simplified technical plan leverages RevenueCat's built-in capabilities for rapid implementation while maintaining high quality standards.