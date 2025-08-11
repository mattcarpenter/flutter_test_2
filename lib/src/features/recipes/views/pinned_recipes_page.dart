import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../database/database.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/recipe_provider.dart';
import '../../../widgets/recipe_list_item.dart';

class PinnedRecipesPage extends ConsumerStatefulWidget {
  const PinnedRecipesPage({super.key});

  @override
  ConsumerState<PinnedRecipesPage> createState() => _PinnedRecipesPageState();
}

class _PinnedRecipesPageState extends ConsumerState<PinnedRecipesPage> {
  String _searchQuery = '';

  List<RecipeEntry> _filterRecipes(List<RecipeEntry> recipes, String query) {
    if (query.isEmpty) return recipes;
    
    final lowerQuery = query.toLowerCase();
    return recipes.where((recipe) {
      return recipe.title.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pinnedRecipesAsync = ref.watch(pinnedRecipesProvider);

    return AdaptiveSliverPage(
      title: 'Pinned Recipes',
      searchEnabled: true,
      onSearchChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
      slivers: [
        pinnedRecipesAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => SliverFillRemaining(
            child: Center(child: Text('Error: $error')),
          ),
          data: (pinnedRecipes) {
            final filteredRecipes = _filterRecipes(pinnedRecipes, _searchQuery);
            
            if (filteredRecipes.isEmpty) {
              String emptyMessage;
              if (_searchQuery.isNotEmpty) {
                emptyMessage = 'No pinned recipes match "$_searchQuery"';
              } else if (pinnedRecipes.isEmpty) {
                emptyMessage = 'No pinned recipes yet.\nPin your favorite recipes to see them here.';
              } else {
                emptyMessage = 'No recipes found';
              }
              
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        emptyMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverList.builder(
              itemCount: filteredRecipes.length,
              itemBuilder: (context, index) {
                final recipe = filteredRecipes[index];
                return RecipeListItem(
                  recipe: recipe,
                  onTap: () {
                    context.push('/recipes/recipe/${recipe.id}', extra: {
                      'previousPageTitle': 'Pinned Recipes',
                    });
                  },
                );
              },
            );
          },
        ),
      ],
      previousPageTitle: 'Recipes',
      automaticallyImplyLeading: true,
    );
  }
}