import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../pages/discover.dart';
import '../pages/meal_plan.dart';
import '../pages/recipes.dart';
import '../pages/shopping_list.dart';

class MoreMenu extends StatelessWidget {
  final void Function(Widget route) onSelect;
  final VoidCallback onClose;

  const MoreMenu({
    super.key,
    required this.onSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // No CupertinoNavigationBar => custom row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(CupertinoIcons.clear,
                      color: Colors.black87),
                ),
                const SizedBox(width: 16),
                const Text('More', style: TextStyle(fontSize: 20)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: const Text('Recipes'),
                  onTap: () => onSelect(const RecipesPage(title: 'Recipes')),
                ),
                ListTile(
                  title: const Text('Shopping List'),
                  onTap: () => onSelect(
                    const ShoppingListPage(title: 'Shopping List'),
                  ),
                ),
                ListTile(
                  title: const Text('Meal Plans'),
                  onTap: () => onSelect(
                    const MealPlanPage(title: 'Meal Plans'),
                  ),
                ),
                ListTile(
                  title: const Text('Discover'),
                  onTap: () => onSelect(
                    const DiscoverPage(title: 'Discover'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
