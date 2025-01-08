import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/svg.dart';

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
      return const CupertinoApp(
        // Provide these for Material widgets
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en', ''),
        ],
        theme: CupertinoThemeData(
          primaryColor: CupertinoColors.systemBlue,
        ),
        home: MainPage(),
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

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int _selectedTab = 1;
  bool _isDrawerOpen = false;

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
    const RecipesPage(title: 'Recipes'),
    const ShoppingListPage(title: 'Shopping List'),
    const MealPlanPage(title: 'Meal Plan'),
    const DiscoverPage(title: 'Discover'),
  ];

  @override
  void initState() {
    super.initState();

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
      duration: const Duration(milliseconds: 200),
    );
    _tabletSidebarAnimation = CurvedAnimation(
      parent: _tabletSidebarController,
      curve: Curves.easeOutQuad,
      reverseCurve: Curves.easeInQuad,
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
      _tabletSidebarController.forward();   // 0 -> 1
    } else {
      _tabletSidebarController.reverse();   // 1 -> 0
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

  /// Bottom nav only, no top AppBar on phone
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
          return CupertinoTabView(
            builder: (_) => _tabs[index],
          );
        },
      );
    } else {
      return Scaffold(
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
    const double sidebarWidth = 250.0;

    return SafeArea(
      child: Stack(
        children: [
          // 1) The sidebar: Fixed width, slides in/out via translate
          AnimatedBuilder(
            animation: _tabletSidebarAnimation, // 0..1
            builder: (context, child) {
              final fraction = _tabletSidebarAnimation.value;

              // Sidebar slides from x=-250 (hidden) to x=0 (fully visible)
              final double offsetX = -sidebarWidth * (1 - fraction);

              return Transform.translate(
                offset: Offset(offsetX, 0),
                child: child,
              );
            },
            child: Material(
              color: CupertinoColors.systemGrey6,
              child: SizedBox(
                width: sidebarWidth,
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
                  onClose: _toggleSidebar,
                ),
              ),
            ),
          ),

          // 2) Main content: Adjusts its left position as sidebar slides
          AnimatedBuilder(
            animation: _tabletSidebarAnimation, // 0..1
            builder: (context, child) {
              final fraction = _tabletSidebarAnimation.value;

              // Main content's left edge moves from 0..250
              final double offsetX = sidebarWidth * fraction;

              return Positioned(
                left: offsetX,
                right: 0, // Full width minus left offset
                top: 0,
                bottom: 0,
                child: child!,
              );
            },
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                title: Text(_titleForTab(_selectedTab)),
              ),
              body: _tabs[_selectedTab],
            ),
          ),

          // 3) Static toggle button pinned at top-left of the screen
          Positioned(
            top: 8,
            left: 16,
            child: GestureDetector(
              onTap: _toggleSidebar,
              child: SvgPicture.asset("assets/images/sidebar.svg"),
            ),
          ),
        ],
      ),
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
