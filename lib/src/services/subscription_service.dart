import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../database/powersync.dart';
import '../../database/database.dart';
import '../../database/models/user_subscriptions.dart';
import 'logging/app_logger.dart';

/// Exception thrown when subscription operations fail
class SubscriptionApiException implements Exception {
  final String message;
  final String? code;
  final SubscriptionErrorType type;

  SubscriptionApiException({
    required this.message,
    this.code,
    required this.type,
  });

  factory SubscriptionApiException.fromPurchasesError(PurchasesError error) {
    return SubscriptionApiException(
      message: error.message,
      code: error.code.name,
      type: _mapPurchasesErrorToType(error),
    );
  }

  factory SubscriptionApiException.fromException(Exception exception) {
    return SubscriptionApiException(
      message: exception.toString(),
      type: SubscriptionErrorType.unknown,
    );
  }

  static SubscriptionErrorType _mapPurchasesErrorToType(PurchasesError error) {
    final code = error.code;
    final message = error.message.toLowerCase();
    
    // Map based on error code names since enum values may differ
    if (code.toString().contains('userCancelled') || message.contains('cancelled')) {
      return SubscriptionErrorType.userCancelled;
    } else if (code.toString().contains('storeProblem') || message.contains('store')) {
      return SubscriptionErrorType.storeProblem;
    } else if (code.toString().contains('network') || message.contains('network')) {
      return SubscriptionErrorType.networkError;
    } else if (code.toString().contains('credentials') || message.contains('credentials')) {
      return SubscriptionErrorType.invalidCredentials;
    } else if (code.toString().contains('purchaseNotAllowed') || message.contains('not allowed')) {
      return SubscriptionErrorType.purchaseNotAllowed;
    } else if (code.toString().contains('productNotAvailable') || message.contains('not available')) {
      return SubscriptionErrorType.productNotAvailable;
    } else if (code.toString().contains('receiptAlreadyInUse') || message.contains('already in use')) {
      return SubscriptionErrorType.receiptInUse;
    } else if (code.toString().contains('missingReceipt') || message.contains('missing receipt')) {
      return SubscriptionErrorType.missingReceipt;
    } else if (code.toString().contains('paymentPending') || message.contains('pending')) {
      return SubscriptionErrorType.paymentPending;
    } else if (code.toString().contains('configuration') || 
               code.toString().contains('invalidKey') ||
               code.toString().contains('ineligible') ||
               code.toString().contains('permissions') ||
               code.toString().contains('invalidAppUserId')) {
      return SubscriptionErrorType.configuration;
    }
    
    return SubscriptionErrorType.unknown;
  }

  @override
  String toString() => 'SubscriptionApiException: $message';
}

/// Types of subscription errors
enum SubscriptionErrorType {
  userCancelled,
  storeProblem,
  networkError,
  invalidCredentials,
  purchaseNotAllowed,
  productNotAvailable,
  receiptInUse,
  missingReceipt,
  paymentPending,
  configuration,
  notInitialized,
  unknown,
}

/// Service for managing subscription state and operations via RevenueCat
class SubscriptionService {
  static const String _apiKey = 'appl_SPuDBCvjoalGuumyxdYEfRZKEXt';
  static const String _entitlementId = 'plus';
  
  final SupabaseClient _supabase;
  
  bool _isInitialized = false;
  Completer<void>? _initCompleter;
  
  // Cache for ALL subscriptions (not just user's own)
  List<UserSubscriptionEntry> _cachedSubscriptions = [];
  String? _lastUserId;
  
  // RevenueCat CustomerInfo cache for immediate access
  CustomerInfo? _cachedCustomerInfo;
  String? _customerInfoUserId; // Track which user this info belongs to
  DateTime? _customerInfoLastUpdated;

  SubscriptionService() : _supabase = Supabase.instance.client;

  /// Initialize RevenueCat SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Prevent multiple initializations
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }

    _initCompleter = Completer<void>();

    try {
      // Configure RevenueCat
      final configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);

      // Set user ID if authenticated
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        await Purchases.logIn(currentUser.id);
      }

      _isInitialized = true;
      _initCompleter!.complete();
    } catch (e) {
      AppLogger.error('RevenueCat initialization failed', e);
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
  }

  /// Ensure the service is initialized before operations
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Check if user has Plus subscription - hybrid approach
  Future<bool> hasPlus({bool allowRevenueCatFallback = true}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // 1. First check PowerSync database (cached)
      if (_lastUserId == user.id && _cachedSubscriptions.isNotEmpty) {
        final dbHasPlus = _cachedSubscriptions.any((subscription) =>
            subscription.entitlements.contains(_entitlementId) &&
            subscription.status == SubscriptionStatus.active);
        if (dbHasPlus) return true;
      }

      // 2. If not in database and fallback allowed, check RevenueCat
      if (allowRevenueCatFallback && _isInitialized) {
        try {
          // Ensure RevenueCat has correct user
          final currentRevenueCatUser = await Purchases.appUserID;
          if (currentRevenueCatUser != user.id) {
            await Purchases.logIn(user.id);
          }

          // Get fresh customer info
          final customerInfo = await Purchases.getCustomerInfo();

          // Cache it with user ID
          _cachedCustomerInfo = customerInfo;
          _customerInfoUserId = user.id;
          _customerInfoLastUpdated = DateTime.now();

          return customerInfo.entitlements.active.containsKey(_entitlementId);
        } catch (e) {
          AppLogger.warning('RevenueCat fallback check failed', e);
        }
      }

      return false;
    } catch (e) {
      AppLogger.error('Error checking Plus subscription', e);
      return false; // Fail closed
    }
  }
  
  /// Check if user has Plus subscription synchronously from database only
  bool hasPlusSync() {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Check if ANY cached subscription has plus entitlement and is active
      if (_lastUserId == user.id && _cachedSubscriptions.isNotEmpty) {
        return _cachedSubscriptions.any((subscription) =>
            subscription.entitlements.contains(_entitlementId) &&
            subscription.status == SubscriptionStatus.active);
      }

      // No cached data available - refresh needed
      return false;
    } catch (e) {
      return false; // Fail closed
    }
  }
  
  /// Helper to check if subscription is active
  bool _isSubscriptionActive(UserSubscriptionEntry subscription) {
    // Simply check if the required entitlement is present
    // RevenueCat webhook removes entitlements when subscription expires
    return subscription.entitlements.contains(_entitlementId);
  }

  /// Get subscription metadata from cached PowerSync data
  Map<String, dynamic>? getSubscriptionMetadata() {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      
      // Find any active subscription with plus entitlement
      if (_lastUserId == user.id && _cachedSubscriptions.isNotEmpty) {
        final activeSubscription = _cachedSubscriptions.firstWhereOrNull((subscription) => 
          subscription.entitlements.contains(_entitlementId) && 
          subscription.status == SubscriptionStatus.active);
        
        if (activeSubscription == null) return null;
        
        return {
          'status': activeSubscription.status.name,
          'entitlements': activeSubscription.entitlements,
          'expires_at': activeSubscription.expiresAt != null ? DateTime.fromMillisecondsSinceEpoch(activeSubscription.expiresAt!).toIso8601String() : null,
          'trial_ends_at': activeSubscription.trialEndsAt != null ? DateTime.fromMillisecondsSinceEpoch(activeSubscription.trialEndsAt!).toIso8601String() : null,
          'cancelled_at': activeSubscription.cancelledAt != null ? DateTime.fromMillisecondsSinceEpoch(activeSubscription.cancelledAt!).toIso8601String() : null,
          'product_id': activeSubscription.productId,
          'store': activeSubscription.store,
          'revenuecat_customer_id': activeSubscription.revenuecatCustomerId,
          'last_updated': activeSubscription.updatedAt != null ? DateTime.fromMillisecondsSinceEpoch(activeSubscription.updatedAt!).toIso8601String() : null,
          'is_household_subscription': activeSubscription.userId != user.id,
          'subscription_owner': activeSubscription.userId,
        };
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Present paywall using RevenueCat's built-in UI
  /// Creates an anonymous Supabase user if needed (for IAP without registration)
  Future<bool> presentPaywall() async {
    try {
      // STEP 1: Ensure we have a Supabase user (anonymous or real)
      String? userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        // Create anonymous user for IAP
        AppLogger.info('No user session, creating anonymous user for IAP');
        userId = await _createAnonymousUserForPurchase();
      }

      // STEP 2: Ensure RevenueCat is initialized
      await _ensureInitialized();

      // STEP 3: Ensure RevenueCat knows about this user
      final currentRevenueCatUser = await Purchases.appUserID;
      if (currentRevenueCatUser != userId) {
        AppLogger.info('Syncing RevenueCat user ID: $userId');
        await Purchases.logIn(userId);
      }

      // STEP 4: Present paywall
      final result = await RevenueCatUI.presentPaywall();
      AppLogger.info('Paywall result: $result');

      // Treat both purchased and restored as success
      final success = result == PaywallResult.purchased || result == PaywallResult.restored;

      if (success) {
        // Immediately refresh RevenueCat state for instant access
        await refreshRevenueCatState();
      }

      return success;
    } on PlatformException catch (e) {
      AppLogger.error('Error presenting paywall', e);

      final purchasesError = PurchasesError(
        PurchasesErrorCode.unknownError,
        e.message ?? 'Unknown error',
        '',
        e.details?.toString() ?? '',
      );

      throw SubscriptionApiException.fromPurchasesError(purchasesError);
    } catch (e) {
      AppLogger.error('Error presenting paywall', e);
      throw SubscriptionApiException.fromException(Exception(e.toString()));
    }
  }

  /// Create anonymous Supabase user specifically for purchase
  Future<String> _createAnonymousUserForPurchase() async {
    try {
      final response = await _supabase.auth.signInAnonymously();

      if (response.user == null) {
        throw SubscriptionApiException(
          message: 'Failed to create anonymous user for purchase',
          type: SubscriptionErrorType.unknown,
        );
      }

      final userId = response.user!.id;
      AppLogger.info('Created anonymous user for IAP: $userId');

      return userId;
    } catch (e) {
      AppLogger.error('Failed to create anonymous user for IAP', e);
      if (e is SubscriptionApiException) rethrow;
      throw SubscriptionApiException.fromException(Exception(e.toString()));
    }
  }

  /// Present paywall only if user doesn't have Plus subscription
  Future<bool> presentPaywallIfNeeded() async {
    try {
      await _ensureInitialized();

      final hasActivePlus = await hasPlus();
      if (hasActivePlus) return true;

      return await presentPaywall();
    } catch (e) {
      rethrow;
    }
  }

  /// Restore purchases
  /// Creates an anonymous Supabase user if needed (for restore without registration)
  Future<void> restorePurchases() async {
    try {
      // Ensure we have a user (anonymous or real)
      String? userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        // Create anonymous user for restore
        AppLogger.info('Creating anonymous user for purchase restoration');
        userId = await _createAnonymousUserForPurchase();
      }

      await _ensureInitialized();

      // Ensure RevenueCat has correct user
      // This triggers RevenueCat's automatic purchase transfer from previous anonymous IDs
      final currentRevenueCatUser = await Purchases.appUserID;
      if (currentRevenueCatUser != userId) {
        await Purchases.logIn(userId);
      }

      // Restore purchases
      final customerInfo = await Purchases.restorePurchases();
      final hasActiveEntitlements = customerInfo.entitlements.active.isNotEmpty;

      if (hasActiveEntitlements) {
        AppLogger.info('Purchases restored successfully');
        await refreshRevenueCatState();
      } else {
        throw SubscriptionApiException(
          message: 'No active purchases found to restore',
          type: SubscriptionErrorType.missingReceipt,
        );
      }
    } on PlatformException catch (e) {
      AppLogger.error('Error restoring purchases', e);

      final purchasesError = PurchasesError(
        PurchasesErrorCode.unknownError,
        e.message ?? 'Unknown error',
        '',
        e.details?.toString() ?? '',
      );

      throw SubscriptionApiException.fromPurchasesError(purchasesError);
    } catch (e) {
      if (e is SubscriptionApiException) rethrow;
      AppLogger.error('Error restoring purchases', e);
      throw SubscriptionApiException.fromException(Exception(e.toString()));
    }
  }

  /// Synchronize user ID with current authenticated user
  Future<void> syncUserId() async {
    try {
      await _ensureInitialized();

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        await Purchases.logOut();
        return;
      }

      await Purchases.logIn(currentUser.id);
    } on PlatformException catch (e) {
      AppLogger.error('Error syncing RevenueCat user ID', e);

      final purchasesError = PurchasesError(
        PurchasesErrorCode.unknownError,
        e.message ?? 'Unknown error',
        '',
        e.details?.toString() ?? '',
      );

      throw SubscriptionApiException.fromPurchasesError(purchasesError);
    } catch (e) {
      AppLogger.error('Error syncing RevenueCat user ID', e);
      throw SubscriptionApiException.fromException(Exception(e.toString()));
    }
  }

  /// Force refresh subscription status from PowerSync database
  Future<void> refreshSubscriptionStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get ALL subscriptions that PowerSync synced down
      final subscriptions = await appDb.select(appDb.userSubscriptions).get();

      // Update cache
      _cachedSubscriptions = subscriptions;
      _lastUserId = user.id;
    } catch (e) {
      AppLogger.error('Error refreshing subscriptions from database', e);
      rethrow;
    }
  }

  /// Stream of customer info changes
  Stream<CustomerInfo> get customerInfoStream {
    // Note: Customer info stream requires manual polling in current RevenueCat version
    // For real-time updates, implement periodic checks or use provider-level refresh
    return Stream.periodic(const Duration(seconds: 30))
        .asyncMap((_) => Purchases.getCustomerInfo())
        .distinct((prev, next) => prev.originalPurchaseDate == next.originalPurchaseDate);
  }

  /// Get user-friendly error message
  static String getErrorMessage(Exception exception) {
    if (exception is SubscriptionApiException) {
      switch (exception.type) {
        case SubscriptionErrorType.userCancelled:
          return 'Purchase was cancelled';
        case SubscriptionErrorType.storeProblem:
          return 'There was a problem with the App Store. Please try again later.';
        case SubscriptionErrorType.networkError:
          return 'Network error. Please check your connection and try again.';
        case SubscriptionErrorType.invalidCredentials:
          return 'Invalid credentials. Please sign out and sign back in.';
        case SubscriptionErrorType.purchaseNotAllowed:
          return 'Purchases are not allowed on this device';
        case SubscriptionErrorType.productNotAvailable:
          return 'This subscription is not available. Please try again later.';
        case SubscriptionErrorType.receiptInUse:
          return 'This purchase is already associated with another account';
        case SubscriptionErrorType.missingReceipt:
          return 'No purchases found to restore';
        case SubscriptionErrorType.paymentPending:
          return 'Payment is pending. Please wait and try again.';
        case SubscriptionErrorType.configuration:
          return 'Subscription service configuration error. Please contact support.';
        case SubscriptionErrorType.notInitialized:
          return 'Subscription service not initialized. Please restart the app.';
        case SubscriptionErrorType.unknown:
          return 'An unexpected error occurred. Please try again.';
      }
    }
    
    return 'An unexpected error occurred. Please try again.';
  }

  /// Force refresh RevenueCat state for immediate access
  Future<void> refreshRevenueCatState() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _cachedCustomerInfo = null;
        _customerInfoUserId = null;
        _customerInfoLastUpdated = null;
        return;
      }

      await _ensureInitialized();

      // Ensure correct user is logged in
      final currentRevenueCatUser = await Purchases.appUserID;
      if (currentRevenueCatUser != user.id) {
        await Purchases.logIn(user.id);
      }

      // Get fresh customer info
      final customerInfo = await Purchases.getCustomerInfo();

      // Update cache
      _cachedCustomerInfo = customerInfo;
      _customerInfoUserId = user.id;
      _customerInfoLastUpdated = DateTime.now();
    } catch (e) {
      AppLogger.warning('Error refreshing RevenueCat state', e);
    }
  }

  /// Initialize subscription cache for the current user
  Future<void> _initializeSubscriptionCache() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _cachedSubscriptions = [];
        _lastUserId = null;
        return;
      }

      // Skip if already cached for this user
      if (_lastUserId == user.id && _cachedSubscriptions.isNotEmpty) {
        return;
      }

      await refreshSubscriptionStatus();
    } catch (e) {
      AppLogger.warning('Error initializing subscription cache', e);
    }
  }
}