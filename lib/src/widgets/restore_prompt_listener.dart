import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';

/// A widget that listens for the shouldPromptRestore flag and shows
/// a dialog prompting the user to restore their purchases after signing in.
///
/// This is used when an anonymous user with a Plus subscription signs into
/// an existing account - their subscription is tied to the anonymous account
/// so they need to restore purchases to transfer it to the new account.
class RestorePromptListener extends ConsumerStatefulWidget {
  final Widget child;

  const RestorePromptListener({super.key, required this.child});

  @override
  ConsumerState<RestorePromptListener> createState() => _RestorePromptListenerState();
}

class _RestorePromptListenerState extends ConsumerState<RestorePromptListener> {
  bool _hasShownDialog = false;

  @override
  Widget build(BuildContext context) {
    // Listen to the shouldPromptRestore flag
    ref.listen<bool>(shouldPromptRestoreProvider, (previous, shouldPrompt) {
      if (shouldPrompt && !_hasShownDialog) {
        _hasShownDialog = true;
        // Show dialog after frame completes to avoid build issues
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showRestorePromptDialog(context);
          }
        });
      }
    });

    return widget.child;
  }

  Future<void> _showRestorePromptDialog(BuildContext context) async {
    final shouldRestore = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Restore Your Subscription'),
        content: const Text(
          'You previously had a Stockpot Plus subscription. '
          'Would you like to restore your purchase to this account?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Later'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Restore'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    // Clear the flag regardless of choice
    if (mounted) {
      ref.read(authNotifierProvider.notifier).clearRestorePrompt();
    }

    // If user chose to restore, trigger the restore flow
    if (shouldRestore == true && mounted) {
      try {
        await ref.read(subscriptionProvider.notifier).restorePurchases();
        if (mounted) {
          _showRestoreSuccessDialog(context);
        }
      } catch (e) {
        if (mounted) {
          _showRestoreErrorDialog(context, e.toString());
        }
      }
    }

    // Reset so dialog can show again in future sessions if needed
    _hasShownDialog = false;
  }

  void _showRestoreSuccessDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Purchase Restored'),
        content: const Text(
          'Your Stockpot Plus subscription has been restored successfully.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showRestoreErrorDialog(BuildContext context, String error) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Restore Failed'),
        content: Text(
          'Unable to restore your purchase. Please try again from Settings > Subscription.\n\nError: $error',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
