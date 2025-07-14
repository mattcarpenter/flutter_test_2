import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/powersync.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../repositories/upload_queue_repository.dart';
import '../../utils/feature_flags.dart';
import 'menu_item.dart';

class Menu extends ConsumerWidget {
  final int selectedIndex;
  final void Function(int index) onMenuItemClick;
  final void Function(String route) onRouteGo;

  const Menu({
    super.key,
    required this.selectedIndex,
    required this.onMenuItemClick,
    required this.onRouteGo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final hasPlus = ref.watch(hasPlusProvider); // Watch for reactive updates

    // Theme Colors
    final Color backgroundColor = isDarkMode ? CupertinoTheme.of(context).barBackgroundColor : CupertinoTheme.of(context).scaffoldBackgroundColor;
    final Color primaryColor = CupertinoTheme.of(context).primaryColor;
    final Color textColor = CupertinoTheme.of(context)
        .textTheme
        .textStyle
        .color ?? Colors.black;
    final Color activeTextColor = isDarkMode ? textColor : primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MenuItem(
          index: 1,
          title: 'Recipes',
          icon: CupertinoIcons.book,
          isActive: selectedIndex == 1,
          color: primaryColor,
          textColor: textColor,
          activeTextColor: activeTextColor,
          backgroundColor: backgroundColor,
          onTap: onMenuItemClick,
        ),
        MenuItem(
          index: 2,
          title: 'Shopping List',
          icon: CupertinoIcons.shopping_cart,
          isActive: selectedIndex == 2,
          color: primaryColor,
          textColor: textColor,
          activeTextColor: activeTextColor,
          backgroundColor: backgroundColor,
          onTap: onMenuItemClick,
        ),
        MenuItem(
          index: 3,
          title: 'Meal Plans',
          icon: CupertinoIcons.calendar_today,
          isActive: selectedIndex == 3,
          color: primaryColor,
          textColor: textColor,
          activeTextColor: activeTextColor,
          backgroundColor: backgroundColor,
          onTap: onMenuItemClick,
        ),
        MenuItem(
          index: 4,
          title: 'Pantry',
          icon: CupertinoIcons.cart_fill,
          isActive: selectedIndex == 4,
          color: primaryColor,
          textColor: textColor,
          activeTextColor: activeTextColor,
          backgroundColor: backgroundColor,
          onTap: onMenuItemClick,
        ),
        MenuItem(
          index: 5,
          title: '🧪Labs',
          icon: CupertinoIcons.settings,
          isActive: selectedIndex == 5,
          color: primaryColor,
          textColor: textColor,
          activeTextColor: activeTextColor,
          backgroundColor: backgroundColor,
          trailing: PremiumBadge(feature: 'labs'),
          onTap: (_) async {
            final debugInfo = ref.read(subscriptionDebugProvider);
            debugPrint('Labs tapped - hasAccess: $hasPlus, debugInfo: $debugInfo');
            
            if (hasPlus) {
              onRouteGo('/labs');
            } else {
              // Show paywall first, only navigate if user purchases
              try {
                final purchased = await ref.read(subscriptionProvider.notifier).presentPaywall();
                if (purchased) {
                  onRouteGo('/labs');
                }
                // If user cancels paywall, stay where they were (no navigation)
              } catch (e) {
                // Error presenting paywall, stay where they were
                debugPrint('Error presenting paywall: $e');
              }
            }
          },
        ),
        MenuItem(
          index: 5,
          title: '🧪Labs DEEP',
          icon: CupertinoIcons.settings,
          isActive: selectedIndex == 6,
          color: primaryColor,
          textColor: textColor,
          activeTextColor: activeTextColor,
          backgroundColor: backgroundColor,
          trailing: PremiumBadge(feature: 'labs'),
          onTap: (_) async {
            if (hasPlus) {
              onRouteGo('/labs/sub');
            } else {
              // Show paywall first, only navigate if user purchases
              try {
                final purchased = await ref.read(subscriptionProvider.notifier).presentPaywall();
                if (purchased) {
                  onRouteGo('/labs/sub');
                }
                // If user cancels paywall, stay where they were (no navigation)
              } catch (e) {
                // Error presenting paywall, stay where they were
              }
            }
          },
        ),
        MenuItem(
          index: 6,
          title: '🧪Auth',
          icon: CupertinoIcons.settings,
          isActive: selectedIndex == 7,
          color: primaryColor,
          textColor: textColor,
          activeTextColor: activeTextColor,
          backgroundColor: backgroundColor,
          onTap: (_) async {
            if (hasPlus) {
              onRouteGo('/labs/auth');
            } else {
              // Show paywall first, only navigate if user purchases
              try {
                final purchased = await ref.read(subscriptionProvider.notifier).presentPaywall();
                if (purchased) {
                  onRouteGo('/labs/auth');
                }
                // If user cancels paywall, stay where they were (no navigation)
              } catch (e) {
                // Error presenting paywall, stay where they were
              }
            }
          },
        ),
        MenuItem(
          index: 7,
          title: 'Household',
          icon: CupertinoIcons.home,
          isActive: selectedIndex == 8,
          color: primaryColor,
          textColor: textColor,
          activeTextColor: activeTextColor,
          backgroundColor: backgroundColor,
          onTap: (_) {
            onRouteGo('/household');
          },
        ),
        // Auth menu item - conditional based on authentication state
        if (!isAuthenticated)
          MenuItem(
            index: 8,
            title: 'Sign In',
            icon: CupertinoIcons.person_circle,
            isActive: selectedIndex == 9,
            color: primaryColor,
            textColor: textColor,
            activeTextColor: activeTextColor,
            backgroundColor: backgroundColor,
            onTap: (_) {
              onRouteGo('/auth');
            },
          ),
        if (isAuthenticated)
          MenuItem(
            index: 8,
            title: 'Sign Out',
            icon: CupertinoIcons.person_circle_fill,
            isActive: false, // Sign out never active
            color: primaryColor,
            textColor: textColor,
            activeTextColor: activeTextColor,
            backgroundColor: backgroundColor,
            onTap: (_) async {
              await _handleSignOut(context, ref);
            },
          ),
      ],
    );
  }

  /// Handle sign out with sync status checking
  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    try {
      final hasPendingSync = await _hasPendingSync(ref);
      
      if (hasPendingSync) {
        if (!context.mounted) return;
        final shouldSignOut = await _showSyncWarningDialog(context);
        if (!shouldSignOut) return; // User cancelled
      }
      
      // Proceed with sign out
      await ref.read(authNotifierProvider.notifier).signOut();
    } catch (e) {
      // Show error dialog if sign out fails
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Sign Out Error'),
            content: Text('Failed to sign out: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Check if there's pending sync activity
  Future<bool> _hasPendingSync(WidgetRef ref) async {
    try {
      // Check PowerSync sync status
      final syncStatus = db.currentStatus;
      
      // Check if actively syncing
      if (syncStatus.uploading == true || syncStatus.downloading == true) {
        return true;
      }
      
      // If not connected and hasn't completed initial sync
      if (syncStatus.connected != true && syncStatus.hasSynced != true) {
        return true;
      }

      // Check custom upload queue for images
      final uploadRepo = ref.read(uploadQueueRepositoryProvider);
      final pendingUploads = await uploadRepo.getPendingEntries();
      if (pendingUploads.isNotEmpty) {
        return true;
      }

      return false;
    } catch (e) {
      // On error, show warning to be safe
      return true;
    }
  }

  /// Show warning dialog for pending sync
  Future<bool> _showSyncWarningDialog(BuildContext context) async {
    return await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'Some data hasn\'t finished syncing. If you sign out now, '
          'your recent changes may be lost.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Sign Out Anyway'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ?? false; // Return false if dialog is dismissed
  }
}
