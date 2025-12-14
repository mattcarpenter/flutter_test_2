import 'package:flutter/cupertino.dart';
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
  /// Optional offering to display. If null, fetches the current offering.
  final Offering? offering;

  const PaywallPage({super.key, this.offering});

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  // Flags to track success - set in callbacks, checked in onDismiss
  bool _purchaseSucceeded = false;
  bool _restoreSucceeded = false;

  // Loading state - we fetch the offering first to avoid visual glitch
  Offering? _offering;
  bool _isLoading = true;
  bool _transitionComplete = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _fetchOffering();
    _waitForTransition();
  }

  /// Wait for the page transition animation to complete before showing PaywallView.
  /// This prevents the stutter caused by PaywallView's internal initialization
  /// interfering with the slide-up animation.
  void _waitForTransition() {
    // MaterialPageRoute uses ~300ms for transitions
    Future.delayed(const Duration(milliseconds: 0), () {
      if (mounted) {
        setState(() {
          _transitionComplete = true;
        });
      }
    });
  }

  Future<void> _fetchOffering() async {
    // If offering was provided, use it immediately
    if (widget.offering != null) {
      setState(() {
        _offering = widget.offering;
        _isLoading = false;
      });
      return;
    }

    // Otherwise fetch the current offering
    try {
      final offerings = await Purchases.getOfferings();
      if (mounted) {
        setState(() {
          _offering = offerings.current;
          _isLoading = false;
          if (_offering == null) {
            _loadError = 'No offerings available';
          }
        });
      }
    } catch (e) {
      AppLogger.error('Failed to fetch offerings', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = 'Failed to load subscription options';
        });
      }
    }
  }

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
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: _buildBody(context, colors),
    );
  }

  Widget _buildBody(BuildContext context, AppColors colors) {
    // Show loading state while fetching offering OR waiting for transition
    if (_isLoading || !_transitionComplete) {
      return Center(
        child: CupertinoActivityIndicator(
          radius: 14,
          color: colors.textSecondary,
        ),
      );
    }

    // Show error state if fetching failed
    if (_loadError != null || _offering == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_circle,
                size: 48,
                color: colors.error,
              ),
              const SizedBox(height: 16),
              Text(
                _loadError ?? 'Unable to load subscription options',
                style: TextStyle(color: colors.textPrimary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CupertinoButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Close', style: TextStyle(color: colors.primary)),
              ),
            ],
          ),
        ),
      );
    }

    // Show PaywallView once offering is loaded
    return PaywallView(
      offering: _offering,
      displayCloseButton: true,
      onPurchaseStarted: _handlePurchaseStarted,
      onPurchaseCompleted: _handlePurchaseCompleted,
      onPurchaseError: _handlePurchaseError,
      onPurchaseCancelled: _handlePurchaseCancelled,
      onRestoreCompleted: _handleRestoreCompleted,
      onRestoreError: _handleRestoreError,
      onDismiss: _handleDismiss,
    );
  }
}
