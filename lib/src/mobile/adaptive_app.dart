import 'dart:io' show Platform;
import 'package:cupertino_sidebar/cupertino_sidebar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../localization/app_localizations.dart';
import '../localization/custom_cupertino_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:recipe_app/src/features/recipes/views/recipe_page.dart';
import 'package:recipe_app/src/features/recipes/views/recipes_folder_page.dart';
import 'package:recipe_app/src/features/recipes/views/pinned_recipes_page.dart';
import 'package:recipe_app/src/features/recipes/views/recently_viewed_page.dart';
import 'package:recipe_app/src/mobile/utils/adaptive_sheet_page.dart';

import '../color_theme.dart';
import '../features/pantry/views/pantry_root.dart';
import '../features/pantry/views/pantry_sub_page.dart';
import '../features/clippings/views/clippings_root.dart';
import '../features/clippings/views/clipping_editor_page.dart';
import '../features/discover/views/discover_page.dart';
import '../features/auth/views/auth_landing_page.dart';
import '../features/auth/views/sign_in_page.dart';
import '../features/auth/views/sign_up_page.dart';
import '../features/auth/views/forgot_password_page.dart';
import '../features/settings/views/settings_page.dart';
import '../features/settings/views/manage_tags_page.dart';
import '../features/settings/views/home_screen_page.dart';
import '../features/settings/views/layout_appearance_page.dart';
import '../features/settings/views/theme_mode_page.dart';
import '../features/settings/views/show_folders_page.dart';
import '../features/settings/views/sort_folders_page.dart';
import '../features/settings/views/recipe_font_size_page.dart';
import '../features/settings/views/account_page.dart';
import '../features/settings/views/acknowledgements_page.dart';
import '../features/import_export/views/import_page.dart';
import '../features/import_export/views/export_page.dart';
import '../features/import_export/views/import_preview_page.dart';
import '../features/import_export/services/import_service.dart';
import '../features/settings/views/legal_pages.dart';
import '../features/settings/views/support_page.dart';
import '../features/help/views/help_page.dart';
import '../features/settings/providers/app_settings_provider.dart';
import '../features/meal_plans/views/meal_plans_root.dart';
import '../features/meal_plans/views/meal_plans_sub_page.dart';
import '../features/recipes/views/recipes_root.dart';
import '../features/shopping_list/views/shopping_list_root.dart';
import '../features/shopping_list/views/shopping_list_sub_page.dart';
import '../features/household/views/household_sharing_page.dart';
import 'main_page_shell.dart';
import 'global_status_bar.dart';
import 'package:sheet/route.dart';
import '../widgets/identity_exists_error_listener.dart';
import '../widgets/restore_prompt_listener.dart';
import '../widgets/share_session_listener.dart';

/// Global navigator key for accessing Navigator from anywhere in the app.
/// Used by GlobalStatusBarWrapper to show modals with proper Navigator context.
final globalRootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'globalRootNavKey');

bool isTablet(BuildContext context) {
  return MediaQuery.sizeOf(context).shortestSide >= 600;
}

class AdaptiveApp2 extends ConsumerStatefulWidget {
  const AdaptiveApp2({super.key});

  @override
  ConsumerState<AdaptiveApp2> createState() => _AdaptiveApp2State();
}

class _AdaptiveApp2State extends ConsumerState<AdaptiveApp2> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only create the GoRouter once. We use `isTablet(context)` here
    // but do not re-create the router on subsequent rebuilds.
    if (_router == null) {
      // Get initial home screen from settings (sync read since settings load on app start)
      final homeScreen = ref.read(homeScreenProvider);
      final initialLocation = switch (homeScreen) {
        'shopping' => '/shopping',
        'meal_plans' => '/meal_plans',
        'pantry' => '/pantry',
        _ => '/recipes',
      };
      _router = _createRouter(isTablet(context), initialLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get platform brightness as fallback
    // Use specific selector to avoid rebuilds when viewInsets changes (keyboard)
    final Brightness platformBrightness = MediaQuery.platformBrightnessOf(context);

    // Watch the theme mode setting
    final themeMode = ref.watch(appThemeModeProvider);

    // Determine effective brightness based on theme setting
    final bool isDarkMode = switch (themeMode) {
      ThemeMode.light => false,
      ThemeMode.dark => true,
      ThemeMode.system => platformBrightness == Brightness.dark,
    };

    // Safely unwrap the router we created.
    final router = _router!;

    if (Platform.isIOS) {
      // CupertinoApp doesn't have themeMode, so we manually select the theme
      return CupertinoApp.router(
        routeInformationParser: router.routeInformationParser,
        routerDelegate: router.routerDelegate,
        routeInformationProvider: router.routeInformationProvider,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          CustomCupertinoLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ja'),
        ],
        theme: isDarkMode
            ? AppTheme.cupertinoDarkTheme
            : AppTheme.cupertinoLightTheme,
        builder: (context, child) {
          return ShareSessionListener(
            child: IdentityExistsErrorListener(
              child: RestorePromptListener(
                child: GlobalStatusBarWrapper(child: child ?? const SizedBox.shrink()),
              ),
            ),
          );
        },
      );
    } else {
      // MaterialApp supports themeMode directly
      return MaterialApp.router(
        routeInformationParser: router.routeInformationParser,
        routerDelegate: router.routerDelegate,
        routeInformationProvider: router.routeInformationProvider,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          CustomCupertinoLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ja'),
        ],
        themeMode: themeMode,
        theme: AppTheme.materialLightTheme,
        darkTheme: AppTheme.materialDarkTheme,
        builder: (context, child) {
          return ShareSessionListener(
            child: IdentityExistsErrorListener(
              child: RestorePromptListener(
                child: GlobalStatusBarWrapper(child: child ?? const SizedBox.shrink()),
              ),
            ),
          );
        },
      );
    }
  }

  /// Create a [GoRouter] instance with shell routing for the bottom tabs.
  GoRouter _createRouter(bool isTablet, String initialLocation) {
    // Navigator keys for each tab's separate shell:
    // Note: Using globalRootNavigatorKey (defined at top of file) for root navigator
    final _recipesNavKey   = GlobalKey<NavigatorState>(debugLabel: 'recipesNavKey');
    final _shoppingNavKey  = GlobalKey<NavigatorState>(debugLabel: 'shoppingNavKey');
    final _mealPlansNavKey = GlobalKey<NavigatorState>(debugLabel: 'mealPlansNavKey');
    final _pantryNavKey  = GlobalKey<NavigatorState>(debugLabel: 'pantryNavKey');
    final _discoverPageShellKey = GlobalKey<MainPageShellState>(debugLabel: 'discoverPageShellKey');
    final _authPageShellKey = GlobalKey<MainPageShellState>(debugLabel: 'authPageShellKey');
    final _householdPageShellKey = GlobalKey<MainPageShellState>(debugLabel: 'householdPageShellKey');
    final _settingsPageShellKey = GlobalKey<MainPageShellState>(debugLabel: 'settingsPageShellKey');
    final _clippingsPageShellKey = GlobalKey<MainPageShellState>(debugLabel: 'clippingsPageShellKey');

    final nonTabRoutes = [
      // ─────────────────────────────────────────────────────────────
      // Discover (no bottom nav)
      // ─────────────────────────────────────────────────────────────
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
                    key: _discoverPageShellKey,
                    child: child,
                    showBottomNavBar: false,
                  ),
                ),
          );
        },
        routes: [
          GoRoute(
            path: '/discover',
            pageBuilder: (context, state) => _platformPage(
              state: state,
              child: DiscoverPage(
                onMenuPressed: () {
                  _discoverPageShellKey.currentState?.toggleDrawer();
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
                    key: _authPageShellKey,
                    child: child,
                    showBottomNavBar: false,
                  ),
                ),
          );
        },
        routes: [
          GoRoute(
            path: '/auth',
            routes: [
              GoRoute(
                path: 'signin',
                pageBuilder: (context, state) => _platformPage(
                  state: state,
                  child: const SignInPage(),
                ),
              ),
              GoRoute(
                path: 'signup',
                pageBuilder: (context, state) => _platformPage(
                  state: state,
                  child: const SignUpPage(),
                ),
              ),
              GoRoute(
                path: 'forgot-password',
                pageBuilder: (context, state) => _platformPage(
                  state: state,
                  child: const ForgotPasswordPage(),
                ),
              ),
            ],
            pageBuilder: (context, state) => _platformPage(
              state: state,
              child: AuthLandingPage(
                onMenuPressed: () {
                  _authPageShellKey.currentState?.toggleDrawer();
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
                    key: _settingsPageShellKey,
                    child: child,
                    showBottomNavBar: false,
                  ),
                ),
          );
        },
        routes: [
          GoRoute(
            path: '/settings',
            routes: [
              // Manage Tags
              GoRoute(
                path: 'tags',
                pageBuilder: (context, state) => _platformPage(
                  state: state,
                  child: const ManageTagsPage(),
                ),
              ),
              // Home Screen selection
              GoRoute(
                path: 'home-screen',
                pageBuilder: (context, state) => _platformPage(
                  state: state,
                  child: const HomeScreenPage(),
                ),
              ),
              // Layout & Appearance sub-page
              GoRoute(
                path: 'layout-appearance',
                routes: [
                  GoRoute(
                    path: 'show-folders',
                    pageBuilder: (context, state) => _platformPage(
                      state: state,
                      child: const ShowFoldersPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'sort-folders',
                    pageBuilder: (context, state) => _platformPage(
                      state: state,
                      child: const SortFoldersPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'theme',
                    pageBuilder: (context, state) => _platformPage(
                      state: state,
                      child: const ThemeModePage(),
                    ),
                  ),
                  GoRoute(
                    path: 'font-size',
                    pageBuilder: (context, state) => _platformPage(
                      state: state,
                      child: const RecipeFontSizePage(),
                    ),
                  ),
                ],
                pageBuilder: (context, state) => _platformPage(
                  state: state,
                  child: const LayoutAppearancePage(),
                ),
              ),
              // Account placeholder
              GoRoute(
                path: 'account',
                pageBuilder: (context, state) => _platformPage(
                  state: state,
                  child: const AccountPage(),
                ),
              ),
              // Import/Export
              GoRoute(
                path: 'import',
                routes: [
                  GoRoute(
                    path: 'preview',
                    pageBuilder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      final filePath = extra?['filePath'] as String? ?? '';
                      final source = extra?['source'] as String? ?? 'stockpot';
                      return _platformPage(
                        state: state,
                        child: ImportPreviewPage(
                          filePath: filePath,
                          source: ImportSource.values.byName(source),
                        ),
                      );
                    },
                  ),
                ],
                pageBuilder: (context, state) => _platformPage(
                  state: state,
                  child: const ImportPage(),
                ),
              ),
              GoRoute(
                path: 'export',
                pageBuilder: (context, state) => _platformPage(
                  state: state,
                  child: const ExportPage(),
                ),
              ),
              // Help/Support placeholders
              GoRoute(
                path: 'help',
                pageBuilder: (context, state) => _platformPage(
                  state: state,
                  child: const HelpPage(),
                ),
              ),
              GoRoute(
                path: 'support',
                pageBuilder: (context, state) => _platformPage(
                  state: state,
                  child: const SupportPage(),
                ),
              ),
              // Legal placeholders
              GoRoute(
                path: 'privacy',
                pageBuilder: (context, state) => _platformPage(
                  state: state,
                  child: const PrivacyPolicyPage(),
                ),
              ),
              GoRoute(
                path: 'terms',
                pageBuilder: (context, state) => _platformPage(
                  state: state,
                  child: const TermsOfUsePage(),
                ),
              ),
              GoRoute(
                path: 'acknowledgements',
                pageBuilder: (context, state) => _platformPage(
                  state: state,
                  child: const AcknowledgementsPage(),
                ),
              ),
            ],
            pageBuilder: (context, state) => _platformPage(
              state: state,
              child: SettingsPage(
                onMenuPressed: () {
                  _settingsPageShellKey.currentState?.toggleDrawer();
                },
              ),
            ),
          ),
        ],
      ),
      // ─────────────────────────────────────────────────────────────
      // Clippings (no bottom nav)
      // ─────────────────────────────────────────────────────────────
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
                    key: _clippingsPageShellKey,
                    child: child,
                    showBottomNavBar: false,
                  ),
                ),
          );
        },
        routes: [
          GoRoute(
            path: '/clippings',
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _platformPage(
                  state: state,
                  child: ClippingEditorPage(
                    clippingId: state.pathParameters['id']!,
                  ),
                ),
              ),
            ],
            pageBuilder: (context, state) => _platformPage(
              state: state,
              child: ClippingsTab(
                onMenuPressed: () {
                  _clippingsPageShellKey.currentState?.toggleDrawer();
                },
              ),
            ),
          ),
        ],
      ),
    ];

    return GoRouter(
      debugLogDiagnostics: true,
      initialLocation: initialLocation,
      navigatorKey: globalRootNavigatorKey,
      // Handle auth callback deep links - Supabase processes the token internally
      // We just need to prevent GoRouter from throwing a "no route" error
      redirect: (context, state) {
        final path = state.uri.path;
        // Ignore auth callback URLs - Supabase handles these via app_links
        if (path == '/auth-callback' || path == '/auth-callback/') {
          return null; // Stay on current page, don't navigate
        }
        return null;
      },
      onException: (context, state, router) {
        // If the exception is for an auth callback URL, ignore it
        final path = state.uri.path;
        if (path == '/auth-callback' || path == '/auth-callback/') {
          return; // Supabase handles this internally
        }
        // For other exceptions, navigate to home
        router.go('/recipes');
      },
      routes: [
        // Auth callback route - Supabase handles the token via app_links
        // This route exists just to prevent "no route found" errors
        // It immediately redirects back to recipes (Supabase already processed the token)
        GoRoute(
          path: '/auth-callback',
          redirect: (context, state) => '/recipes',
        ),
        GoRoute(
            path: '/add_folder',
            pageBuilder: (context, state) => buildAdaptiveSheetPage<void>(
              child: Container(child:Text("hello world")),
              context: context,
              state: state
            )
        ),
        // Full-screen recipe detail route (outside shell, no bottom nav)
        GoRoute(
          path: '/recipe/:recipeId',
          pageBuilder: (context, state) {
            final recipeId = state.pathParameters['recipeId'];
            String previousPageTitle = 'Recipes';

            // Handle different types of extra data more safely
            if (state.extra != null) {
              if (state.extra is Map<String, String>) {
                previousPageTitle = (state.extra as Map<String, String>)['previousPageTitle'] ?? 'Recipes';
              } else if (state.extra is Map<String, dynamic>) {
                final extraData = state.extra as Map<String, dynamic>;
                previousPageTitle = extraData['previousPageTitle']?.toString() ?? 'Recipes';
              }
            }

            return _platformPage(
              state: state,
              child: RecipePage(recipeId: recipeId!, previousPageTitle: previousPageTitle),
            );
          },
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
                    GoRoute(
                      path: 'pinned',
                      pageBuilder: (context, state) => _platformPage(
                        state: state,
                        child: const PinnedRecipesPage(),
                      ),
                    ),
                    GoRoute(
                      path: 'recent',
                      pageBuilder: (context, state) => _platformPage(
                        state: state,
                        child: const RecentlyViewedPage(),
                      ),
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
