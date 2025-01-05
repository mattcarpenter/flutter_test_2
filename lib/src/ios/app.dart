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
  int _selectedTab = 1; // Default to Recipes
  bool _isDrawerOpen = false;
  late AnimationController _drawerController;

  final List<Widget> _tabs = [
    const SizedBox(), // Placeholder for drawer
    const RecipesPage(title: 'Recipes'),
    const ShoppingListPage(title: 'Shopping List'),
    const MealPlanPage(title: 'Meal Plan'),
    const DiscoverPage(title: 'Discover'),
  ];

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double drawerWidth = screenWidth > 400 ? 400 : screenWidth * 0.8;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // Main App Content
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: _isDrawerOpen ? drawerWidth : 0,
            right: _isDrawerOpen ? -drawerWidth : 0,
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
          // Drawer
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: drawerWidth,
            child: Material(
              color: CupertinoColors.systemGrey6, // Background color for drawer
              child: MoreMenu(
                onSelect: (route) {
                  if (route == 'Recipes') {
                    _switchToTab(1); // Switch to Recipes tab
                  } else if (route == 'Shopping List') {
                    _switchToTab(2); // Switch to Shopping List tab
                  } else {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => route,
                      ),
                    );
                  }
                },
                onClose: _closeDrawer,
              ),
            ),
          ),
          // Gesture Detector to close drawer
          if (_isDrawerOpen)
            GestureDetector(
              onTap: _closeDrawer,
              child: Container(
                color: Colors.black54.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }
}


