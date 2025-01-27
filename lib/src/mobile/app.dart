import 'dart:io' show Platform;
import 'package:cupertino_sidebar/cupertino_sidebar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../color_theme.dart';
import '../features/discover/views/discover_root.dart';
import '../features/meal_plans/views/meal_plans_root.dart';
import '../features/recipes/views/recipes_root.dart';
import '../features/shopping_list/views/shopping_list_root.dart';
import '../widgets/menu/menu.dart';

bool isTablet(BuildContext context) {
  return MediaQuery.of(context).size.shortestSide >= 600;
}

class AdaptiveApp extends StatelessWidget {
  const AdaptiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final bool isDarkMode = brightness == Brightness.dark;

    if (Platform.isIOS) {
      return CupertinoApp(
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
        home: const MainPage(),
      );
    } else {
      return MaterialApp(
        theme: isDarkMode
            ? AppTheme.materialDarkTheme
            : AppTheme.materialLightTheme,
        home: Scaffold(
          appBar: AppBar(
            title: Text('App Title'),
          ),
          body: MainPage(),
        ),
      );
    }
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int _selectedTab = 1;
  bool _isDrawerOpen = false;
  bool isExpanded = true;

  final GlobalKey<NavigatorState> _nestedNavigatorKey =
      GlobalKey<NavigatorState>();

  // Phone drawer animations
  late AnimationController _drawerController;
  late Animation<double> _animation;
  late Animation<double> _overlayAnimation;

  // iOS bottom nav
  CupertinoTabController? _iosTabController;

  // Whether the sidebar is logically "open" or "closed" on tablet
  bool _isSidebarVisible = true;

  // Tablet sidebar animation (0 => hidden, 1 => fully visible)
  late AnimationController _tabletSidebarController;
  late Animation<double> _tabletSidebarAnimation;

  final List<Widget> _tabs = [
    const SizedBox(),
    const RecipesTab(),
    const ShoppingListTab(),
    const MealPlansRoot(),
    const DiscoverTab(),
  ];

  late final List<GlobalKey<NavigatorState>> _androidNavigatorKeys;

  @override
  void initState() {
    super.initState();

    _androidNavigatorKeys =
        List.generate(5, (_) => GlobalKey<NavigatorState>());

    // iOS phone => "More" does not become the active tab
    if (Platform.isIOS) {
      _iosTabController = CupertinoTabController(initialIndex: _selectedTab)
        ..addListener(() {
          final newIndex = _iosTabController!.index;
          if (newIndex == 0) {
            _iosTabController!.index = _selectedTab;
            _toggleDrawer();
          } else {
            _switchToTab(newIndex);
          }
        });
    }

    // Phone drawer animations
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeOutQuad,
      reverseCurve: Curves.easeInQuad,
    );
    _overlayAnimation = CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _drawerController.value = 0.0;
    _isDrawerOpen = false;

    // Tablet sidebar animation
    // Will animate from width=0 to width=250
    _tabletSidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _tabletSidebarAnimation = CurvedAnimation(
      parent: _tabletSidebarController,
      curve: Curves.easeOutExpo,
      reverseCurve: Curves.easeInExpo,
    );
    // Initialize to 1.0 if we want it open initially
    _tabletSidebarController.value = _isSidebarVisible ? 1.0 : 0.0;
  }

  @override
  void dispose() {
    _drawerController.dispose();
    _iosTabController?.dispose();

    // Tablet
    _tabletSidebarController.dispose();

    super.dispose();
  }

  // --------------------------------------------------------------------------
  // PHONE: Drawer logic
  // --------------------------------------------------------------------------
  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
      if (_isDrawerOpen) {
        _drawerController.forward();
      } else {
        _drawerController.reverse();
      }
    });
  }

  void _closeDrawer() {
    if (_isDrawerOpen) {
      setState(() {
        _isDrawerOpen = false;
        _drawerController.reverse();
      });
    }
  }

  // Switch tabs
  void _switchToTab(int index) {
    if (_selectedTab == index && !Platform.isIOS) {
      // Pop the navigation stack to the root of the current tab
      _androidNavigatorKeys[index]
          .currentState
          ?.popUntil((route) => route.isFirst);
      _closeDrawer();
      return; // No need to update _selectedTab, as it's already active
    }

    setState(() {
      _selectedTab = index;
    });
    _iosTabController?.index = index;

    _closeDrawer();
  }

  // --------------------------------------------------------------------------
  // TABLET: Show/hide the sidebar with animation
  // --------------------------------------------------------------------------
  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
    if (_isSidebarVisible) {
      _tabletSidebarController.forward(); // 0 -> 1
    } else {
      _tabletSidebarController.reverse(); // 1 -> 0
    }
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // If tablet => animate sidebar
    // If phone => normal drawer
    return isTablet(context)
        ? _buildTabletLayout(context)
        : _buildPhoneLayout(context);
  }

  // --------------------------------------------------------------------------
  // PHONE LAYOUT (no top AppBar, bottom nav only)
  // --------------------------------------------------------------------------
  Widget _buildPhoneLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final drawerWidth = width > 300 ? 300.0 : width * 0.8;
    final Color backgroundColor =
        CupertinoColors.systemBackground.resolveFrom(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final slide = drawerWidth * _animation.value;
        final overlayOpacity = 0.5 * _overlayAnimation.value;

        return Stack(
          children: [
            // 1) Main content
            Positioned(
              left: slide,
              right: -slide,
              top: 0,
              bottom: 0,
              child: _buildPhoneMainContent(context),
            ),

            // 2) Overlay
            if (overlayOpacity > 0)
              Positioned(
                left: slide,
                right: -slide,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _closeDrawer,
                  child: Container(
                    color: Colors.black54.withOpacity(overlayOpacity),
                  ),
                ),
              ),

            // 3) Drawer
            Positioned(
              left: -drawerWidth + slide,
              top: 0,
              bottom: 0,
              width: drawerWidth,
              child: Material(
                color: backgroundColor, //CupertinoColors.systemGrey6,
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: Menu(
                            selectedIndex: _selectedTab,
                            onMenuItemClick: (index) {
                              _switchToTab(index);
                            },
                            onRouteGo: (_) {}
                        ),
                      )
                    ],
                  ),
                ),

                /*MoreMenu(
                  onSelect: (route) {
                    if (route is RecipesPage) {
                      _switchToTab(1);
                    } else if (route is ShoppingListPage) {
                      _switchToTab(2);
                    } else if (route is MealPlanPage) {
                      _switchToTab(3);
                    } else if (route is DiscoverPage) {
                      _switchToTab(4);
                    } else {
                      if (Platform.isIOS) {
                        Navigator.of(context).push(
                          CupertinoPageRoute(builder: (_) => route),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => route),
                        );
                      }
                    }
                  },
                  onClose: _closeDrawer,
                ),*/
              ),
            ),
          ],
        );
      },
    );
  }

  /// Bottom nav only, no top AppBar on phone
  /// Bottom nav only, no top AppBar on phone
  Widget _buildPhoneMainContent(BuildContext context) {
    if (Platform.isIOS) {
      // iOS is unchanged: uses CupertinoTabScaffold
      return CupertinoTabScaffold(
        controller: _iosTabController,
        tabBar: CupertinoTabBar(
          currentIndex: _selectedTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.bars),
              label: 'More',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.book),
              label: 'Recipes',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.cart),
              label: 'Shopping',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.calendar),
              label: 'Meal Plan',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.home),
              label: 'Discover',
            ),
          ],
        ),
        tabBuilder: (context, index) {
          return CupertinoTabView(builder: (BuildContext context) {
            return _tabs[index];
          });
        },
      );
    } else {
      // ANDROID: Use an IndexedStack of nested Navigators for each tab.
      return Scaffold(
        // The body is now an IndexedStack instead of just `_tabs[_selectedTab]`.
        body: IndexedStack(
          index: _selectedTab,
          children: [
            // 0 => "More" (drawer trigger). We never actually display this,
            //      so just use an empty Container.
            Container(),

            // 1 => Recipes
            _buildTabNavigator(1),

            // 2 => Shopping
            _buildTabNavigator(2),

            // 3 => Meal Plan
            _buildTabNavigator(3),

            // 4 => Discover
            _buildTabNavigator(4),
          ],
        ),

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedTab,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 0) {
              // "More" => toggle the drawer
              _toggleDrawer();
            } else {
              // Switch to that tab
              _switchToTab(index);
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              label: 'More',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: 'Recipes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Shopping',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Meal Plan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Discover',
            ),
          ],
        ),
      );
    }
  }

  /// TABLET LAYOUT:
  /// Animated left column from 0..250 px, main content in the rest.
  /// A top-level Stack is used only for the toggle button.
  /// A tablet layout where:
  /// - The sidebar slides in from offscreen (no text reflow in the sidebar).
  /// - The main content transforms (offset and/or scale) so it “shrinks”
  ///   but does NOT reflow text.
  /// Build the tablet layout so the sidebar "slides in" from offscreen
  /// (width 0..250) and physically shrinks the main content area by that same amount.
  /// There's no scaling of the main content's height or text — it's a real reflow of width.
  /// Build the tablet layout where:
  /// - Sidebar is fixed at 250px but slides offscreen via Transform.translate.
  /// - Main content adjusts its left edge via Positioned offset.
  Widget _buildTabletLayout(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Row(
            children: [
              // Sidebar
              CupertinoSidebarCollapsible(
                isExpanded: isExpanded,
                child: CupertinoSidebar(
                  selectedIndex: _selectedTab,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedTab = index; // Switch to that top-level page
                    });
                  },
                  children: [
                    const SizedBox(height: 50),
                    Menu(
                      onRouteGo: (_) {},
                      selectedIndex: _selectedTab,
                      onMenuItemClick: (index) {
                        _switchToTab(index);
                      },
                    ),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: Platform.isAndroid
                    ? IndexedStack(
                        index: _selectedTab,
                        children: List.generate(
                          _tabs.length,
                          (index) => Navigator(
                            key: _androidNavigatorKeys[index],
                            onGenerateRoute: (settings) {
                              if (settings.name == '/') {
                                return MaterialPageRoute(
                                  builder: (_) => _tabs[index],
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                      )
                    : Center(
                        child: CupertinoTabTransitionBuilder(
                          child: _tabs[_selectedTab],
                        ),
                      ),
              ),
            ],
          ),
          // Toggle Sidebar Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    isExpanded = !isExpanded; // Toggle the sidebar
                  });
                },
                child: const Icon(CupertinoIcons.sidebar_left),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTab(int index) {
    setState(() {
      _selectedTab = index; // Update the selected tab index
    });

    // Map index to routes
    final Map<int, String> routes = {
      0: '/recipes',
      1: '/shopping',
      2: '/meal_plans',
      3: '/discover',
    };

    final String? routeName = routes[index];

    if (routeName != null) {
      // Use the nested navigator key to push the route
      _nestedNavigatorKey.currentState?.pushNamedAndRemoveUntil(
        routeName,
        (Route<dynamic> route) => false, // Remove all routes
      );
    }
  }

  Widget _buildTabNavigator(int index) {
    return Navigator(
      key: _androidNavigatorKeys[index],
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          // The default/initial route for this tab is _tabs[index].
          return MaterialPageRoute(
            builder: (_) => _tabs[index],
            settings: settings,
          );
        }
        // If you have any sub-routes, handle them here:
        // if (settings.name == '/details') { ... }
        return null;
      },
    );
  }

  // Title for the AppBar
  String _titleForTab(int index) {
    switch (index) {
      case 1:
        return 'Recipes';
      case 2:
        return 'Shopping List';
      case 3:
        return 'Meal Plan';
      case 4:
        return 'Discover';
      default:
        return 'My App';
    }
  }
}
