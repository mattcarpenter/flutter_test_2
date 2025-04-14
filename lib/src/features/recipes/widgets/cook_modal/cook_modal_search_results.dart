import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../database/database.dart';
import '../../../../providers/recipe_provider.dart' as recipe_provider;
import '../../../../providers/cook_provider.dart';

class CookModalSearchResults extends ConsumerWidget {
  final void Function(RecipeEntry) onResultSelected;

  const CookModalSearchResults({
    super.key, 
    required this.onResultSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(recipe_provider.cookModalRecipeSearchProvider);
    // Watch in-progress cooks to filter them out
    final inProgressCooks = ref.watch(inProgressCooksProvider);
    
    // List of recipe IDs that already have active cooks
    final activeRecipeIds = inProgressCooks.map((cook) => cook.recipeId).toSet();

    if (searchState.error != null) {
      return Center(child: Text('Error: ${searchState.error}'));
    }

    // Filter out recipes that already have active cooks
    List<RecipeEntry> results = searchState.results
        .where((recipe) => !activeRecipeIds.contains(recipe.id))
        .toList();

    if (results.isEmpty && searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (results.isEmpty) {
      return searchState.results.isEmpty 
          ? const Center(child: Text('No recipes found.'))
          : const Center(child: Text('All matching recipes already in your cook session.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final recipe = results[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(recipe.title),
            subtitle: recipe.description != null && recipe.description!.isNotEmpty
                ? Text(
                    recipe.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: const Icon(Icons.add_circle_outline),
            onTap: () => onResultSelected(recipe),
          ),
        );
      },
    );
  }
}