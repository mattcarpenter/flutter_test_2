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
        itemBuilder: (context) => items.map((item) {
          return PullDownMenuItem(
            title: item.title,
            icon: item.icon.icon,
            onTap: item.onTap,
          );
        }).toList(),
        buttonBuilder: (context, showMenu) {
          return GestureDetector(
            onTap: showMenu,
            child: child,
          );
        },
        routeTheme: const PullDownMenuRouteTheme(
          shadow: BoxShadow(
            color: Color(0x33000000), // Black with 20% opacity
            blurRadius: 64,
            offset: Offset(0, 6),
            spreadRadius: 14,
          ),
        ),
      );
    } else {
      // Android (or other platforms): Use a Material PopupMenuButton.
      return PopupMenuButton<AdaptiveMenuItem>(
        itemBuilder: (context) {
          return items.map((item) {
            return PopupMenuItem<AdaptiveMenuItem>(
              value: item,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: item.icon,
                  ),
                  Text(item.title),
                ],
              ),
            );
          }).toList();
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
