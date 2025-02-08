import 'dart:io' show Platform;
import 'package:cupertino_sidebar/cupertino_sidebar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_app/src/features/recipes/views/recipes_folder_page.dart';

import '../color_theme.dart';
import '../features/discover/views/discover_root.dart';
import '../features/discover/views/discover_sub_page.dart';
import '../features/labs/views/auth_sub_page.dart';
import '../features/labs/views/labs_root.dart';
import '../features/labs/views/labs_sub_page.dart';
import '../features/meal_plans/views/meal_plans_root.dart';
import '../features/meal_plans/views/meal_plans_sub_page.dart';
import '../features/recipes/views/recipes_root.dart';
import '../features/shopping_list/views/shopping_list_root.dart';
import '../features/shopping_list/views/shopping_list_sub_page.dart';
import 'main_page_shell.dart';

bool isTablet(BuildContext context) {
  return MediaQuery.of(context).size.shortestSide >= 600;
}

class AdaptiveApp2 extends StatefulWidget {
  const AdaptiveApp2({super.key});

  @override
  State<AdaptiveApp2> createState() => _AdaptiveApp2State();
}

class _AdaptiveApp2State extends State<AdaptiveApp2> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only create the GoRouter once. We use `isTablet(context)` here
    // but do not re-create the router on subsequent rebuilds.
    if (_router == null) {
      _router = _createRouter(isTablet(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final bool isDarkMode = brightness == Brightness.dark;

    // Safely unwrap the router we created.
    final router = _router!;

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
  GoRouter _createRouter(bool isTablet) {
    // Navigator keys for each tab's separate shell:
    final _recipesNavKey   = GlobalKey<NavigatorState>(debugLabel: 'recipesNavKey');
    final _shoppingNavKey  = GlobalKey<NavigatorState>(debugLabel: 'shoppingNavKey');
    final _mealPlansNavKey = GlobalKey<NavigatorState>(debugLabel: 'mealPlansNavKey');
    final _discoverNavKey  = GlobalKey<NavigatorState>(debugLabel: 'discoverNavKey');
    final _mainPageShellKey = GlobalKey<MainPageShellState>(debugLabel: 'mainPageShellKey');

    final nonTabRoutes = [
      ShellRoute(
        pageBuilder: (BuildContext context, GoRouterState state, Widget child) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: child,
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                CupertinoTabPageTransition(
                  animation: animation,
                  child: isTablet
                      ? child
                      : MainPageShell(
                    key: _mainPageShellKey,
                    child: child,
                    showBottomNavBar: false,
                  ),
                ),
          );
        },
        routes: [
          GoRoute(
            path: '/labs',
            routes: [
              GoRoute(
                path: 'sub',
                pageBuilder: (context, state) => _platformPage(
                  state: state,
                  child: const LabsSubPage(),
                ),
              ),
              GoRoute(
                path: 'auth',
                pageBuilder: (context, state) => _platformPage(
                  state: state,
                  child: const AuthSubPage(),
                ),
              )
            ],
            pageBuilder: (context, state) => _platformPage(
              state: state,
              child: LabsTab(
                onMenuPressed: () {
                  _mainPageShellKey.currentState?.toggleDrawer();
                },
              ),
            ),
          ),
        ],
      ),
    ];

    return GoRouter(
      debugLogDiagnostics: true,
      initialLocation: '/recipes',
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
                      path: 'folder/:parentId',
                      pageBuilder: (context, state) {
                        // Extract the parent folder id from the path.
                        final parentId = state.pathParameters['parentId'];

                        // Get extra data (if provided) as a Map. Otherwise, use defaults.
                        final extraData = state.extra as Map<String, String>?;
                        final folderTitle = extraData?['folderTitle'] ?? 'Folders';
                        final previousPageTitle = extraData?['previousPageTitle'] ?? 'Recipes';
                        return _platformPage(
                          state: state,
                          child: RecipesFolderPage(
                            parentId: parentId,
                            title: folderTitle,
                            previousPageTitle: previousPageTitle,
                          ),
                        );
                      },
                    ),
                  ],
                  pageBuilder: (context, state) => _platformPage(
                    state: state,
                    child: RecipesTab(),
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
                  pageBuilder: (context, state) => _platformPage(
                    state: state,
                    child: ShoppingListTab(),
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
                  pageBuilder: (context, state) => _platformPage(
                    state: state,
                    child: MealPlansRoot(),
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
                  pageBuilder: (context, state) => _platformPage(
                    state: state,
                    child: DiscoverTab(),
                  ),
                ),
              ],
            ),

            // Include non-tab routes within this ShellRoute if on tablet
            if (isTablet) ...nonTabRoutes,
          ],
        ),
        if (!isTablet) ...nonTabRoutes,
      ],
    );
  }

  /// Platform-aware page builder, unchanged from your code.
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
