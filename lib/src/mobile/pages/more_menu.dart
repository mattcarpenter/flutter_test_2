import 'package:flutter/cupertino.dart';
import 'package:flutter_test_2/src/mobile/pages/pantry_page.dart';
import 'package:flutter_test_2/src/mobile/pages/recipes.dart';
import 'package:flutter_test_2/src/mobile/pages/shopping_list.dart';
import 'package:flutter_test_2/src/mobile/pages/menus_page.dart';

import 'meal_plan.dart';

class MoreMenuPage extends StatelessWidget {
  const MoreMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('More'),
      ),
      child: ListView(
        children: [
          CupertinoListTile(
            title: const Text('Recipes'),
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const RecipesPage(title: 'Recipes'),
                ),
              );
            },
          ),
          CupertinoListTile(
            title: const Text('Shopping List'),
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const ShoppingListPage(title: 'Shopping List'),
                ),
              );
            },
          ),
          CupertinoListTile(
            title: const Text('Pantry'),
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const PantryPage(title: 'Pantry'),
                ),
              );
            },
          ),
          CupertinoListTile(
            title: const Text('Menus'),
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const MenusPage(title: 'Menus'),
                ),
              );
            },
          ),
          CupertinoListTile(
            title: const Text('Meal Plans'),
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const MealPlanPage(title: 'Meal Plans'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
