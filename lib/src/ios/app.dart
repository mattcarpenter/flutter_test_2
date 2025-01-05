import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_2/src/ios/pages/discover.dart';
import 'package:flutter_test_2/src/ios/pages/meal_plan.dart';
import 'package:flutter_test_2/src/ios/pages/recipes.dart';
import 'package:flutter_test_2/src/ios/pages/shopping_list.dart';
import 'package:flutter_test_2/src/ios/widgets/more_menu.dart';

class IOSApp extends StatelessWidget {
  const IOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.systemBlue,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  int _selectedTab = 1; // Start on "Recipes"
  bool _isDrawerOpen = false;

  late AnimationController _drawerController;
  late Animation<double> _animation; // We'll add a curve
  late Animation<double> _overlayAnimation;
  late CupertinoTabController _tabController;

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

    _tabController = CupertinoTabController(initialIndex: _selectedTab)
    ..addListener(() {
      setState(() {
        if (_tabController.index == 0) {
          _tabController.index = _selectedTab;
        }
      });
    });

    // Faster animation: 200ms
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Apply an easing curve
    _animation = CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeOutQuad, // can try easeInOutCubic, etc.
      reverseCurve: Curves.easeInQuad
    );

    _overlayAnimation = CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn
    );

    // Make sure it's closed initially
    _drawerController.value = 0.0;
    _isDrawerOpen = false;
  }

  @override
  void dispose() {
    _drawerController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
      if (_isDrawerOpen) {
        _drawerController.forward(); // animate 0 -> 1
      } else {
        _drawerController.reverse(); // animate 1 -> 0
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
    print('Switching to tab $index');
    setState(() {
      _selectedTab = index;
    });
    _tabController.index = index; // Update the tab controller's index
    _closeDrawer(); // Close the drawer if switching tabs
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final drawerWidth = width > 300 ? 300.0 : width * 0.8;

    return CupertinoPageScaffold(
      backgroundColor: Colors.white,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          // The animation value goes from 0 (closed) to 1 (open)
          final double slide = drawerWidth * _animation.value;
          final double overlayOpacity = 0.5 * _overlayAnimation.value;

          return Stack(
            children: [
              // 1) MAIN CONTENT
              //    starts at left=0, moves to left=drawerWidth as we open
              Positioned(
                left: slide,
                right: -slide,
                top: 0,
                bottom: 0,
                child: CupertinoTabScaffold(
                  controller: _tabController,
                  tabBar: CupertinoTabBar(
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
                    currentIndex: _selectedTab, // Keep the active tab highlighted
                    onTap: (index) {
                      if (index == 0) {
                        // "More" tab tapped -> Open the drawer
                        _toggleDrawer();
                      } else {
                        // Switch to a different tab
                        _switchToTab(index);
                      }
                    },
                  ),
                  tabBuilder: (context, index) {
                    return CupertinoTabView(
                      builder: (_) => _tabs[index],
                    );
                  },
                ),
              ),

              // 2) DARK OVERLAY that sits exactly over the main content area,
              //    letting the drawer remain visible and *not* tinted.
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

              // 3) DRAWER itself
              //    starts at left = -drawerWidth, slides to left=0
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
                        Navigator.of(context).push(
                          CupertinoPageRoute(builder: (_) => route),
                        );
                      }
                    },
                    onClose: _closeDrawer,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
