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
  static const String _apiKey = String.fromEnvironment('REVENUECAT_API_KEY');
  static const String _labsEntitlementId = 'labs_premium';
  
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
  
  /// Check if user has Labs premium access
  Future<bool> hasLabsAccess() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(_labsEntitlementId);
    } catch (e) {
      debugPrint('Error checking Labs access: $e');
      // Graceful degradation - deny access on error
      return false;
    }
  }
  
  /// Stream of subscription status changes
  Stream<bool> get labsAccessStream {
    return Purchases.getCustomerInfoStream().map((customerInfo) {
      return customerInfo.entitlements.active.containsKey(_labsEntitlementId);
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
      final result = await RevenueCatUI.presentPaywallIfNeeded(_labsEntitlementId);
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
    @Default(false) bool hasLabsAccess,
    @Default(false) bool isLoading,
    @Default(false) bool isRestoring,
    String? error,
    DateTime? lastChecked,
    Map<String, bool>? entitlements,
  }) = _SubscriptionState;
  
  const SubscriptionState._();
  
  bool get isActive => hasLabsAccess;
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
      _subscriptionService.labsAccessStream.listen((hasAccess) {
        final currentState = state.valueOrNull ?? const SubscriptionState();
        state = AsyncValue.data(currentState.copyWith(
          hasLabsAccess: hasAccess,
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
      
      final hasAccess = await _subscriptionService.hasLabsAccess();
      
      state = AsyncValue.data(SubscriptionState(
        hasLabsAccess: hasAccess,
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
final hasLabsAccessProvider = Provider<bool>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  return subscription.valueOrNull?.hasLabsAccess ?? false;
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
    if (!subscription.hasLabsAccess) {
      return '/paywall?source=labs_gate&redirect=${Uri.encodeComponent(state.matchedLocation)}';
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
        if (!subscription.hasLabsAccess) {
          return '/paywall?source=labs_feature&redirect=${Uri.encodeComponent(state.matchedLocation)}';
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

// Add new paywall route
GoRoute(
  path: '/paywall',
  pageBuilder: (context, state) {
    final source = state.uri.queryParameters['source'] ?? 'unknown';
    final redirectPath = state.uri.queryParameters['redirect'];
    
    return _platformPage(
      state: state,
      child: PaywallPage(
        source: source,
        redirectAfterPurchase: redirectPath,
      ),
    );
  },
),
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

## Paywall UI Implementation

### Custom Paywall Page

**File**: `lib/src/features/subscription/views/paywall_page.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/subscription_provider.dart';

class PaywallPage extends ConsumerStatefulWidget {
  final String source;
  final String? redirectAfterPurchase;
  
  const PaywallPage({
    super.key,
    required this.source,
    this.redirectAfterPurchase,
  });
  
  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  bool _isProcessing = false;
  
  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionProvider);
    
    // Listen for subscription state changes
    ref.listen(subscriptionProvider, (previous, next) {
      next.whenData((state) {
        if (state.hasLabsAccess && !_isProcessing) {
          _handlePurchaseSuccess();
        }
      });
    });
    
    return WillPopScope(
      onWillPop: () async {
        // For post-auth paywalls, prevent going back
        if (widget.source == 'post_auth') {
          context.go('/recipes');
          return false;
        }
        return true;
      },
      child: AdaptiveSliverPage(
        title: 'Premium Features',
        automaticallyImplyLeading: widget.source != 'post_auth',
        body: subscription.when(
          data: (state) => _buildPaywallContent(state),
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stack) => _buildErrorContent(error),
        ),
      ),
    );
  }
  
  Widget _buildPaywallContent(SubscriptionState state) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.lab_flask_solid,
            size: 80,
            color: CupertinoColors.systemPurple,
          ),
          const SizedBox(height: 24),
          Text(
            'Unlock Labs Features',
            style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Get access to experimental features and help shape the future of the app.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildFeatureList(),
          const SizedBox(height: 32),
          _buildPurchaseButton(state),
          const SizedBox(height: 16),
          _buildRestoreButton(state),
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: const TextStyle(color: CupertinoColors.systemRed),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildFeatureList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          _FeatureRow(
            icon: CupertinoIcons.lab_flask,
            title: 'Experimental Features',
            description: 'Early access to new functionality',
          ),
          SizedBox(height: 12),
          _FeatureRow(
            icon: CupertinoIcons.gear,
            title: 'Advanced Settings',
            description: 'Fine-tune your app experience',
          ),
          SizedBox(height: 12),
          _FeatureRow(
            icon: CupertinoIcons.chart_bar,
            title: 'Analytics Dashboard',
            description: 'Detailed insights into your usage',
          ),
        ],
      ),
    );
  }
  
  Widget _buildPurchaseButton(SubscriptionState state) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton.filled(
        onPressed: (_isProcessing || state.isLoading) 
            ? null 
            : _handlePurchasePressed,
        child: _isProcessing || state.isLoading
            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
            : const Text('Start Premium Subscription'),
      ),
    );
  }
  
  Widget _buildRestoreButton(SubscriptionState state) {
    return CupertinoButton(
      onPressed: (state.isRestoring) ? null : _handleRestorePressed,
      child: state.isRestoring
          ? const CupertinoActivityIndicator()
          : const Text('Restore Purchases'),
    );
  }
  
  Widget _buildErrorContent(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 16),
            const Text('Unable to load subscription information'),
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
    );
  }
  
  Future<void> _handlePurchasePressed() async {
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Use RevenueCat's built-in paywall
      final success = await ref
          .read(subscriptionProvider.notifier)
          .presentPaywall(source: widget.source);
      
      if (success) {
        _handlePurchaseSuccess();
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _handleRestorePressed() async {
    await ref.read(subscriptionProvider.notifier).restorePurchases();
  }
  
  void _handlePurchaseSuccess() {
    if (widget.redirectAfterPurchase != null) {
      context.go(Uri.decodeComponent(widget.redirectAfterPurchase!));
    } else {
      context.go('/recipes');
    }
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: CupertinoColors.systemPurple,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                description,
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
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
      final hasAccess = ref.watch(hasLabsAccessProvider);
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
    
    test('hasLabsAccess returns true when entitlement is active', () async {
      // Arrange
      final entitlements = <String, EntitlementInfo>{
        'labs_premium': EntitlementInfo(
          identifier: 'labs_premium',
          isActive: true,
          willRenew: true,
          latestPurchaseDate: DateTime.now(),
          originalPurchaseDate: DateTime.now(),
          productIdentifier: 'labs_premium_monthly',
          isSandbox: true,
        ),
      };
      
      when(mockCustomerInfo.entitlements).thenReturn(
        EntitlementInfos(all: entitlements, active: entitlements)
      );
      when(mockPurchases.getCustomerInfo()).thenAnswer((_) async => mockCustomerInfo);
      
      // Act
      final hasAccess = await subscriptionService.hasLabsAccess();
      
      // Assert
      expect(hasAccess, true);
    });
    
    test('hasLabsAccess returns false when entitlement is inactive', () async {
      // Arrange
      when(mockCustomerInfo.entitlements).thenReturn(
        EntitlementInfos(all: {}, active: {})
      );
      when(mockPurchases.getCustomerInfo()).thenAnswer((_) async => mockCustomerInfo);
      
      // Act
      final hasAccess = await subscriptionService.hasLabsAccess();
      
      // Assert
      expect(hasAccess, false);
    });
    
    test('hasLabsAccess returns false on error', () async {
      // Arrange
      when(mockPurchases.getCustomerInfo()).thenThrow(Exception('Network error'));
      
      // Act
      final hasAccess = await subscriptionService.hasLabsAccess();
      
      // Assert
      expect(hasAccess, false);
    });
  });
}
```

### Widget Tests

**File**: `test/widget/subscription_gate_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/src/widgets/subscription_gate.dart';
import 'package:recipe_app/src/providers/subscription_provider.dart';
import 'package:recipe_app/src/models/subscription_state.dart';

void main() {
  group('SubscriptionGate', () {
    testWidgets('shows child when user has access', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionProvider.overrideWith((ref) => 
              StateNotifier((ref) => const AsyncValue.data(
                SubscriptionState(hasLabsAccess: true)
              ))
            ),
          ],
          child: const CupertinoApp(
            home: SubscriptionGate(
              feature: 'labs',
              child: Text('Protected Content'),
            ),
          ),
        ),
      );
      
      expect(find.text('Protected Content'), findsOneWidget);
      expect(find.text('Upgrade to Premium'), findsNothing);
    });
    
    testWidgets('shows upgrade prompt when user lacks access', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionProvider.overrideWith((ref) => 
              StateNotifier((ref) => const AsyncValue.data(
                SubscriptionState(hasLabsAccess: false)
              ))
            ),
          ],
          child: const CupertinoApp(
            home: SubscriptionGate(
              feature: 'labs',
              child: Text('Protected Content'),
            ),
          ),
        ),
      );
      
      expect(find.text('Protected Content'), findsNothing);
      expect(find.text('Upgrade to Premium'), findsOneWidget);
      expect(find.text('Restore Purchases'), findsOneWidget);
    });
  });
}
```

### Integration Tests

**File**: `test/integration/subscription_flow_test.dart`

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:recipe_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Subscription Flow Integration Tests', () {
    testWidgets('Complete subscription purchase flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to Labs (should trigger paywall)
      await tester.tap(find.text('🧪Labs'));
      await tester.pumpAndSettle();
      
      // Should see paywall
      expect(find.text('Premium Features'), findsOneWidget);
      expect(find.text('Start Premium Subscription'), findsOneWidget);
      
      // Tap purchase button (will open RevenueCat paywall)
      await tester.tap(find.text('Start Premium Subscription'));
      await tester.pumpAndSettle();
      
      // Note: Actual purchase testing requires sandbox environment
      // and cannot be fully automated in CI/CD
    });
    
    testWidgets('Labs access after successful purchase', (tester) async {
      // This test would require mocking purchase success
      // or running in sandbox with pre-purchased test account
    });
  });
}
```

## Configuration Requirements

### RevenueCat Dashboard Setup

1. **Project Creation**
   - Create new project in RevenueCat dashboard
   - Configure iOS and Android app bundles
   - Upload App Store Connect P8 key

2. **Product Configuration**
   - Create "Labs Premium" entitlement
   - Configure monthly/yearly subscription products
   - Set up offerings and packages

3. **Paywall Design**
   - Use visual paywall editor for branded experience
   - Configure multiple paywall variations for A/B testing
   - Set up localization for multiple markets

### App Store Connect Configuration

1. **In-App Purchases**
   - Create subscription groups
   - Configure subscription products (monthly/yearly)
   - Set pricing and availability

2. **App Information**
   - Update app description with subscription features
   - Configure subscription terms and privacy policy
   - Set up promotional offers if desired

### Environment Variables

**File**: `.env` (for development)
```
REVENUECAT_API_KEY=your_development_api_key_here
```

**File**: `.env.production` (for production)
```
REVENUECAT_API_KEY=your_production_api_key_here
```

## Implementation Timeline

### Week 1: Foundation Setup
- **Day 1-2**: Dependencies, basic service implementation
- **Day 3-4**: Provider setup and auth integration
- **Day 5**: Initial testing and debugging

### Week 2: Labs Feature Protection
- **Day 1-2**: Route guard implementation
- **Day 3-4**: Paywall UI and purchase flow
- **Day 5**: Menu integration and status indicators

### Week 3: Polish and Testing
- **Day 1-2**: Custom paywall page and enhanced UX
- **Day 3-4**: Comprehensive testing (unit, widget, integration)
- **Day 5**: Bug fixes and performance optimization

### Week 4: Production Readiness
- **Day 1-2**: RevenueCat dashboard configuration
- **Day 3-4**: App Store Connect setup and submission preparation
- **Day 5**: Documentation and handoff

## Risk Mitigation

1. **Testing Strategy**: Extensive testing in sandbox before production
2. **Graceful Degradation**: Always fail closed on subscription checks
3. **Error Handling**: Comprehensive error handling with user-friendly messages
4. **Performance**: Optimize subscription checks to avoid UI blocking
5. **Privacy**: Ensure compliance with App Store guidelines and privacy policies

This technical plan provides a comprehensive roadmap for implementing RevenueCat paywall functionality while maintaining the high quality and user experience standards of the existing Flutter recipe app.