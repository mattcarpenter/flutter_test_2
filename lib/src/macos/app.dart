import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import '../widgets/menu/menu.dart';
import 'hello_page.dart';

class MacApp extends StatelessWidget {
  const MacApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final int _pageIndex = 0;

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {

    return MacosWindow(
      sidebar: Sidebar(
        minWidth: 200,
        builder: (context, scrollController) {
          /*return SidebarItems(
            currentIndex: _pageIndex,
            onChanged: (index) {},
            items: const [
              SidebarItem(
                leading: MacosIcon(CupertinoIcons.home),
                label: Text('Home'),
              ),
              SidebarItem(
                leading: MacosIcon(CupertinoIcons.search),
                label: Text('Explore'),
              ),
            ],
          );*/
          return Menu(selectedIndex: _selectedIndex, onMenuItemClick: (index) {
            setState(() {
              _selectedIndex = index;
            });
          });
        },
      ),
      child: const HelloPage(),
    );
  }
}
