import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../../constants/folder_constants.dart';
import '../../../providers/recipe_provider.dart';

class RecipeSearchResults extends ConsumerWidget {
  final String? folderId;
  final void Function(RecipeEntry)? onResultSelected;

  const RecipeSearchResults({super.key, this.folderId, this.onResultSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(recipeSearchNotifierProvider);

    if (searchState.error != null) {
      return Center(child: Text('Error: ${searchState.error}'));
    }

    List<RecipeEntry> results = searchState.results;

    if (folderId != null) {
      if (folderId == kUncategorizedFolderId) {
        results = results.where((r) => r.folderIds?.isEmpty ?? true).toList();
      } else {
        results = results.where((r) => r.folderIds?.contains(folderId) ?? false).toList();
      }
    }

    if (results.isEmpty && searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (results.isEmpty) {
      return const Center(child: Text('No recipes found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final recipe = results[index];
        return ListTile(
          title: Text(recipe.title),
          subtitle: Text(recipe.description ?? ''),
          onTap: () {
            if (onResultSelected != null) {
              // Save recipe to pass to callback
              final selectedRecipe = recipe;
              
              // Use Future.delayed to ensure the search UI can close
              // before navigation occurs
              Future.microtask(() {
                onResultSelected!(selectedRecipe);
              });
            }
          },
        );
      },
    );
  }
}

