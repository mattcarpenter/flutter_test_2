import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../mobile/adaptive_app.dart' show globalRootNavigatorKey;
import '../providers/auth_provider.dart';
import 'error_dialog.dart';

/// A widget that listens for the identityAlreadyExistsError flag and shows
/// a dialog explaining that the OAuth identity is already linked to another account.
///
/// This is used when an anonymous user tries to link a Google/Apple identity
/// that's already linked to another Stockpot account.
class IdentityExistsErrorListener extends ConsumerStatefulWidget {
  final Widget child;

  const IdentityExistsErrorListener({super.key, required this.child});

  @override
  ConsumerState<IdentityExistsErrorListener> createState() =>
      _IdentityExistsErrorListenerState();
}

class _IdentityExistsErrorListenerState
    extends ConsumerState<IdentityExistsErrorListener> {
  bool _hasShownDialog = false;

  @override
  Widget build(BuildContext context) {
    // Listen to the identityAlreadyExistsError flag
    ref.listen<bool>(
      authNotifierProvider.select((state) => state.identityAlreadyExistsError),
      (previous, hasError) {
        if (hasError && !_hasShownDialog) {
          _hasShownDialog = true;
          // Show dialog after a short delay to let navigation stabilize
          // The deep link triggers navigation changes, so we need to wait
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showIdentityExistsDialog();
            }
          });
        }
      },
    );

    return widget.child;
  }

  Future<void> _showIdentityExistsDialog() async {
    // Use the global navigator context, not the builder context
    // The builder context is ABOVE the Navigator in the widget tree
    final navigatorContext = globalRootNavigatorKey.currentContext;
    if (navigatorContext == null) {
      // Navigator not ready yet - reset flag and try again later
      _hasShownDialog = false;
      return;
    }
    final authState = ref.read(authNotifierProvider);
    final pendingProvider = authState.pendingLinkIdentityProvider;

    // Clear the error flag
    ref.read(authNotifierProvider.notifier).clearIdentityAlreadyExistsError();

    if (pendingProvider == null) {
      // No pending provider - shouldn't happen but handle gracefully
      _hasShownDialog = false;
      return;
    }

    // Clear the pending provider
    ref.read(authNotifierProvider.notifier).clearPendingLinkIdentityProvider();

    final providerName =
        pendingProvider == OAuthProvider.google ? 'Google' : 'Apple';

    final shouldContinue = await showCupertinoDialog<bool>(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Account Already Exists'),
        content: Text(
          'This $providerName account is already linked to a Stockpot account.\n\n'
          'If you continue, your current local recipes will be replaced with that account\'s data.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Sign In Anyway'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    // Reset so dialog can show again in future sessions if needed
    _hasShownDialog = false;

    if (shouldContinue != true) return;

    // Sign in with native OAuth (bypasses linkIdentity)
    try {
      if (pendingProvider == OAuthProvider.google) {
        await ref
            .read(authNotifierProvider.notifier)
            .signInWithGoogle(forceNativeOAuth: true);
      } else {
        await ref
            .read(authNotifierProvider.notifier)
            .signInWithApple(forceNativeOAuth: true);
      }
      if (mounted) {
        navigatorContext.go('/recipes');
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          navigatorContext,
          message: 'Failed to sign in. Please try again.',
        );
      }
    }
  }
}
