import 'dart:io' show Platform;
import 'package:cupertino_sidebar/cupertino_sidebar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test_2/src/features/discover/views/discover_root.dart';
import 'package:flutter_test_2/src/features/discover/views/discover_sub_page.dart';
import 'package:flutter_test_2/src/features/meal_plans/views/meal_plans_root.dart';
import 'package:flutter_test_2/src/features/meal_plans/views/meal_plans_sub_page.dart';
import 'package:flutter_test_2/src/features/recipes/views/recipes_root.dart';
import 'package:flutter_test_2/src/mobile/pages/meal_plan.dart';
import 'package:flutter_test_2/src/features/shopping_list/views/shopping_list_sub_page.dart';
import 'package:flutter_test_2/src/features/shopping_list/views/shopping_list_root.dart';
import 'package:go_router/go_router.dart';

import '../color_theme.dart';
import '../features/recipes/views/recipes_sub_page.dart';
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
  /// We still track _lastLocation, isSameTab, etc., but now each tab
  /// will have its own ShellRoute + navigatorKey.

  GoRouter _createRouter() {
    String? _previousLocation;
    String? _currentLocation;

    // Navigator keys for each tab's separate shell:
    final _recipesNavKey   = GlobalKey<NavigatorState>(debugLabel: 'recipesNavKey');
    final _shoppingNavKey  = GlobalKey<NavigatorState>(debugLabel: 'shoppingNavKey');
    final _mealPlansNavKey = GlobalKey<NavigatorState>(debugLabel: 'mealPlansNavKey');
    final _discoverNavKey  = GlobalKey<NavigatorState>(debugLabel: 'discoverNavKey');

    return GoRouter(
      debugLogDiagnostics: true,
      initialLocation: '/recipes',
      redirect: (context, state) {
        // Before changing anything, store the old in _previousLocation
        _previousLocation = _currentLocation;
        // Now update _currentLocation to the new path
        _currentLocation = state.uri.path;
        // No actual redirect
        return null;
      },
      routes: [
        // ─────────────────────────────────────────────────────────────
        // TOP-LEVEL SHELL: Builds MainPageShell
        // ─────────────────────────────────────────────────────────────
        ShellRoute(
          builder: (context, state, child) {
            return MainPageShell(child: child);
          },
          routes: [
            // ─────────────────────────────────────────────────────────
            // TAB 1 SHELL: Recipes
            // ─────────────────────────────────────────────────────────
            ShellRoute(
              navigatorKey: _recipesNavKey,
              pageBuilder: (BuildContext context, GoRouterState state, Widget child) {
                return CustomTransitionPage<void>(
                  key: state.pageKey,
                  child: child,
                  transitionDuration: const Duration(milliseconds: 400),
                  reverseTransitionDuration: const Duration(milliseconds: 400),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                      CupertinoTabPageTransition(animation: animation, child: child),
                );
              },
              routes: [
                GoRoute(
                  path: '/recipes',
                  routes: [
                    GoRoute(
                      path: 'sub',
                      pageBuilder: (context, state) => _platformPage(
                        state: state,
                        child: const RecipesSubPage(title: 'Sub Page'),
                      ),
                    ),
                  ],
                  pageBuilder: (context, state) => _tabTransitionPage(
                    state: state,
                    child: RecipesTab(
                      enableTitleTransition: _isSameTab(
                        from: _previousLocation,
                        to: state.uri.path
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ─────────────────────────────────────────────────────────
            // TAB 2 SHELL: Shopping
            // ─────────────────────────────────────────────────────────
            ShellRoute(
              navigatorKey: _shoppingNavKey,
              pageBuilder: (BuildContext context, GoRouterState state, Widget child) {
                return CustomTransitionPage<void>(
                  key: state.pageKey,
                  child: child,
                  transitionDuration: const Duration(milliseconds: 400),
                  reverseTransitionDuration: const Duration(milliseconds: 400),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                      CupertinoTabPageTransition(animation: animation, child: child),
                );
              },
              routes: [
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
                      enableTitleTransition: _isSameTab(
                        from: _previousLocation,
                        to: state.uri.path
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ─────────────────────────────────────────────────────────
            // TAB 3 SHELL: Meal Plans
            // ─────────────────────────────────────────────────────────
            ShellRoute(
              navigatorKey: _mealPlansNavKey,
              pageBuilder: (BuildContext context, GoRouterState state, Widget child) {
                return CustomTransitionPage<void>(
                  key: state.pageKey,
                  child: child,
                  transitionDuration: const Duration(milliseconds: 400),
                  reverseTransitionDuration: const Duration(milliseconds: 400),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                      CupertinoTabPageTransition(animation: animation, child: child),
                );
              },
              routes: [
                GoRoute(
                  path: '/meal_plans',
                  routes: [
                    GoRoute(
                      path: 'sub',
                      pageBuilder: (context, state) => _platformPage(
                        state: state,
                        child: const MealPlansSubPage(),
                      ),
                    ),
                  ],
                  pageBuilder: (context, state) => _tabTransitionPage(
                    state: state,
                    child: MealPlansRoot(
                      enableTitleTransition: _isSameTab(
                        from: _previousLocation,
                        to: state.uri.path
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ─────────────────────────────────────────────────────────
            // TAB 4 SHELL: Discover
            // ─────────────────────────────────────────────────────────
            ShellRoute(
              navigatorKey: _discoverNavKey,
              pageBuilder: (BuildContext context, GoRouterState state, Widget child) {
                return CustomTransitionPage<void>(
                  key: state.pageKey,
                  child: child,
                  transitionDuration: const Duration(milliseconds: 400),
                  reverseTransitionDuration: const Duration(milliseconds: 400),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                      CupertinoTabPageTransition(animation: animation, child: child),
                );
              },
              routes: [
                GoRoute(
                  path: '/discover',
                  routes: [
                    GoRoute(
                      path: 'sub',
                      pageBuilder: (context, state) => _platformPage(
                        state: state,
                        child: const DiscoverSubPage(),
                      ),
                    ),
                  ],
                  pageBuilder: (context, state) => _tabTransitionPage(
                    state: state,
                    child: DiscoverTab(
                      enableTitleTransition: _isSameTab(
                        from: _previousLocation,
                        to: state.uri.path
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// A helper method to see if we're staying in the same tab or not.
  bool _isSameTab({ required String? from, required String to }) {
    if (from == null) return false; // first time
    final fromTab = from.split('/')[1];
    final toTab = to.split('/')[1];
    return (fromTab == toTab);
  }

  /// We'll keep your platformPage exactly as is:
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

  /// We'll keep your tabTransitionPage as is:
  Page<void> _tabTransitionPage({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 400),
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
}
