import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'menu_item.dart';

class Menu extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

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
          index: 0,
          title: 'Recipes',
          icon: CupertinoIcons.book,
          isActive: selectedIndex == 0,
          color: primaryColor,
          textColor: textColor,
          activeTextColor: activeTextColor,
          backgroundColor: backgroundColor,
          onTap: onMenuItemClick,
        ),
        MenuItem(
          index: 1,
          title: 'Shopping List',
          icon: CupertinoIcons.shopping_cart,
          isActive: selectedIndex == 1,
          color: primaryColor,
          textColor: textColor,
          activeTextColor: activeTextColor,
          backgroundColor: backgroundColor,
          onTap: onMenuItemClick,
        ),
        MenuItem(
          index: 2,
          title: 'Meal Plans',
          icon: CupertinoIcons.calendar_today,
          isActive: selectedIndex == 2,
          color: primaryColor,
          textColor: textColor,
          activeTextColor: activeTextColor,
          backgroundColor: backgroundColor,
          onTap: onMenuItemClick,
        ),
        MenuItem(
          index: 3,
          title: 'Discover',
          icon: CupertinoIcons.compass,
          isActive: selectedIndex == 3,
          color: primaryColor,
          textColor: textColor,
          activeTextColor: activeTextColor,
          backgroundColor: backgroundColor,
          onTap: onMenuItemClick,
        ),
        MenuItem(
          index: 4,
          title: '🧪Labs',
          icon: CupertinoIcons.settings,
          isActive: selectedIndex == 4,
          color: primaryColor,
          textColor: textColor,
          activeTextColor: activeTextColor,
          backgroundColor: backgroundColor,
          onTap: (_) {
            onRouteGo('/labs');
          },
        ),
      ],
    );
  }
}
