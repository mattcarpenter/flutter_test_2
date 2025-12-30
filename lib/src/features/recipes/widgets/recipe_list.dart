import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/src/features/recipes/widgets/recipe_tile.dart';

import 'package:go_router/go_router.dart';

import '../../../../database/database.dart';
import '../../../providers/recipe_provider.dart';
import '../../../theme/spacing.dart';

class RecipesList extends ConsumerWidget {
  final List<RecipeEntry> recipes;
  final String currentPageTitle;

  const RecipesList({super.key, required this.recipes, required this.currentPageTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width - 32; // Account for padding

    // Calculate number of columns based on screen width
    // More fluid responsive behavior
    int crossAxisCount;
    if (screenWidth < 360) {
      crossAxisCount = 1;
    } else if (screenWidth < 600) {
      crossAxisCount = 2;
    } else if (screenWidth < 900) {
      crossAxisCount = 3;
    } else if (screenWidth < 1200) {
      crossAxisCount = 4;
    } else if (screenWidth < 1600) {
      crossAxisCount = 5;
    } else {
      crossAxisCount = 6;
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,  // 16px left
        AppSpacing.lg,  // 16px top
        AppSpacing.lg,  // 16px right
        100,  // Extra bottom padding to prevent scroll issues
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: AppSpacing.xs,  // 8px vertical spacing
          crossAxisSpacing: AppSpacing.lg,  // 16px horizontal spacing
          childAspectRatio: 1.0, // Keep cards square
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final recipe = recipes[index];
            return RecipeTile(
              key: ValueKey(recipe.id),
              recipe: recipe,
              onTap: () {
                context.push('/recipe/${recipe.id}', extra: {
                  'previousPageTitle': currentPageTitle,
                });
              },
              onDelete: () {
                ref.read(recipeNotifierProvider.notifier).deleteRecipe(recipe.id);
              },
            );
          },
          childCount: recipes.length,
        ),
      ),
    );
  }
}
