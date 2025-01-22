import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_2/src/mobile/pages/shopping_list/shopping_list_root_page.dart';
import 'package:flutter_test_2/src/mobile/pages/shopping_list/shopping_list_routes.dart';

import '../shopping_list_sub.dart';

class ShoppingListTab extends StatefulWidget {
  final ShoppingListRoutes initialRoute;

  const ShoppingListTab({
    super.key,
    this.initialRoute = ShoppingListRoutes.root,
  });

  @override
  _ShoppingListTabState createState() => _ShoppingListTabState();
}

class _ShoppingListTabState extends State<ShoppingListTab> {
  late final GlobalKey<NavigatorState> _navigatorKey;

  @override
  void initState() {
    super.initState();
    _navigatorKey = GlobalKey<NavigatorState>();

    // Push the initial route stack after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleDeepLinking();
    });
  }

  void _handleDeepLinking() {
    if (widget.initialRoute == ShoppingListRoutes.root) return;

    // Push additional routes based on the initial route
    final navigator = _navigatorKey.currentState!;
    if (widget.initialRoute == ShoppingListRoutes.subPage) {
      navigator.pushNamed('/sub');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabView(
      navigatorKey: _navigatorKey, // Assign the custom navigator key
      onGenerateRoute: (RouteSettings settings) {
        print('ON GENERATE ROUTE: ${settings.name}');
        switch (settings.name) {
          case '/':
            return _platformPageRoute(
              builder: (_) => ShoppingListRootPage(),
              settings: settings,
            );
          case '/sub':
            return _platformPageRoute(
              builder: (_) => const ShoppingListSubPage(),
              settings: settings,
            );
          default:
            throw Exception('Unknown route: ${settings.name}');
        }
      },
    );
  }

  Route<dynamic> _platformPageRoute({
    required WidgetBuilder builder,
    required RouteSettings settings,
  }) {
    if (Platform.isIOS) {
      return CupertinoPageRoute(
        builder: builder,
        settings: settings,
      );
    } else {
      return MaterialPageRoute(
        builder: builder,
        settings: settings,
      );
    }
  }
}
