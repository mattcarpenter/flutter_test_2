import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:recipe_app/src/features/recipes/widgets/recipe_tile.dart';

class Recipe {
  final String name;
  final String time;
  final String difficulty;

  Recipe({
    required this.name,
    required this.time,
    required this.difficulty,
  });
}

final List<Recipe> dummyRecipes = [
  Recipe(name: 'Spaghetti Bolognese', time: '45 mins', difficulty: 'Medium'),
  Recipe(name: 'Chicken Curry', time: '60 mins', difficulty: 'Hard'),
  Recipe(name: 'Grilled Cheese', time: '15 mins', difficulty: 'Easy'),
  Recipe(name: 'Caesar Salad', time: '20 mins', difficulty: 'Easy'),
  Recipe(name: 'Beef Stroganoff', time: '50 mins', difficulty: 'Medium'),
  Recipe(name: 'Vegetable Stir Fry', time: '30 mins', difficulty: 'Easy'),
];

class RecipesList extends StatelessWidget {
  final List<Recipe> recipes;

  const RecipesList({Key? key, required this.recipes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        double maxCrossAxisExtent;

        if (availableWidth < 300) {
          maxCrossAxisExtent = 300;
        } else if (availableWidth < 500) {
          // For narrow screens (e.g. typical iPhone), use a max extent that yields 2 columns.
          maxCrossAxisExtent = 190;
        } else if (availableWidth < 768) {
          // For a half‑iPad view, choose a max extent so that you get 3 columns.
          maxCrossAxisExtent = 200;
        } else {
          // For full iPad width, lower the max extent to squeeze in more columns.
          maxCrossAxisExtent = 160;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxCrossAxisExtent,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return RecipeTile(recipe: recipe);
          },
        );
      },
    );
  }
}


