import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:recipe_app/src/features/recipes/widgets/recipe_tile.dart';

class Recipe {
  final String name;
  final String time;
  final String difficulty;
  final String imageName;

  Recipe({
    required this.name,
    required this.time,
    required this.difficulty,
    required this.imageName,
  });
}

final List<Recipe> dummyRecipes = [
  Recipe(name: 'Spaghetti Bolognese', time: '45 mins', difficulty: 'Medium', imageName: '1.png'),
  Recipe(name: 'Chicken Curry', time: '60 mins', difficulty: 'Hard', imageName: '2.png'),
  Recipe(name: 'Grilled Cheese', time: '15 mins', difficulty: 'Easy', imageName: '3.png'),
  Recipe(name: 'Caesar Salad', time: '20 mins', difficulty: 'Easy', imageName: '4.png'),
  Recipe(name: 'Beef Stroganoff', time: '50 mins', difficulty: 'Medium', imageName: '5.png'),
  Recipe(name: 'Vegetable Stir Fry', time: '30 mins', difficulty: 'Easy', imageName: '6.png'),
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
            childAspectRatio: 0.95,
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


