import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/colors.dart';
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
    final hasPlus = ref.watch(effectiveHasPlusProvider);

    // Theme Colors
    final Color backgroundColor = isDarkMode ? CupertinoTheme.of(context).barBackgroundColor : CupertinoTheme.of(context).scaffoldBackgroundColor;
    final Color primaryColor = CupertinoTheme.of(context).primaryColor;
    final Color textColor = CupertinoTheme.of(context)
        .textTheme
        .textStyle
        .color ?? Colors.black;
    final Color activeTextColor = isDarkMode ? textColor : primaryColor;

    return Column(
        children: [
          // Main menu items (scrollable)
          Expanded(
          child: SingleChildScrollView(
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
                  icon: CupertinoIcons.archivebox,
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
                  title: 'Household',
                  icon: CupertinoIcons.home,
                  isActive: selectedIndex == 7,
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
              ],
            ),
          ),
        ),
        // Upgrade CTA for non-Plus users (pinned above bottom items)
        if (!hasPlus)
          _UpgradeBanner(
            isDarkMode: isDarkMode,
            onTap: () async {
              await ref.read(subscriptionProvider.notifier).presentPaywall(context);
            },
          ),
        // Bottom items (pinned to bottom)
        Divider(
          height: 1,
          thickness: 0.5,
          color: textColor.withValues(alpha: 0.15),
        ),
        const SizedBox(height: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Account (when authenticated) or Sign Up (when not)
            if (isEffectivelyAuthenticated)
              MenuItem(
                index: 8,
                title: 'Account',
                icon: CupertinoIcons.person_circle_fill,
                isActive: selectedIndex == 8,
                color: primaryColor,
                textColor: textColor,
                activeTextColor: activeTextColor,
                backgroundColor: backgroundColor,
                onTap: (_) {
                  onRouteGo('/settings/account');
                },
              )
            else
              MenuItem(
                index: 8,
                title: 'Sign Up',
                icon: CupertinoIcons.person_circle_fill,
                isActive: selectedIndex == 8,
                color: primaryColor,
                textColor: textColor,
                activeTextColor: activeTextColor,
                backgroundColor: backgroundColor,
                onTap: (_) {
                  onRouteGo('/auth');
                },
              ),
            MenuItem(
              index: 9,
              title: 'Settings',
              icon: CupertinoIcons.settings,
              isActive: selectedIndex == 9,
              color: primaryColor,
              textColor: textColor,
              activeTextColor: activeTextColor,
              backgroundColor: backgroundColor,
              onTap: (_) {
                onRouteGo('/settings');
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Upgrade banner CTA for non-Plus users
class _UpgradeBanner extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onTap;

  const _UpgradeBanner({
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  State<_UpgradeBanner> createState() => _UpgradeBannerState();
}

class _UpgradeBannerState extends State<_UpgradeBanner> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Gradient from orange to gold/amber
    const goldColor = Color(0xFFFFAB00); // Amber/gold
    final gradientColors = widget.isDarkMode
        ? [AppColorSwatches.primary[400]!, goldColor]
        : [AppColorSwatches.primary[500]!, goldColor];

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _isPressed ? 0.7 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.sparkles,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Upgrade to Plus',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Import from social media & more',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
