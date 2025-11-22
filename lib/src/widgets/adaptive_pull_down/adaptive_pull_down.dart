import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'adaptive_menu_item.dart'; // if you want to keep the model in a separate file

class AdaptivePullDownButton extends StatelessWidget {
  final Widget child;
  final List<AdaptiveMenuItem> items;

  const AdaptivePullDownButton({
    Key? key,
    required this.child,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      // iOS: Use pull_down_button for a Cupertino-style menu.
      return PullDownButton(
        itemBuilder: (context) {
          final List<PullDownMenuEntry> menuItems = [];
          for (final item in items) {
            if (item.isDivider) {
              menuItems.add(const PullDownMenuDivider.large());
            } else if (item.isDestructive) {
              menuItems.add(PullDownMenuItem(
                title: item.title,
                icon: item.icon.icon,
                onTap: item.onTap,
                isDestructive: true,
              ));
            } else {
              menuItems.add(PullDownMenuItem(
                title: item.title,
                icon: item.icon.icon,
                iconColor: item.icon.color,
                onTap: item.onTap,
              ));
            }
          }
          return menuItems;
        },
        buttonBuilder: (context, showMenu) {
          return GestureDetector(
            onTap: showMenu,
            child: child,
          );
        },
        routeTheme: const PullDownMenuRouteTheme(
          shadow: BoxShadow(
            color: Color(0x20000000), // Black with ~12% opacity
            blurRadius: 32,
            offset: Offset(0, 8),
            spreadRadius: 0, // No spread for natural soft fade
          ),
        ),
      );
    } else {
      // Android (or other platforms): Use a Material PopupMenuButton.
      return PopupMenuButton<AdaptiveMenuItem>(
        itemBuilder: (context) {
          final List<PopupMenuEntry<AdaptiveMenuItem>> menuItems = [];
          for (final item in items) {
            if (item.isDivider) {
              menuItems.add(const PopupMenuDivider());
            } else {
              final textStyle = item.isDestructive
                  ? const TextStyle(color: Colors.red)
                  : null;
              final iconColor = item.isDestructive
                  ? Colors.red
                  : item.icon.color;

              menuItems.add(PopupMenuItem<AdaptiveMenuItem>(
                value: item,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(
                        item.icon.icon,
                        color: iconColor,
                      ),
                    ),
                    Text(item.title, style: textStyle),
                  ],
                ),
              ));
            }
          }
          return menuItems;
        },
        onSelected: (item) {
          if (item.onTap != null) {
            item.onTap!();
          }
        },
        child: child,
      );
    }
  }
}
