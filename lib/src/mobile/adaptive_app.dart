import 'dart:io' show Platform;
import 'package:cupertino_sidebar/cupertino_sidebar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:recipe_app/src/features/recipes/views/recipe_page.dart';
import 'package:recipe_app/src/features/recipes/views/recipes_folder_page.dart';
import 'package:recipe_app/src/mobile/utils/adaptive_sheet_page.dart';

import '../color_theme.dart';
import '../features/pantry/views/pantry_root.dart';
import '../features/pantry/views/pantry_sub_page.dart';
import '../features/labs/views/auth_sub_page.dart';
import '../features/labs/views/labs_root.dart';
import '../features/labs/views/labs_sub_page.dart';
import '../features/meal_plans/views/meal_plans_root.dart';
import '../features/meal_plans/views/meal_plans_sub_page.dart';
import '../features/recipes/views/recipes_root.dart';
import '../features/shopping_list/views/shopping_list_root.dart';
import '../features/shopping_list/views/shopping_list_sub_page.dart';
import '../features/household/views/household_sharing_page.dart';
import 'main_page_shell.dart';
import 'package:sheet/route.dart';

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
    final _rootNavKey   = GlobalKey<NavigatorState>(debugLabel: 'rootNavKey');
    final _recipesNavKey   = GlobalKey<NavigatorState>(debugLabel: 'recipesNavKey');
    final _shoppingNavKey  = GlobalKey<NavigatorState>(debugLabel: 'shoppingNavKey');
    final _mealPlansNavKey = GlobalKey<NavigatorState>(debugLabel: 'mealPlansNavKey');
    final _pantryNavKey  = GlobalKey<NavigatorState>(debugLabel: 'pantryNavKey');
    final _mainPageShellKey = GlobalKey<MainPageShellState>(debugLabel: 'mainPageShellKey');
    final _householdPageShellKey = GlobalKey<MainPageShellState>(debugLabel: 'householdPageShellKey');

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
              ),
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
                    key: _householdPageShellKey,
                    child: child,
                    showBottomNavBar: false,
                  ),
                ),
          );
        },
        routes: [
          GoRoute(
            path: '/household',
            pageBuilder: (context, state) => _platformPage(
              state: state,
              child: HouseholdSharingPage(
                onMenuPressed: () {
                  _householdPageShellKey.currentState?.toggleDrawer();
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
      navigatorKey: _rootNavKey,
      routes: [
        GoRoute(
            path: '/add_folder',
            pageBuilder: (context, state) => buildAdaptiveSheetPage<void>(
              child: Container(child:Text("hello world")),
              context: context,
              state: state
            )
        ),
        ShellRoute(
          pageBuilder: (context, state, child) {
            if (Platform.isIOS) {
              return CupertinoExtendedPage(child: child);
            }
            return  MaterialExtendedPage(child: child);
          },
          routes: [

        // ─────────────────────────────────────────────────────────────
        // TOP-LEVEL SHELL: Builds MainPageShell
        // ─────────────────────────────────────────────────────────────
        ShellRoute(
          builder: (context, state, child) {
            //final currentLocation = state.uri.path;
            //final showBottomNavBar = !(currentLocation ?? '').contains('add_folder');
            return MainPageShell(child: child, showBottomNavBar: true);
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
                      path: 'recipe/:recipeId',
                      pageBuilder: (context, state) {
                        final recipeId = state.pathParameters['recipeId'];
                        final extraData = state.extra as Map<String, String>?;
                        final previousPageTitle = extraData?['previousPageTitle'] ?? 'Recipes';
                        return _platformPage(
                          state: state,
                          child: RecipePage(recipeId: recipeId!, previousPageTitle: previousPageTitle),
                        );
                      },
                    ),
                    GoRoute(
                      path: 'folder/:folderId',
                      pageBuilder: (context, state) {
                        // Extract the parent folder id from the path.
                        final folderId = state.pathParameters['folderId'];

                        // Get extra data (if provided) as a Map. Otherwise, use defaults.
                        final extraData = state.extra;

                        final folderTitle = (extraData is Map<String, dynamic> && extraData['folderTitle'] is String)
                            ? extraData['folderTitle'] as String
                            : 'Folders';

                        final previousPageTitle = (extraData is Map<String, dynamic> && extraData['previousPageTitle'] is String)
                            ? extraData['previousPageTitle'] as String
                            : 'Recipes';

                        return _platformPage(
                          state: state,
                          child: RecipesFolderPage(
                            folderId: folderId,
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
            // TAB 4 SHELL: Pantry
            // ─────────────────────────────────────────────────────────
            ShellRoute(
              navigatorKey: _pantryNavKey,
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
                  path: '/pantry',
                  routes: [
                    GoRoute(
                      path: 'sub',
                      pageBuilder: (context, state) => _platformPage(
                        state: state,
                        child: const PantrySubPage(),
                      ),
                    ),
                  ],
                  pageBuilder: (context, state) => _platformPage(
                    state: state,
                    child: PantryTab(),
                  ),
                ),
              ],
            ),

            // Include non-tab routes within this ShellRoute if on tablet
            if (isTablet) ...nonTabRoutes,
          ],
        ),
        if (!isTablet) ...nonTabRoutes,
    ])],
    );
  }

  /// Platform-aware page builder, unchanged from your code.
  Page<void> _platformPage({
    required GoRouterState state,
    required Widget child,
  }) {
    if (Platform.isIOS) {
      return CupertinoExtendedPage(
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
