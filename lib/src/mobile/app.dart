import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Your existing pages and widgets
import 'package:flutter_test_2/src/ios/pages/discover.dart';
import 'package:flutter_test_2/src/ios/pages/meal_plan.dart';
import 'package:flutter_test_2/src/ios/pages/recipes.dart';
import 'package:flutter_test_2/src/ios/pages/shopping_list.dart';
import 'package:flutter_test_2/src/ios/widgets/more_menu.dart';

class AdaptiveApp extends StatelessWidget {
  const AdaptiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      // iOS => Cupertino theme
      return const CupertinoApp(
        theme: CupertinoThemeData(
          primaryColor: CupertinoColors.systemBlue,
        ),
        home: MainPage(),
      );
    } else {
      // Android => Material theme
      return MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MainPage(),
      );
    }
  }
}

/// The main page that holds your custom sliding drawer logic
/// and bottom navigation, adapting between iOS and Android.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  int _selectedTab = 1; // Start on "Recipes"
  bool _isDrawerOpen = false;

  late AnimationController _drawerController;
  late Animation<double> _animation;       // slides main content & drawer
  late Animation<double> _overlayAnimation; // fades the overlay
  late CupertinoTabController? _iosTabController; // For iOS bottom nav logic

  // The tabs to show at indexes 1..4; index 0 is "More" placeholder
  final List<Widget> _tabs = [
    const SizedBox(), // index 0 => "drawer" placeholder
    const RecipesPage(title: 'Recipes'),
    const ShoppingListPage(title: 'Shopping List'),
    const MealPlanPage(title: 'Meal Plan'),
    const DiscoverPage(title: 'Discover'),
  ];

  @override
  void initState() {
    super.initState();

    // If we're on iOS, we can use a CupertinoTabController for the bottom nav
    if (Platform.isIOS) {
      _iosTabController = CupertinoTabController(initialIndex: _selectedTab)
        ..addListener(() {
          // If user taps index 0 => "More", revert to the old tab (prevent tab switch)
          if (_iosTabController!.index == 0) {
            _iosTabController!.index = _selectedTab;
          }
        });
    } else {
      // On Android, we won't use a CupertinoTabController
      _iosTabController = null;
    }

    // Drawer animation controller
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Easing curve for opening (forward) & closing (reverse)
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

    // Ensure drawer is initially closed
    _drawerController.value = 0.0;
    _isDrawerOpen = false;
  }

  @override
  void dispose() {
    _drawerController.dispose();
    _iosTabController?.dispose();
    super.dispose();
  }

  // Toggle the drawer open/closed
  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
      if (_isDrawerOpen) {
        _drawerController.forward();  // animate 0 -> 1
      } else {
        _drawerController.reverse();  // animate 1 -> 0
      }
    });
  }

  // Force the drawer closed
  void _closeDrawer() {
    if (_isDrawerOpen) {
      setState(() {
        _isDrawerOpen = false;
        _drawerController.reverse();
      });
    }
  }

  // Switch bottom tab to [index], also close the drawer
  void _switchToTab(int index) {
    setState(() {
      _selectedTab = index;
    });
    if (_iosTabController != null) {
      _iosTabController!.index = index; // For iOS
    }
    _closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    // Use the same drawer animation logic for both iOS & Android
    final width = MediaQuery.of(context).size.width;
    final drawerWidth = width > 300 ? 300.0 : width * 0.8;

    // Rebuild whenever the drawer animation changes
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final double slide = drawerWidth * _animation.value;
        final double overlayOpacity = 0.5 * _overlayAnimation.value;

        return Stack(
          children: [
            // 1) MAIN CONTENT & BOTTOM NAV
            Positioned(
              left: slide,
              right: -slide,
              top: 0,
              bottom: 0,
              child: _buildMainContent(context),
            ),

            // 2) OVERLAY that fades in/out, blocking taps when drawer is open
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

            // 3) The actual drawer sliding in
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
                    } else {
                      // If it's not one of the main tabs, push a route
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

  /// Build the main content + bottom nav differently for iOS vs. Android,
  /// but keep the same drawer logic in both cases.
  Widget _buildMainContent(BuildContext context) {
    if (Platform.isIOS) {
      // iOS => Use your existing CupertinoTabScaffold approach
      return CupertinoTabScaffold(
        controller: _iosTabController,
        tabBar: CupertinoTabBar(
          currentIndex: _selectedTab,
          onTap: (index) {
            if (index == 0) {
              // "More" => toggle drawer
              _toggleDrawer();
            } else {
              _switchToTab(index);
            }
          },
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
      // Android => Use a Material Scaffold with bottom nav
      return Scaffold(
        appBar: AppBar(
          title: Text(_titleForTab(_selectedTab)),
        ),
        body: _tabs[_selectedTab],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedTab,
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
