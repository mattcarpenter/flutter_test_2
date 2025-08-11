import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/src/features/recipes/widgets/recipe_view/cook_action_button.dart';
import 'package:recipe_app/src/features/recipes/widgets/recipe_view/recipe_image_gallery.dart';
import 'package:recipe_app/src/features/recipes/widgets/recipe_view/recipe_ingredients_view.dart';
import 'package:recipe_app/src/features/recipes/widgets/recipe_view/recipe_steps_view.dart';
import 'package:recipe_app/src/providers/pantry_provider.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';

import '../../../../../database/database.dart';
import '../../../../repositories/recipe_repository.dart';

// Provider to fetch a single recipe by ID
final recipeByIdStreamProvider = StreamProvider.family<RecipeEntry?, String>(
      (ref, recipeId) {
    final repository = ref.watch(recipeRepositoryProvider);
    // First, we need to add a new method to watch a single recipe in the repository
    return repository.watchRecipeById(recipeId);
  },
);

class RecipeView extends ConsumerStatefulWidget {
  final String recipeId;

  const RecipeView({Key? key, required this.recipeId}) : super(key: key);

  @override
  ConsumerState<RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends ConsumerState<RecipeView> {
  @override
  void initState() {
    super.initState();
    // Pre-fetch ingredient matches when the view is loaded
    Future.microtask(() {
      // First make sure the pantry data is fresh
      ref.refresh(pantryItemsProvider);
      
      // Then invalidate and read the ingredient matches
      ref.invalidate(recipeIngredientMatchesProvider(widget.recipeId));
      ref.read(recipeIngredientMatchesProvider(widget.recipeId).future);
      
      print("Initialized recipe view for ${widget.recipeId}, refreshed providers");
    });
  }
  
  @override
  void didUpdateWidget(RecipeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the recipe ID changes, refresh the data
    if (oldWidget.recipeId != widget.recipeId) {
      Future.microtask(() {
        ref.invalidate(recipeIngredientMatchesProvider(widget.recipeId));
        ref.read(recipeIngredientMatchesProvider(widget.recipeId).future);
        print("Recipe ID changed, refreshed providers");
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Watch pantry items to detect changes
    ref.watch(pantryItemsProvider);
    final recipeAsync = ref.watch(recipeByIdStreamProvider(widget.recipeId));

    return recipeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error loading recipe: $error')),
      data: (recipe) {
        if (recipe == null) {
          return const Center(child: Text('Recipe not found'));
        }

        // Calculate total time (if both prep and cook times are available)
        String totalTime = '';
        if (recipe.prepTime != null && recipe.cookTime != null) {
          final total = recipe.prepTime! + recipe.cookTime!;
          totalTime = '$total mins';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery
            if (recipe.images != null && recipe.images!.isNotEmpty)
              RecipeImageGallery(images: recipe.images!, recipeId: recipe.id),

            const SizedBox(height: 16),

            // Title
            Text(
              recipe.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            // Description (if available)
            if (recipe.description != null && recipe.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                recipe.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],

            const SizedBox(height: 16),

            CookActionButton(recipeId: recipe.id, recipeName: recipe.title),

            const SizedBox(height: 16),

            // Recipe Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (recipe.servings != null)
                    _buildInfoItem(
                      context,
                      icon: Icons.people,
                      label: 'Servings',
                      value: '${recipe.servings}',
                    ),
                  if (recipe.prepTime != null)
                    _buildInfoItem(
                      context,
                      icon: Icons.timer,
                      label: 'Prep',
                      value: '${recipe.prepTime} min',
                    ),
                  if (recipe.cookTime != null)
                    _buildInfoItem(
                      context,
                      icon: Icons.microwave,
                      label: 'Cook',
                      value: '${recipe.cookTime} min',
                    ),
                  if (totalTime.isNotEmpty)
                    _buildInfoItem(
                      context,
                      icon: Icons.hourglass_bottom,
                      label: 'Total',
                      value: totalTime,
                    ),
                ],
              ),
            ),

            // Source (if available)
            if (recipe.source != null && recipe.source!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Source: ${recipe.source}',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Ingredients with pantry match indicators
            RecipeIngredientsView(
              ingredients: recipe.ingredients ?? [],
              recipeId: recipe.id,
              // Add a unique key to force rebuild
              key: ValueKey('IngredientsView-${recipe.id}'),
            ),

            const SizedBox(height: 8),

            // Steps
            RecipeStepsView(steps: recipe.steps ?? []),

            // Notes (if available)
            if (recipe.generalNotes != null && recipe.generalNotes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(recipe.generalNotes!),
              ),
            ],

            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
      }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
