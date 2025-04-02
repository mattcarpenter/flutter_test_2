import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/database.dart';
import '../../../providers/recipe_provider.dart';

class RecipeSearchResults extends ConsumerWidget {
  const RecipeSearchResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(recipeSearchNotifierProvider);

    if (searchState.error != null) {
      return Center(child: Text('Error: ${searchState.error}'));
    }

    final results = searchState.results;

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
            // navigate to recipe detail
          },
        );
      },
    );
  }
}

