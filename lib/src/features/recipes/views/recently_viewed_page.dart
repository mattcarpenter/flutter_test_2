import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../database/database.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/recently_viewed_provider.dart';
import '../../../widgets/recipe_list_item.dart';
import '../../../theme/spacing.dart';
import '../../../theme/colors.dart';

class RecentlyViewedPage extends ConsumerWidget {
  const RecentlyViewedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentlyViewedAsync = ref.watch(recentlyViewedProvider);

    return AdaptiveSliverPage(
      title: 'Recently Viewed',
      searchEnabled: false, // No search filtering per requirements
      slivers: [
        recentlyViewedAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => SliverFillRemaining(
            child: Center(child: Text('Error: $error')),
          ),
          data: (recentlyViewedRecipes) {
            if (recentlyViewedRecipes.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: AppColorSwatches.neutral[400],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'No recently viewed recipes yet.\nStart exploring recipes to see them here.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.of(context).textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return _buildResponsiveGrid(context, recentlyViewedRecipes);
          },
        ),
      ],
      previousPageTitle: 'Recipes',
      automaticallyImplyLeading: true,
    );
  }

  Widget _buildResponsiveGrid(BuildContext context, List<RecipeEntry> recipes) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive layout: 1 column mobile, 2 columns wider screens
    final crossAxisCount = screenWidth < 600 ? 1 : 2;

    if (crossAxisCount == 1) {
      // Single column - use simple list
      return SliverList.builder(
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return RecipeListItem(
            recipe: recipe,
            onTap: () {
              context.push('/recipe/${recipe.id}', extra: {
                'previousPageTitle': 'Recently Viewed',
              });
            },
          );
        },
      );
    } else {
      // Two column grid
      return SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.lg,
            childAspectRatio: 4.0, // Wide aspect ratio for recipe list items
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final recipe = recipes[index];
              return RecipeListItem(
                recipe: recipe,
                onTap: () {
                  context.push('/recipe/${recipe.id}', extra: {
                    'previousPageTitle': 'Recently Viewed',
                  });
                },
              );
            },
            childCount: recipes.length,
          ),
        ),
      );
    }
  }
}