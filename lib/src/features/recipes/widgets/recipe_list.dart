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

class RecipesList extends StatefulWidget {
  final List<Recipe> recipes;

  const RecipesList({Key? key, required this.recipes})
      : super(key: key);

  @override
  _RecipesListState createState() => _RecipesListState();
}

class _RecipesListState extends State<RecipesList> {
  // This holds the "stable" column count.
  int? _columnCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // Compute the new column count based on available width and current _columnCount
        final newCount = _computeHysteresisColumnCount(availableWidth);

        // Initialize _columnCount if it's not set.
        if (_columnCount == null) {
          _columnCount = newCount;
        }

        // If the new count is different, update _columnCount after the build.
        if (newCount != _columnCount) {
          // Use addPostFrameCallback to avoid calling setState during build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _columnCount = newCount;
              });
            }
          });
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columnCount!,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            // Fixed tile height that accommodates the image and text
            mainAxisExtent: _columnCount! == 2 ? 160 : 180,
          ),
          itemCount: widget.recipes.length,
          itemBuilder: (context, index) {
            final recipe = widget.recipes[index];
            return RecipeTile(recipe: recipe);
          },
        );

      },
    );
  }

  /// This method calculates the column count using hysteresis.
  /// The thresholds are defined with an upward and downward margin to prevent
  /// frequent switching when the available width hovers around a breakpoint.
  int _computeHysteresisColumnCount(double width) {
    // Define thresholds with hysteresis margins.
    const threshold1Up = 280.0;  // 1 -> 2 columns (when increasing)
    const threshold1Down = 260.0; // 2 -> 1 columns (when decreasing)
    const threshold2Up = 450.0;  // 2 -> 3 columns (when increasing)
    const threshold2Down = 430.0; // 3 -> 2 columns (when decreasing)
    const threshold3Up = 650.0;  // 3 -> 4 columns (when increasing)
    const threshold3Down = 630.0; // 4 -> 3 columns (when decreasing)
    const threshold4Up = 900.0;  // 4 -> 5 columns (new breakpoint for tablets)
    const threshold4Down = 880.0; // 5 -> 4 columns (hysteresis margin)

    // If _columnCount hasn't been set yet, use raw logic.
    if (_columnCount == null) {
      if (width < threshold1Up) {
        return 1;
      } else if (width < threshold2Up) {
        return 2;
      } else if (width < threshold3Up) {
        return 3;
      } else if (width < threshold4Up) {
        return 4;
      } else {
        return 5;  // New case: allow 5 columns on wider screens.
      }
    }

    // Use hysteresis rules based on the current stable _columnCount.
    switch (_columnCount) {
      case 1:
        return width >= threshold1Up ? 2 : 1;
      case 2:
        if (width >= threshold2Up) {
          return 3;
        } else if (width < threshold1Down) {
          return 1;
        }
        return 2;
      case 3:
        if (width >= threshold3Up) {
          return 4;
        } else if (width < threshold2Down) {
          return 2;
        }
        return 3;
      case 4:
        if (width >= threshold4Up) {
          return 5;
        } else if (width < threshold3Down) {
          return 3;
        }
        return 4;
      case 5:
        return width < threshold4Down ? 4 : 5;
      default:
        return _columnCount!;
    }
  }

}
