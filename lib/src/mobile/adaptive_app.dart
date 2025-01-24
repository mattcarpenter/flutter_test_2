import 'dart:io' show Platform;
import 'package:cupertino_sidebar/cupertino_sidebar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test_2/src/features/recipes/views/recipes_root.dart';
import 'package:flutter_test_2/src/mobile/pages/discover.dart';
import 'package:flutter_test_2/src/mobile/pages/meal_plan.dart';
import 'package:flutter_test_2/src/features/shopping_list/views/shopping_list_sub_page.dart';
import 'package:flutter_test_2/src/features/shopping_list/views/shopping_list_root.dart';
import 'package:go_router/go_router.dart';

import '../color_theme.dart';
import 'main_page_shell.dart'; // We'll define a Shell widget for the tabs.

class AdaptiveApp2 extends StatelessWidget {
  const AdaptiveApp2({super.key});

  @override
  Widget build(BuildContext context) {
    final router = _createRouter();
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final bool isDarkMode = brightness == Brightness.dark;

    if (Platform.isIOS) {
      return CupertinoApp.router(
        routeInformationParser: router.routeInformationParser,
        routerDelegate: router.routerDelegate,
        routeInformationProvider: router.routeInformationProvider,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
        ],
        theme: isDarkMode
            ? AppTheme.cupertinoDarkTheme
            : AppTheme.cupertinoLightTheme,
      );
    } else {
      return MaterialApp.router(
        routeInformationParser: router.routeInformationParser,
        routerDelegate: router.routerDelegate,
        routeInformationProvider: router.routeInformationProvider,
        theme: AppTheme.materialLightTheme,
        darkTheme: AppTheme.materialDarkTheme,
      );
    }
  }

  /// Create a [GoRouter] instance with shell routing for the bottom tabs.
  GoRouter _createRouter() {
    return GoRouter(
      debugLogDiagnostics: true, // Helpful for debugging route transitions
      initialLocation: '/recipes', // e.g., set the default tab
      routes: [
        // A ShellRoute that manages your bottom/tab navigation or drawer-based layout
        ShellRoute(
          builder: (context, state, child) {
            return MainPageShell(child: child);
          },
          routes: [
            // Each child route represents a tab (or drawer item).
            GoRoute(
              path: '/recipes',
              pageBuilder: (context, state) => _platformPage(
                state: state,
                child: const RecipesTab(),
              ),
            ),
            GoRoute(
              path: '/shopping',
              // We can nest sub-routes for /sub or /deep:
              routes: [
                GoRoute(
                  path: 'sub',  // combined => /shopping/sub
                  pageBuilder: (context, state) => _platformPage(
                    state: state,
                    child: const ShoppingListSubPage(title: 'Sub Page'),
                  ),
                ),
              ],
              pageBuilder: (context, state) => _platformPage(
                state: state,
                child: const ShoppingListTab(),
              ),
            ),
            GoRoute(
              path: '/meal_plan',
              pageBuilder: (context, state) => _platformPage(
                state: state,
                child: const MealPlanPage(title: 'Meal Plan'),
              ),
            ),
            GoRoute(
              path: '/discover',
              pageBuilder: (context, state) => _platformPage(
                state: state,
                child: const DiscoverPage(title: 'Discover'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Wraps routes in CupertinoPage on iOS, MaterialPage on other platforms.
  Page<void> _platformPage({
    required GoRouterState state,
    required Widget child,
  }) {
    if (Platform.isIOS) {
      return CupertinoPage(
        child: child,
        key: state.pageKey,
        title: state.name,
      );
    } else {
      return MaterialPage(
        child: child,
        key: state.pageKey,
      );
    }
  }
}

Page<void> _tabTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  // We'll use a CustomTransitionPage so we can define exactly how to animate.
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    // This is the magic: use CupertinoTabPageTransition for the "zoom/fade" effect
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return CupertinoTabPageTransition(
        animation: animation,
        child: child,
      );
    },
  );
}

Page<void> _pushTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  if (Platform.isIOS) {
    return CupertinoPage<void>(
      key: state.pageKey,
      child: child,
      title: state.name,
    );
  } else {
    return MaterialPage<void>(
      key: state.pageKey,
      child: child,
    );
  }
}
