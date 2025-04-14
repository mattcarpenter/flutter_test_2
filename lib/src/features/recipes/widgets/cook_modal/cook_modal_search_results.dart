import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../database/database.dart';
import '../../../../providers/recipe_provider.dart';

class CookModalSearchResults extends ConsumerWidget {
  final void Function(RecipeEntry) onResultSelected;

  const CookModalSearchResults({
    super.key, 
    required this.onResultSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(cookModalRecipeSearchProvider);

    if (searchState.error != null) {
      return Center(child: Text('Error: ${searchState.error}'));
    }

    List<RecipeEntry> results = searchState.results;

    if (results.isEmpty && searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (results.isEmpty) {
      return const Center(child: Text('No recipes found.'));
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