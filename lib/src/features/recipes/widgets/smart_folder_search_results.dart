import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../database/database.dart';
import '../../../providers/smart_folder_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../widgets/recipe_list_item.dart';

/// Search results widget for smart folders
/// This does client-side filtering of the already-loaded smart folder recipes
class SmartFolderSearchResults extends ConsumerWidget {
  final RecipeFolderEntry folder;
  final String currentPageTitle;

  const SmartFolderSearchResults({
    super.key,
    required this.folder,
    required this.currentPageTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(smartFolderSearchQueryProvider);
    final recipesAsync = ref.watch(smartFolderRecipesProvider(folder));
    final query = searchQuery.toLowerCase().trim();

    // Show placeholder when no search query
    if (query.isEmpty) {
      return Center(
        child: Text(
          'Start typing to search for recipes.',
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
      );
    }

    return recipesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (recipes) {
        // Filter recipes based on search query
        final filteredRecipes = recipes.where((recipe) {
          return recipe.title.toLowerCase().contains(query);
        }).toList();

        if (filteredRecipes.isEmpty) {
          return Center(
            child: Text(
              'No recipes match your search.',
              style: TextStyle(color: AppColors.of(context).textSecondary),
            ),
          );
        }

        return Column(
          children: [
            // Results count
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filteredRecipes.length} results',
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // Results list with responsive layout
            Expanded(
              child: _buildResponsiveGrid(context, filteredRecipes),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResponsiveGrid(BuildContext context, List<RecipeEntry> recipes) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive layout: 1 column mobile, 2 columns wider screens
    final crossAxisCount = screenWidth < 600 ? 1 : 2;

    if (crossAxisCount == 1) {
      // Single column - use simple list
      return ListView.builder(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return RecipeListItem(
            recipe: recipe,
            onTap: () {
              FocusScope.of(context).unfocus();
              context.push('/recipe/${recipe.id}', extra: {
                'previousPageTitle': currentPageTitle,
              });
            },
          );
        },
      );
    } else {
      // Two column grid
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.lg,
            childAspectRatio: 4.0, // Wide aspect ratio for recipe list items
          ),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return RecipeListItem(
              recipe: recipe,
              onTap: () {
                FocusScope.of(context).unfocus();
                context.push('/recipe/${recipe.id}', extra: {
                  'previousPageTitle': currentPageTitle,
                });
              },
            );
          },
        ),
      );
    }
  }
}
