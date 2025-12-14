import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../services/logging/app_logger.dart';
import '../../../theme/colors.dart';

/// A full-screen page that displays RevenueCat's PaywallView widget.
///
/// This gives us full control over the paywall presentation and dismissal,
/// avoiding issues with RevenueCatUI.presentPaywall() not properly closing.
///
/// The page returns `true` if a purchase or restore was successful, `false` otherwise.
class PaywallPage extends ConsumerStatefulWidget {
  /// Optional offering to display. If null, uses the default offering.
  final Offering? offering;

  const PaywallPage({super.key, this.offering});

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  // Flags to track success - set in callbacks, checked in onDismiss
  bool _purchaseSucceeded = false;
  bool _restoreSucceeded = false;

  void _handlePurchaseStarted(Package package) {
    AppLogger.info('Paywall: Purchase started for ${package.identifier}');
  }

  void _handlePurchaseCompleted(
      CustomerInfo customerInfo, StoreTransaction transaction) {
    AppLogger.info(
        'Paywall: Purchase completed - ${transaction.productIdentifier}');
    // Set flag but DO NOT navigate here - onDismiss will handle it
    _purchaseSucceeded = true;
  }

  void _handlePurchaseError(PurchasesError error) {
    AppLogger.error('Paywall: Purchase error - ${error.code}: ${error.message}');
    // Don't dismiss - let user retry or manually close
  }

  void _handlePurchaseCancelled() {
    AppLogger.info('Paywall: Purchase cancelled by user');
    // Don't dismiss - user cancelled but may want to try again
  }

  void _handleRestoreCompleted(CustomerInfo customerInfo) {
    final hasPlus = customerInfo.entitlements.active.containsKey('plus');
    AppLogger.info('Paywall: Restore completed - hasPlus: $hasPlus');
    _restoreSucceeded = hasPlus;

    // Unlike purchases, restore doesn't auto-trigger onDismiss
    // So we manually dismiss after successful restore
    if (hasPlus && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handleDismiss();
        }
      });
    }
  }

  void _handleRestoreError(PurchasesError error) {
    AppLogger.error('Paywall: Restore error - ${error.code}: ${error.message}');
    // Don't dismiss - let user retry or manually close
  }

  void _handleDismiss() {
    final success = _purchaseSucceeded || _restoreSucceeded;
    AppLogger.info('Paywall: Dismissing with success=$success');

    // This is the ONLY place we handle navigation
    if (mounted) {
      Navigator.of(context).pop(success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: PaywallView(
        offering: widget.offering,
        displayCloseButton: true,
        onPurchaseStarted: _handlePurchaseStarted,
        onPurchaseCompleted: _handlePurchaseCompleted,
        onPurchaseError: _handlePurchaseError,
        onPurchaseCancelled: _handlePurchaseCancelled,
        onRestoreCompleted: _handleRestoreCompleted,
        onRestoreError: _handleRestoreError,
        onDismiss: _handleDismiss,
      ),
    );
  }
}
