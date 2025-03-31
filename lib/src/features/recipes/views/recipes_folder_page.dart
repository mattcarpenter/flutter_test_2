import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../../constants/folder_constants.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/recipe_provider.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../widgets/recipe_list.dart';
import 'add_recipe_modal.dart';

class RecipesFolderPage extends ConsumerWidget {
  final String? folderId;
  final String title;
  final String previousPageTitle;

  const RecipesFolderPage({
    super.key,
    this.folderId,
    required this.title,
    required this.previousPageTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all recipes
    final recipesAsyncValue = ref.watch(recipeNotifierProvider);

    return AdaptiveSliverPage(
      title: title,
      searchEnabled: true,
      slivers: [
        recipesAsyncValue.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => SliverFillRemaining(
            child: Center(child: Text('Error: $error')),
          ),
          data: (recipesWithFolders) {
            final recipes = recipesWithFolders.map((r) => r.recipe).toList();

            // Filter recipes based on folder ID
            List<RecipeEntry> filteredRecipes;

            if (folderId == kUncategorizedFolderId) {
              // Show recipes with no folder assignments
              filteredRecipes = recipes.where((recipe) {
                return recipe.folderIds == null || recipe.folderIds!.isEmpty;
              }).toList();
            } else if (folderId == null) {
              // Show all recipes
              filteredRecipes = recipes;
            } else {
              // Show recipes in the specified folder
              filteredRecipes = recipes
                  .where((recipe) => recipe.folderIds?.contains(folderId) ?? false)
                  .toList();
            }

            if (filteredRecipes.isEmpty) {
              return const SliverFillRemaining(
                child: Center(child: Text('No recipes in this folder yet')),
              );
            }

            return RecipesList(recipes: filteredRecipes, currentPageTitle: title);
          },
        ),
      ],
      trailing: AdaptivePullDownButton(
        items: [
          AdaptiveMenuItem(
            title: 'Add Recipe',
            icon: const Icon(CupertinoIcons.book),
            onTap: () {
              // Don't pass folderId for uncategorized folder
              final saveFolderId = folderId == kUncategorizedFolderId ? null : folderId;
              showRecipeEditorModal(context, folderId: saveFolderId);
            },
          )
        ],
        child: const Icon(CupertinoIcons.add_circled),
      ),
      previousPageTitle: previousPageTitle,
      automaticallyImplyLeading: true,
    );
  }
}
