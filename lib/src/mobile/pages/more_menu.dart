import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_2/src/mobile/pages/pantry_page.dart';
import 'package:flutter_test_2/src/mobile/pages/recipes.dart';
import 'package:flutter_test_2/src/mobile/pages/shopping_list.dart';
import 'package:flutter_test_2/src/mobile/pages/menus_page.dart';

import 'meal_plan.dart';

class MoreMenuPage extends StatelessWidget {
  const MoreMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Current active route for the active state (placeholder logic).
    final activeRoute = ModalRoute.of(context)?.settings.name;

    // Helper to determine if the current menu item is active.
    bool isActive(String routeName) => activeRoute == routeName;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('More2'),
      ),
      child: ListView(
        children: [
          // Navigation group header
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Text(
              'Navigation',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          // Navigation buttons
          _buildNavItem(
            context,
            icon: Icons.book,
            title: 'Recipes',
            routeName: '/recipes',
            isActive: isActive('/recipes'),
            destination: const RecipesPage(title: 'Recipes'),
          ),
          _buildNavItem(
            context,
            icon: Icons.shopping_cart,
            title: 'Shopping List',
            routeName: '/shopping-list',
            isActive: isActive('/shopping-list'),
            destination: const ShoppingListPage(title: 'Shopping List'),
          ),
          _buildNavItem(
            context,
            icon: Icons.kitchen,
            title: 'Pantry',
            routeName: '/pantry',
            isActive: isActive('/pantry'),
            destination: const PantryPage(title: 'Pantry'),
          ),
          _buildNavItem(
            context,
            icon: Icons.menu_book,
            title: 'Menus',
            routeName: '/menus',
            isActive: isActive('/menus'),
            destination: const MenusPage(title: 'Menus'),
          ),
          _buildNavItem(
            context,
            icon: Icons.calendar_today,
            title: 'Meal Plans',
            routeName: '/meal-plans',
            isActive: isActive('/meal-plans'),
            destination: const MealPlanPage(title: 'Meal Plans'),
          ),
          // Divider between groups
          const Divider(height: 32.0, thickness: 1.0),
          // Tree view group header
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Text(
              'Recipe Folders',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          // Tree view placeholder
          _buildTreeItem('Folder 1'),
          _buildTreeItem('Folder 2'),
          _buildTreeItem('Folder 3'),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String routeName,
        required Widget destination,
        required bool isActive,
      }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => destination),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF5F5F5) : Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFFD62828),
            ),
            const SizedBox(width: 16.0),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeItem(String folderName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Icon(
            Icons.folder,
            color: Color(0xFFD62828),
          ),
          const SizedBox(width: 16.0),
          Text(
            folderName,
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
