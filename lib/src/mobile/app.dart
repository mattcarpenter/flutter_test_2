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
      // iOS => CupertinoApp
      return CupertinoApp(
        // Provide these delegates so Material widgets won't complain
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
      // Android => MaterialApp
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

  /// We keep the addListener approach
  CupertinoTabController? _iosTabController;

  bool _isSidebarVisible = true;

  final List<Widget> _tabs = [
    const SizedBox(), // index 0 => "More"
    const RecipesPage(title: 'Recipes'),
    const ShoppingListPage(title: 'Shopping List'),
    const MealPlanPage(title: 'Meal Plan'),
    const DiscoverPage(title: 'Discover'),
  ];

  @override
  void initState() {
    super.initState();

    if (Platform.isIOS) {
      // CHANGED: We re-enable the addListener approach so that tapping index 0 reverts
      _iosTabController = CupertinoTabController(initialIndex: _selectedTab)
        ..addListener(() {
          final newIndex = _iosTabController!.index;
          if (newIndex == 0) {
            // Tapped "More"
            _iosTabController!.index = _selectedTab; // revert to old tab
            _toggleDrawer(); // open the drawer
          } else {
            // Tapped a normal tab => switch
            _switchToTab(newIndex);
          }
        });
    } else {
      _iosTabController = null;
    }

    // Drawer animation (phone only)
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
    if (_iosTabController != null) {
      _iosTabController!.index = index;
    }
    _closeDrawer();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isTablet(context)) {
      return _buildTabletLayout(context);
    } else {
      return _buildPhoneLayout(context);
    }
  }

  // --------------------------------------------------------------------------
  // PHONE LAYOUT
  // --------------------------------------------------------------------------
  Widget _buildPhoneLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final drawerWidth = width > 300 ? 300.0 : width * 0.8;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final double slide = drawerWidth * _animation.value;
        final double overlayOpacity = 0.5 * _overlayAnimation.value;

        return Stack(
          children: [
            // main content
            Positioned(
              left: slide,
              right: -slide,
              top: 0,
              bottom: 0,
              child: _buildPhoneMainContent(context),
            ),
            // overlay
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
            // drawer sliding in
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
                      // If it's not one of the main tabs
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

  Widget _buildPhoneMainContent(BuildContext context) {
    if (Platform.isIOS) {
      // iOS => rely on CupertinoTabController addListener
      // <-- REMOVED onTap since we handle in .addListener
      return CupertinoTabScaffold(
        controller: _iosTabController,
        tabBar: CupertinoTabBar(
          currentIndex: _selectedTab,
          // no onTap for iOS => the .addListener handles all changes
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
          return CupertinoTabView(
            builder: (_) => _tabs[index],
          );
        },
      );
    } else {
      // Android => Material
      return Scaffold(
        appBar: AppBar(
          title: Text(_titleForTab(_selectedTab)),
        ),
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
  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForTab(_selectedTab)),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _toggleSidebar,
          ),
        ],
      ),
      body: Row(
        children: [
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
          Expanded(
            child: _tabs[_selectedTab],
          ),
        ],
      ),
      // If you still want a bottom nav on tablet
      bottomNavigationBar: _buildTabletBottomNav(context),
    );
  }

  Widget _buildTabletBottomNav(BuildContext context) {
    if (Platform.isIOS) {
      // (Optional) Remove ripple on iPad
      return Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedTab,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 0) {
              _toggleSidebar();
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
    } else {
      return BottomNavigationBar(
        currentIndex: _selectedTab,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) {
            _toggleSidebar();
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
      );
    }
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
