import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      slivers: [
        recipesAsyncValue.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => SliverFillRemaining(
            child: Center(child: Text('Error: $error')),
          ),
          data: (recipesWithFolders) {
            // Filter recipes by folder ID
            final filteredRecipes = folderId == null
                ? recipesWithFolders.map((r) => r.recipe).toList()
                : recipesWithFolders
                .where((r) => r.recipe.folderIds?.contains(folderId) ?? false)
                .map((r) => r.recipe)
                .toList();

            if (filteredRecipes.isEmpty) {
              return const SliverFillRemaining(
                child: Center(child: Text('No recipes in this folder yet')),
              );
            }

            return RecipesList(recipes: filteredRecipes);
          },
        ),
      ],
      trailing: AdaptivePullDownButton(
        items: [
          AdaptiveMenuItem(
            title: 'Add Recipe',
            icon: const Icon(CupertinoIcons.book),
            onTap: () {
              showRecipeEditorModal(context, folderId: folderId);
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
