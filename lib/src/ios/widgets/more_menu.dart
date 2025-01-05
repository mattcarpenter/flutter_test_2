import 'package:flutter/cupertino.dart';

import '../pages/discover.dart';
import '../pages/meal_plan.dart';
import '../pages/recipes.dart';
import '../pages/shopping_list.dart';

class MoreMenu extends StatelessWidget {
  final void Function(Widget route) onSelect;
  final VoidCallback onClose;

  const MoreMenu({super.key, required this.onSelect, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoNavigationBar(
          middle: const Text('More'),
          leading: GestureDetector(
            onTap: onClose,
            child: const Icon(CupertinoIcons.clear),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              CupertinoListTile(
                title: const Text('Recipes'),
                onTap: () => onSelect(const RecipesPage(title:'Recipes')),
              ),
              CupertinoListTile(
                title: const Text('Shopping List'),
                onTap: () => onSelect(const ShoppingListPage(title:'Shopping List')),
              ),
              CupertinoListTile(
                title: const Text('Meal Plans'),
                onTap: () => onSelect(const MealPlanPage(title: 'Meal Plans')),
              ),
              CupertinoListTile(
                title: const Text('Discover'),
                onTap: () => onSelect(const DiscoverPage(title:'Discover')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
