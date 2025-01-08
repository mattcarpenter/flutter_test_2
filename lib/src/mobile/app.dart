import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_test_2/src/mobile/pages/discover.dart';
import 'package:flutter_test_2/src/mobile/pages/meal_plan.dart';
import 'package:flutter_test_2/src/mobile/pages/recipes.dart';
import 'package:flutter_test_2/src/mobile/pages/shopping_list.dart';
import 'package:flutter_test_2/src/mobile/widgets/more_menu.dart';

bool isTablet(BuildContext context) {
  return MediaQuery.of(context).size.shortestSide >= 600;
}

class AdaptiveApp extends StatelessWidget {
  const AdaptiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoApp(
        // Provide these for Material widgets
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
        ],
        theme: const CupertinoThemeData(
          primaryColor: CupertinoColors.systemBlue,
        ),
        home: const MainPage(),
      );
    } else {
      return MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.blue,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
          ),
        ),
        home: const MainPage(),
      );
    }
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  int _selectedTab = 1;
  bool _isDrawerOpen = false;

  late AnimationController _drawerController;
  late Animation<double> _animation;
  late Animation<double> _overlayAnimation;

  CupertinoTabController? _iosTabController;
  bool _isSidebarVisible = true;

  final List<Widget> _tabs = [
    const SizedBox(),
    const RecipesPage(title: 'Recipes'),
    const ShoppingListPage(title: 'Shopping List'),
    const MealPlanPage(title: 'Meal Plan'),
    const DiscoverPage(title: 'Discover'),
  ];

  @override
  void initState() {
    super.initState();

    if (Platform.isIOS) {
      // Keep the addListener approach so "More" never appears as active
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
  }

  @override
  void dispose() {
    _drawerController.dispose();
    _iosTabController?.dispose();
    super.dispose();
  }

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

  void _switchToTab(int index) {
    setState(() {
      _selectedTab = index;
    });
    _iosTabController?.index = index;
    _closeDrawer();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    // On tablets, no bottom nav, just the sidebar
    // On phones, bottom nav + no title bar
    return isTablet(context)
        ? _buildTabletLayout(context)
        : _buildPhoneLayout(context);
  }

  // --------------------------------------------------------------------------
  // PHONE LAYOUT
  // --------------------------------------------------------------------------
  // CHANGED: remove any AppBar usage; we can just show the tab bar at bottom
  Widget _buildPhoneLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final drawerWidth = width > 300 ? 300.0 : width * 0.8;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final slide = drawerWidth * _animation.value;
        final overlayOpacity = 0.5 * _overlayAnimation.value;

        return Stack(
          children: [
            // 1) MAIN CONTENT
            Positioned(
              left: slide,
              right: -slide,
              top: 0,
              bottom: 0,
              child: _buildPhoneMainContent(context),
            ),

            // 2) OVERLAY
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

            // 3) SLIDING DRAWER
            Positioned(
              left: -drawerWidth + slide,
              top: 0,
              bottom: 0,
              width: drawerWidth,
              child: Material(
                color: CupertinoColors.systemGrey6,
                child: MoreMenu(
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
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // On phone, purely the bottom nav with no app bar
  Widget _buildPhoneMainContent(BuildContext context) {
    if (Platform.isIOS) {
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
          // pages
          return CupertinoTabView(builder: (_) => _tabs[index]);
        },
      );
    } else {
      return Scaffold(
        // REMOVED APPBAR ON PHONE
        body: _tabs[_selectedTab],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedTab,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 0) {
              _toggleDrawer();
            } else {
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

  // --------------------------------------------------------------------------
  // TABLET LAYOUT
  // --------------------------------------------------------------------------
  /// Build the tablet layout with a sidebar on the left
  /// and a nested Scaffold on the right. The AppBar appears
  /// only above the main content, not over the sidebar.
  Widget _buildTabletLayout(BuildContext context) {
    return SafeArea(
      // 1) Wrap everything in a Stack
      child: Stack(
        children: [
          // 2) The main row: [ sidebar | expanded Scaffold(main content) ]
          Row(
            children: [
              // Sidebar
              if (_isSidebarVisible)
                SizedBox(
                  width: 250,
                  child: Material(
                    color: CupertinoColors.systemGrey6,
                    child: MoreMenu(
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
                      onClose: () {
                        setState(() {
                          _isSidebarVisible = false;
                        });
                      },
                    ),
                  ),
                ),

              // Main content => nested Scaffold
              Expanded(
                child: Scaffold(
                  appBar: AppBar(
                    title: Text(_titleForTab(_selectedTab)),
                  ),
                  body: _tabs[_selectedTab],
                ),
              ),
            ],
          ),

          // 3) The static show/hide button at top-left corner
          //    This button always stays in the same place,
          //    even if the sidebar is shown or hidden.
          Positioned(
            top: 16,
            left: 16,
            child: ElevatedButton(
              onPressed: _toggleSidebar,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              child: Icon(
                _isSidebarVisible ? Icons.arrow_back_ios : Icons.menu,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }


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
