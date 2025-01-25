import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cupertino_sidebar/cupertino_sidebar.dart';
import 'package:flutter_test_2/src/widgets/menu/menu.dart';
import 'package:go_router/go_router.dart';

bool isTablet(BuildContext context) {
  return MediaQuery.of(context).size.shortestSide >= 600;
}

class MainPageShell extends StatefulWidget {
  final Widget child; // The active tab's child from the GoRouter
  final bool showBottomNavBar;

  const MainPageShell({super.key, required this.child, this.showBottomNavBar = true});

  @override
  State<MainPageShell> createState() => MainPageShellState();
}

class MainPageShellState extends State<MainPageShell> with TickerProviderStateMixin {
  bool _isDrawerOpen = false;
  late AnimationController _drawerController;
  late Animation<double> _animation;
  late Animation<double> _overlayAnimation;

  bool _isSidebarVisible = true;
  late AnimationController _tabletSidebarController;
  late Animation<double> _tabletSidebarAnimation;

  @override
  void initState() {
    super.initState();

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
    _tabletSidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _tabletSidebarAnimation = CurvedAnimation(
      parent: _tabletSidebarController,
      curve: Curves.easeOutExpo,
      reverseCurve: Curves.easeInExpo,
    );
    _tabletSidebarController.value = _isSidebarVisible ? 1.0 : 0.0;
  }

  @override
  void dispose() {
    _drawerController.dispose();
    _tabletSidebarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isTablet(context)
        ? _buildTabletLayout(context)
        : _buildPhoneLayout(context);
  }

  // --------------------------------------------------------------------------
  // PHONE LAYOUT
  // --------------------------------------------------------------------------
  Widget _buildPhoneLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final drawerWidth = width > 300 ? 300.0 : width * 0.8;
    final Color backgroundColor = CupertinoColors.systemBackground.resolveFrom(context);

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
              child: Scaffold(
                body: widget.child, // The content from go_router
                bottomNavigationBar: widget.showBottomNavBar ? _buildPhoneBottomNavBar(context) : null,
              ),
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
                color: backgroundColor,
                child: SafeArea(
                  child: Menu(
                    selectedIndex: _selectedIndexFromLocation(),
                    onMenuItemClick: (index) {
                      _switchToTab(context, index);
                    },
                    onRouteGo: (route) {
                      context.go(route);
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhoneBottomNavBar(BuildContext context) {
    final isIos = Platform.isIOS;

    if (isIos) {
      return CupertinoTabBar(
        currentIndex: _selectedIndexFromLocation(),
        onTap: (index) {
          if (index == 0) {
            _toggleDrawer();
          } else {
            _switchToTab(context, index);
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
      );
    } else {
      return BottomNavigationBar(
        currentIndex: _selectedIndexFromLocation(),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) {
            _toggleDrawer();
          } else {
            _switchToTab(context, index);
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

  void toggleDrawer() {
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

  // --------------------------------------------------------------------------
  // TABLET LAYOUT
  // --------------------------------------------------------------------------
  Widget _buildTabletLayout(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Row(
            children: [
              // Sidebar
              CupertinoSidebarCollapsible(
                isExpanded: _isSidebarVisible,
                child: CupertinoSidebar(
                  selectedIndex: _selectedIndexFromLocation(),
                  onDestinationSelected: (index) {
                    _switchToTab(context, index);
                  },
                  children: [
                    const SizedBox(height: 50),
                    Menu(
                      selectedIndex: _selectedIndexFromLocation(),
                      onMenuItemClick: (index) => _switchToTab(context, index),
                      onRouteGo: (route) => context.go(route),
                    ),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: widget.child, // The content from go_router
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
                    _isSidebarVisible = !_isSidebarVisible;
                    if (_isSidebarVisible) {
                      _tabletSidebarController.forward();
                    } else {
                      _tabletSidebarController.reverse();
                    }
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

  // --------------------------------------------------------------------------
  // NAVIGATION HELPERS
  // --------------------------------------------------------------------------
  int _selectedIndexFromLocation() {
    final location = GoRouterState.of(context).uri.path; // Map location => index
    // e.g. /recipes => 1, /shopping => 2, /meal_plan => 3, /discover => 4
    if (location.startsWith('/recipes')) return 1;
    if (location.startsWith('/shopping')) return 2;
    if (location.startsWith('/meal_plan')) return 3;
    if (location.startsWith('/discover')) return 4;
    if (location.startsWith('/labs')) return 5;
    return 1; // Default to recipes if unknown
  }

  void _switchToTab(BuildContext context, int index) {
    _closeDrawer();
    switch (index) {
      case 0:
      // 'More' => toggle the drawer
        _toggleDrawer();
        break;
      case 1:
        context.go('/recipes');
        break;
      case 2:
        context.go('/shopping');
        break;
      case 3:
        context.go('/meal_plans');
        break;
      case 4:
        context.go('/discover');
        break;
    }
  }
}
