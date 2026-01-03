import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../localization/l10n_extension.dart';
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
                const SizedBox(height: 12),
                MenuItem(
                  index: 1,
                  title: context.l10n.menuRecipes,
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedBook01, color: primaryColor, size: 20),
                  isActive: selectedIndex == 1,
                  color: primaryColor,
                  textColor: textColor,
                  activeTextColor: activeTextColor,
                  backgroundColor: backgroundColor,
                  onTap: onMenuItemClick,
                ),
                MenuItem(
                  index: 2,
                  title: context.l10n.menuShoppingList,
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedShoppingCart01, color: primaryColor, size: 20),
                  isActive: selectedIndex == 2,
                  color: primaryColor,
                  textColor: textColor,
                  activeTextColor: activeTextColor,
                  backgroundColor: backgroundColor,
                  onTap: onMenuItemClick,
                ),
                MenuItem(
                  index: 3,
                  title: context.l10n.menuMealPlans,
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedCalendar01, color: primaryColor, size: 20),
                  isActive: selectedIndex == 3,
                  color: primaryColor,
                  textColor: textColor,
                  activeTextColor: activeTextColor,
                  backgroundColor: backgroundColor,
                  onTap: onMenuItemClick,
                ),
                MenuItem(
                  index: 4,
                  title: context.l10n.menuPantry,
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedFridge, color: primaryColor, size: 20),
                  isActive: selectedIndex == 4,
                  color: primaryColor,
                  textColor: textColor,
                  activeTextColor: activeTextColor,
                  backgroundColor: backgroundColor,
                  onTap: onMenuItemClick,
                ),
                MenuItem(
                  index: 5,
                  title: context.l10n.menuClippings,
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedFile01, color: primaryColor, size: 20),
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
                  title: context.l10n.menuDiscover,
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedCompass01, color: primaryColor, size: 20),
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
                  title: context.l10n.menuHousehold,
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedHome01, color: primaryColor, size: 20),
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
            backgroundColor: backgroundColor,
            textColor: activeTextColor,
            title: context.l10n.menuUpgradeTitle,
            subtitle: context.l10n.menuUpgradeSubtitle,
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
                title: context.l10n.menuAccount,
                icon: HugeIcon(icon: HugeIcons.strokeRoundedUserCircle, color: primaryColor, size: 20),
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
                title: context.l10n.menuSignUp,
                icon: HugeIcon(icon: HugeIcons.strokeRoundedUserCircle, color: primaryColor, size: 20),
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
              title: context.l10n.menuSettings,
              icon: HugeIcon(icon: HugeIcons.strokeRoundedSettings01, color: primaryColor, size: 20),
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
  final Color backgroundColor;
  final Color textColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _UpgradeBanner({
    required this.isDarkMode,
    required this.backgroundColor,
    required this.textColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_UpgradeBanner> createState() => _UpgradeBannerState();
}

class _UpgradeBannerState extends State<_UpgradeBanner> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.textColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedAiMagic,
                color: widget.textColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: widget.textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: widget.textColor,
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
