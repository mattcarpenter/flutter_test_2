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
    return CupertinoApp(
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.systemBlue,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  // Start on Recipes tab by default
  int _selectedTab = 1;
  bool _isDrawerOpen = false;

  late AnimationController _drawerController;

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
    _isDrawerOpen = false;
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 0.0, // 0 => closed, 1 => open
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
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
    _closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth > 400 ? 400.0 : screenWidth * 0.8;

    return CupertinoPageScaffold(
      backgroundColor: Colors.white,
      child: AnimatedBuilder(
        animation: _drawerController,
        builder: (context, _) {
          // _drawerController.value goes 0 -> 1
          // We'll interpolate positions from that.
          final double slideAmount = drawerWidth * _drawerController.value;

          return Stack(
            children: [
              // 1) Drawer, sliding from left = -drawerWidth (closed) to 0 (open)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                left: -drawerWidth + slideAmount,
                top: 0,
                bottom: 0,
                width: drawerWidth,
                child: Material(
                  color: CupertinoColors.systemGrey6,
                  child: MoreMenu(
                    onSelect: (route) {
                      // Switch to a tab if it matches, otherwise push
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

              // 2) Main content, sliding from left=0 to left=drawerWidth
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                left: slideAmount,
                right: -slideAmount,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: CupertinoTabScaffold(
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
                      currentIndex: _selectedTab,
                      onTap: (index) {
                        if (index == 0) {
                          _toggleDrawer();
                        } else {
                          _switchToTab(index);
                        }
                      },
                    ),
                    tabBuilder: (context, index) {
                      return CupertinoTabView(
                        builder: (context) => _tabs[index],
                      );
                    },
                  ),
                ),
              ),

              // 3) Dimming overlay that closes the drawer on tap
              if (_isDrawerOpen)
                GestureDetector(
                  onTap: _closeDrawer,
                  child: Container(color: Colors.black54.withOpacity(0.5)),
                ),
            ],
          );
        },
      ),
    );
  }
}
