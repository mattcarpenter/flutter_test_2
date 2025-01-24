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
  /// In `_createRouter()`, we track the last known path so we can detect
  /// if the user is switching tabs or pushing deeper.

  GoRouter _createRouter() {
    String? _lastLocation;

    return GoRouter(
      debugLogDiagnostics: true,
      initialLocation: '/recipes',
      // Use a redirect to store the old location before we change.
      // So we can tell if the new path is the same tab or not.
      redirect: (context, state) {
        final from = _lastLocation;
        final to = state.uri.path;
        _lastLocation = to; // update for next time
        return null;        // no actual redirect
      },
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return MainPageShell(child: child);
          },
          routes: [
            // Tab 1
            GoRoute(
              path: '/recipes',
              pageBuilder: (context, state) => _tabTransitionPage(
                state: state,
                // We'll pass a param to tell the page if we want transitions or not
                child: RecipesTab(
                  enableTitleTransition: _isSameTab(from: _lastLocation, to: '/recipes'),
                ),
              ),
            ),
            // Tab 2
            GoRoute(
              path: '/shopping',
              routes: [
                GoRoute(
                  path: 'sub',
                  pageBuilder: (context, state) => _platformPage(
                    state: state,
                    child: const ShoppingListSubPage(title: 'Sub Page'),
                  ),
                ),
              ],
              pageBuilder: (context, state) => _tabTransitionPage(
                state: state,
                child: ShoppingListTab(
                  enableTitleTransition: _isSameTab(from: _lastLocation, to: '/shopping'),
                ),
              ),
            ),
            // Tab 3
            GoRoute(
              path: '/meal_plan',
              pageBuilder: (context, state) => _tabTransitionPage(
                state: state,
                child: MealPlanPage(
                  title: 'Meal Plan',
                  enableTitleTransition: _isSameTab(from: _lastLocation, to: '/meal_plan'),
                ),
              ),
            ),
            // Tab 4
            GoRoute(
              path: '/discover',
              pageBuilder: (context, state) => _tabTransitionPage(
                state: state,
                child: DiscoverPage(
                  title: 'Discover',
                  enableTitleTransition: _isSameTab(from: _lastLocation, to: '/discover'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// A helper method to see if we're staying in the same tab or not.
  bool _isSameTab({ required String? from, required String to }) {
    if (from == null) return false; // first time
    // simplistic check: see if both start with '/recipes' or '/shopping' ...
    final fromTab = from.split('/')[1];
    final toTab = to.split('/')[1];
    return (fromTab == toTab);
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
    //This is the magic: use CupertinoTabPageTransition for the "zoom/fade" effect
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
