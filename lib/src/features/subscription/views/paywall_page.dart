import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../providers/subscription_provider.dart';
import '../../../services/logging/app_logger.dart';
import '../../../theme/colors.dart';
import '../../../widgets/app_circle_button.dart';

/// A full-screen page that displays RevenueCat's PaywallView widget.
///
/// This page is shown immediately with a spinner while it:
/// 1. Creates anonymous user if needed
/// 2. Initializes RevenueCat
/// 3. Logs in the user to RevenueCat
/// 4. Fetches/uses cached offering
///
/// This gives instant feedback to the user while the slow setup happens.
///
/// The page returns `true` if a purchase or restore was successful, `false` otherwise.
class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({super.key});

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

  // Timing for diagnostics
  final Stopwatch _pageStopwatch = Stopwatch();
  bool _didLogPaywallReady = false;

  @override
  void initState() {
    super.initState();
    _pageStopwatch.start();
    AppLogger.info('[Paywall Timing] PaywallPage initState called');
    _setupAndLoadOffering();
    _waitForTransition();
  }

  /// Wait for the page transition animation to complete before showing PaywallView.
  /// This prevents the stutter caused by PaywallView's internal initialization
  /// interfering with the slide-up animation.
  void _waitForTransition() {
    // MaterialPageRoute uses ~300ms for transitions
    // NOTE: Currently set to 0ms - transition wait is disabled
    Future.delayed(const Duration(milliseconds: 0), () {
      if (mounted) {
        setState(() {
          _transitionComplete = true;
        });
        AppLogger.info('[Paywall Timing] Transition marked complete at ${_pageStopwatch.elapsedMilliseconds}ms since initState');
      }
    });
  }

  /// Sets up everything needed for purchase and loads the offering.
  /// This includes: anonymous user creation, RevenueCat init, RC login, offering fetch.
  Future<void> _setupAndLoadOffering() async {
    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final offering = await subscriptionService.ensureReadyForPurchase();

      if (mounted) {
        setState(() {
          _offering = offering;
          _isLoading = false;
          if (_offering == null) {
            _loadError = 'No offerings available';
          }
        });
        AppLogger.info('[Paywall Timing] Setup complete, _isLoading=false at ${_pageStopwatch.elapsedMilliseconds}ms since initState');
      }
    } catch (e) {
      AppLogger.error('Failed to setup paywall', e);
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

    // Log when we're ready to show PaywallView (only once)
    if (!_didLogPaywallReady) {
      _didLogPaywallReady = true;
      AppLogger.info('[Paywall Timing] Ready to show PaywallView at ${_pageStopwatch.elapsedMilliseconds}ms since initState');
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
    // Wrap in Stack to overlay our own close button (RC's doesn't respect safe areas)
    return Stack(
      children: [
        PaywallView(
          offering: _offering,
          displayCloseButton: false, // We provide our own
          onPurchaseStarted: _handlePurchaseStarted,
          onPurchaseCompleted: _handlePurchaseCompleted,
          onPurchaseError: _handlePurchaseError,
          onPurchaseCancelled: _handlePurchaseCancelled,
          onRestoreCompleted: _handleRestoreCompleted,
          onRestoreError: _handleRestoreError,
          onDismiss: _handleDismiss,
        ),
        // Custom close button with proper safe area positioning
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          right: 16,
          child: AppCircleButton(
            icon: AppCircleButtonIcon.close,
            variant: AppCircleButtonVariant.overlay,
            size: 40,
            onPressed: _handleDismiss,
          ),
        ),
      ],
    );
  }
}
