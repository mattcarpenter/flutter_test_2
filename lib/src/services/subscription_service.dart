import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      debugPrint('SubscriptionService: Initializing RevenueCat with API key: $_apiKey');
      
      // Configure RevenueCat
      final configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);
      
      // Set user ID if authenticated
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        debugPrint('SubscriptionService: Setting user ID: ${currentUser.id}');
        await Purchases.logIn(currentUser.id);
      }
      
      _isInitialized = true;
      _initCompleter!.complete();
      debugPrint('SubscriptionService: Initialization complete');
    } catch (e) {
      debugPrint('SubscriptionService: Initialization failed: $e');
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

  /// Check if user has Plus subscription
  Future<bool> hasPlus() async {
    try {
      await _ensureInitialized();
      
      debugPrint('SubscriptionService: Checking Plus entitlement');
      final customerInfo = await Purchases.getCustomerInfo();
      
      final hasEntitlement = customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
      debugPrint('SubscriptionService: Plus entitlement active: $hasEntitlement');
      
      return hasEntitlement;
    } on PlatformException catch (e) {
      debugPrint('SubscriptionService: Error checking Plus entitlement: $e');
      
      // Fail closed - deny access on error
      if (e.code == 'purchases_not_configured') {
        throw SubscriptionApiException(
          message: 'Subscription service not properly configured',
          code: e.code,
          type: SubscriptionErrorType.configuration,
        );
      }
      
      // For other errors, fail safely by denying access
      return false;
    } catch (e) {
      debugPrint('SubscriptionService: Unexpected error checking entitlement: $e');
      // Fail closed - deny access on unexpected errors
      return false;
    }
  }

  /// Present paywall using RevenueCat's built-in UI
  Future<bool> presentPaywall() async {
    try {
      await _ensureInitialized();
      
      debugPrint('SubscriptionService: Presenting paywall');
      final result = await RevenueCatUI.presentPaywall();
      
      debugPrint('SubscriptionService: Paywall result: ${result.name}');
      return result == PaywallResult.purchased;
    } on PlatformException catch (e) {
      debugPrint('SubscriptionService: Error presenting paywall: $e');
      
      // Create a mock PurchasesError for consistent error handling
      final purchasesError = PurchasesError(
        PurchasesErrorCode.unknownError,
        e.message ?? 'Unknown error',
        '',
        e.details?.toString() ?? '',
      );
      
      throw SubscriptionApiException.fromPurchasesError(purchasesError);
    } catch (e) {
      debugPrint('SubscriptionService: Unexpected error presenting paywall: $e');
      throw SubscriptionApiException.fromException(Exception(e.toString()));
    }
  }

  /// Present paywall only if user doesn't have Plus subscription
  Future<bool> presentPaywallIfNeeded() async {
    try {
      await _ensureInitialized();
      
      debugPrint('SubscriptionService: Checking if paywall needed');
      final hasActivePlus = await hasPlus();
      
      if (hasActivePlus) {
        debugPrint('SubscriptionService: User already has Plus, skipping paywall');
        return true;
      }
      
      debugPrint('SubscriptionService: User needs Plus, presenting paywall');
      return await presentPaywall();
    } catch (e) {
      debugPrint('SubscriptionService: Error in presentPaywallIfNeeded: $e');
      rethrow;
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    try {
      await _ensureInitialized();
      
      debugPrint('SubscriptionService: Restoring purchases');
      final customerInfo = await Purchases.restorePurchases();
      
      final hasActiveEntitlements = customerInfo.entitlements.active.isNotEmpty;
      debugPrint('SubscriptionService: Restored purchases, active entitlements: $hasActiveEntitlements');
      
      if (!hasActiveEntitlements) {
        throw SubscriptionApiException(
          message: 'No active purchases found to restore',
          type: SubscriptionErrorType.missingReceipt,
        );
      }
    } on PlatformException catch (e) {
      debugPrint('SubscriptionService: Error restoring purchases: $e');
      
      // Create a mock PurchasesError for consistent error handling
      final purchasesError = PurchasesError(
        PurchasesErrorCode.unknownError,
        e.message ?? 'Unknown error',
        '',
        e.details?.toString() ?? '',
      );
      
      throw SubscriptionApiException.fromPurchasesError(purchasesError);
    } catch (e) {
      debugPrint('SubscriptionService: Unexpected error restoring purchases: $e');
      throw SubscriptionApiException.fromException(Exception(e.toString()));
    }
  }

  /// Synchronize user ID with current authenticated user
  Future<void> syncUserId() async {
    try {
      await _ensureInitialized();
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        debugPrint('SubscriptionService: No authenticated user, logging out from RevenueCat');
        await Purchases.logOut();
        return;
      }
      
      debugPrint('SubscriptionService: Syncing user ID: ${currentUser.id}');
      await Purchases.logIn(currentUser.id);
      debugPrint('SubscriptionService: User ID sync complete');
    } on PlatformException catch (e) {
      debugPrint('SubscriptionService: Error syncing user ID: $e');
      
      // Create a mock PurchasesError for consistent error handling
      final purchasesError = PurchasesError(
        PurchasesErrorCode.unknownError,
        e.message ?? 'Unknown error',
        '',
        e.details?.toString() ?? '',
      );
      
      throw SubscriptionApiException.fromPurchasesError(purchasesError);
    } catch (e) {
      debugPrint('SubscriptionService: Unexpected error syncing user ID: $e');
      throw SubscriptionApiException.fromException(Exception(e.toString()));
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
}