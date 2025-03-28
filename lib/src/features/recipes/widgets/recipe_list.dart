import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/src/features/recipes/widgets/recipe_tile.dart';

import 'package:go_router/go_router.dart';

import '../../../../database/database.dart';
import '../../../providers/recipe_provider.dart';

class RecipesList extends ConsumerWidget {
  final List<RecipeEntry> recipes;
  final String currentPageTitle;

  const RecipesList({super.key, required this.recipes, required this.currentPageTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: DynamicSliverGridDelegate(),
        delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
            final recipe = recipes[index];
            return RecipeTile(key: ValueKey(recipe.id), recipe: recipe,
                onTap: () {
                  context.push('/recipes/recipe/${recipe.id}', extra: {
                    'previousPageTitle': currentPageTitle,
                  });
                },
                onDelete: () {
              ref.read(recipeNotifierProvider.notifier).deleteRecipe(recipe.id);
            });
          },
          childCount: recipes.length,
        ),
      ),
    );
  }
}

/// Custom SliverGridDelegate that calculates the number of columns dynamically.
class DynamicSliverGridDelegate extends SliverGridDelegate {
  final double crossAxisSpacing = 16.0;
  final double mainAxisSpacing = 16.0;
  final double tileHeight = 180.0; // Adjusted for consistency

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final availableWidth = constraints.crossAxisExtent; // Actual content area width
    final columnCount = _computeHysteresisColumnCount(availableWidth);

    // Calculate total spacing (between tiles)
    final totalSpacing = crossAxisSpacing * (columnCount - 1);
    final tileWidth = (availableWidth - totalSpacing) / columnCount;

    return SliverGridRegularTileLayout(
      crossAxisCount: columnCount,
      mainAxisStride: tileHeight + mainAxisSpacing, // Includes vertical spacing
      crossAxisStride: tileWidth + crossAxisSpacing, // Includes horizontal spacing
      childMainAxisExtent: tileHeight, // Keeps consistent tile height
      childCrossAxisExtent: tileWidth, // Adjusted tile width
      reverseCrossAxis: false,
    );
  }

  @override
  bool shouldRelayout(DynamicSliverGridDelegate oldDelegate) => true;

  int _computeHysteresisColumnCount(double width) {
    const threshold1Up = 280.0;
    const threshold1Down = 260.0;
    const threshold2Up = 450.0;
    const threshold2Down = 430.0;
    const threshold3Up = 650.0;
    const threshold3Down = 630.0;
    const threshold4Up = 900.0;
    const threshold4Down = 880.0;

    if (width < threshold1Up) {
      return 1;
    } else if (width < threshold2Up) {
      return 2;
    } else if (width < threshold3Up) {
      return 3;
    } else if (width < threshold4Up) {
      return 4;
    } else {
      return 5;
    }
  }
}

