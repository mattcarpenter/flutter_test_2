import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
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
    final isEffectivelyAuthenticated = ref.watch(isAuthenticatedProvider); // Returns false for anonymous users
    final isAnonymous = ref.watch(isAnonymousUserProvider);
    final hasPlus = ref.watch(effectiveHasPlusProvider); // Includes optimistic access after purchase

    // Theme Colors
    final Color backgroundColor = isDarkMode ? CupertinoTheme.of(context).barBackgroundColor : CupertinoTheme.of(context).scaffoldBackgroundColor;
    final Color primaryColor = CupertinoTheme.of(context).primaryColor;
    final Color textColor = CupertinoTheme.of(context)
        .textTheme
        .textStyle
        .color ?? Colors.black;
    final Color activeTextColor = isDarkMode ? textColor : primaryColor;

    return SingleChildScrollView(
      child: Column(
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
          title: 'Clippings',
          icon: CupertinoIcons.doc_text,
          isActive: selectedIndex == 5,
          color: primaryColor,
          textColor: textColor,
          activeTextColor: activeTextColor,
          backgroundColor: backgroundColor,
          onTap: (_) {
            onRouteGo('/clippings');
          },
        ),
        MenuItem(
          index: 6,
          title: 'Discover',
          icon: CupertinoIcons.compass,
          isActive: selectedIndex == 6,
          color: primaryColor,
          textColor: textColor,
          activeTextColor: activeTextColor,
          backgroundColor: backgroundColor,
          onTap: (_) {
            onRouteGo('/discover');
          },
        ),
        MenuItem(
          index: 7,
          title: '🧪Labs',
          icon: CupertinoIcons.settings,
          isActive: selectedIndex == 7,
          color: primaryColor,
          textColor: textColor,
          activeTextColor: activeTextColor,
          backgroundColor: backgroundColor,
          trailing: PremiumBadge(feature: 'labs'),
          onTap: (_) async {
            if (hasPlus) {
              onRouteGo('/labs');
            } else {
              // Show paywall first, only navigate if user purchases
              try {
                final purchased = await ref.read(subscriptionProvider.notifier).presentPaywall(context);
                if (purchased) {
                  onRouteGo('/labs');
                }
                // If user cancels paywall, stay where they were (no navigation)
              } catch (e) {
                // Error presenting paywall, stay where they were
              }
            }
          },
        ),
        MenuItem(
          index: 5,
          title: '🧪Labs DEEP',
          icon: CupertinoIcons.settings,
          isActive: selectedIndex == 7,
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
                final purchased = await ref.read(subscriptionProvider.notifier).presentPaywall(context);
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
          isActive: selectedIndex == 8,
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
                final purchased = await ref.read(subscriptionProvider.notifier).presentPaywall(context);
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
          index: 8,
          title: 'Household',
          icon: CupertinoIcons.home,
          isActive: selectedIndex == 9,
          color: primaryColor,
          textColor: textColor,
          activeTextColor: activeTextColor,
          backgroundColor: backgroundColor,
          onTap: (_) {
            // Household features require full registration (not anonymous)
            if (isEffectivelyAuthenticated) {
              onRouteGo('/household');
            } else {
              // Anonymous or logged out - redirect to auth
              onRouteGo('/auth');
            }
          },
        ),
        MenuItem(
          index: 9,
          title: 'Settings',
          icon: CupertinoIcons.settings,
          isActive: selectedIndex == 10,
          color: primaryColor,
          textColor: textColor,
          activeTextColor: activeTextColor,
          backgroundColor: backgroundColor,
          onTap: (_) {
            onRouteGo('/settings');
          },
        ),
        // Sign in menu item - show when not effectively authenticated (including anonymous users)
        // Sign out is now in Settings > Account
        if (!isEffectivelyAuthenticated)
          MenuItem(
            index: 10,
            title: 'Sign In',
            icon: CupertinoIcons.person_circle,
            isActive: selectedIndex == 11,
            color: primaryColor,
            textColor: textColor,
            activeTextColor: activeTextColor,
            backgroundColor: backgroundColor,
            onTap: (_) {
              onRouteGo('/auth');
            },
          ),
        ],
      ),
    );
  }
}
