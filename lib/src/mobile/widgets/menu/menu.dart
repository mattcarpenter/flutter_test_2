import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../color_theme.dart';

class Menu extends StatelessWidget {
  final int selectedIndex;
  final void Function(int index) onMenuItemClick;

  const Menu({
    super.key,
    required this.selectedIndex,
    required this.onMenuItemClick,
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
      ],
    );
  }
}

class MenuItem extends StatelessWidget {
  final int index;
  final String title;
  final IconData icon;
  final bool isActive;
  final Color color;
  final Color textColor;
  final Color activeTextColor;
  final Color backgroundColor;
  final void Function(int index) onTap;

  const MenuItem({
    super.key,
    required this.index,
    required this.title,
    required this.icon,
    required this.isActive,
    required this.color,
    required this.activeTextColor,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final typography = CupertinoTheme.of(context).textTheme;

    final effectiveTextStyle = isActive
        ? typography.textStyle.copyWith(
            color: activeTextColor,
            fontWeight: FontWeight.w600,
        )
        : typography.textStyle;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
        decoration: BoxDecoration(
          color: isActive ? backgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.08), // Shadow color
              blurRadius: 10.0, // How blurred the shadow should be
              offset: const Offset(0, 2), // Position of the shadow
            ),
          ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
            ),
            const SizedBox(width: 10),
            Text(title, style: effectiveTextStyle),
          ],
        ),
      ),
    );

  }
}
