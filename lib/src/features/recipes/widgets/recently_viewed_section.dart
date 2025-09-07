import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/recently_viewed_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/recipe_list_item.dart';

class RecentlyViewedSection extends ConsumerWidget {
  const RecentlyViewedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show only last 5 recipes in the section
    final recentlyViewedAsync = ref.watch(recentlyViewedLimitedProvider(5));

    return recentlyViewedAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
      data: (recentlyViewedRecipes) {
        if (recentlyViewedRecipes.isEmpty) {
          return const SizedBox.shrink(); // Don't show section if no recently viewed recipes
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with title and "View All" button
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0), // 16px left/right, 8px top
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recently Viewed',
                    style: AppTypography.h2.copyWith(
                      color: AppColors.of(context).textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push('/recipes/recent');
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm), // 8px consistent gap

            // Single column list using RecipeListItem
            ...recentlyViewedRecipes.map((recipe) {
              return GestureDetector(
                onTap: () {
                  context.push('/recipes/recipe/${recipe.id}', extra: {
                    'previousPageTitle': 'Recipes',
                  });
                },
                child: AbsorbPointer(
                  child: RecipeListItem(
                    recipe: recipe,
                    onTap: null, // Disable internal tap to prevent gesture conflicts
                  ),
                ),
              );
            }),

            // Bottom margin to prevent scroll feedback loops
            const SizedBox(height: 80), // Extra space to prevent scroll bounce at bottom
          ],
        );
      },
    );
  }
}
