import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/src/features/recipes/widgets/recipe_view/recipe_image_gallery.dart';
import 'package:recipe_app/src/features/recipes/widgets/recipe_view/recipe_ingredients_view.dart';
import 'package:recipe_app/src/features/recipes/widgets/recipe_view/recipe_steps_view.dart';
import 'package:recipe_app/src/providers/pantry_provider.dart';
import '../../../../providers/recipe_provider.dart' as recipe_provider;
import '../../../../providers/recently_viewed_provider.dart';
import '../../../../providers/cook_provider.dart';
import '../../../../theme/typography.dart';
import '../../../../theme/colors.dart';
import '../../../../utils/duration_formatter.dart';
import '../../../../widgets/app_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cook_modal/cook_modal.dart';

import '../../../../../database/database.dart';


class RecipeView extends ConsumerStatefulWidget {
  final String recipeId;
  final bool showHeroImage;

  const RecipeView({Key? key, required this.recipeId, this.showHeroImage = true}) : super(key: key);

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
      ref.invalidate(recipe_provider.recipeIngredientMatchesProvider(widget.recipeId));
      ref.read(recipe_provider.recipeIngredientMatchesProvider(widget.recipeId).future);

      // Track this recipe as recently viewed
      ref.read(recentlyViewedProvider.notifier).addRecentlyViewed(widget.recipeId);

      print("Initialized recipe view for ${widget.recipeId}, refreshed providers");
    });
  }

  @override
  void didUpdateWidget(RecipeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the recipe ID changes, refresh the data
    if (oldWidget.recipeId != widget.recipeId) {
      Future.microtask(() {
        ref.invalidate(recipe_provider.recipeIngredientMatchesProvider(widget.recipeId));
        ref.read(recipe_provider.recipeIngredientMatchesProvider(widget.recipeId).future);

        // Track the new recipe as recently viewed
        ref.read(recentlyViewedProvider.notifier).addRecentlyViewed(widget.recipeId);

        print("Recipe ID changed, refreshed providers");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch pantry items to detect changes
    ref.watch(pantryItemsProvider);
    final recipeAsync = ref.watch(recipe_provider.recipeByIdStreamProvider(widget.recipeId));

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
          totalTime = DurationFormatter.formatMinutes(total);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery (only show if showHeroImage is true)
            if (widget.showHeroImage && recipe.images != null && recipe.images!.isNotEmpty) ...[
              RecipeImageGallery(images: recipe.images!, recipeId: recipe.id),
              const SizedBox(height: 16),
            ],

            // Title and Cooking Button Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (takes remaining space after button)
                Expanded(
                  child: Text(
                    recipe.title,
                    style: AppTypography.h1Serif.copyWith(
                      color: AppColors.of(context).textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16), // Space between title and button
                // Cooking Button (intrinsic width, right-aligned)
                _buildCookingButton(context, ref, recipe),
              ],
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

            // Recipe Info
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (recipe.servings != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 32),
                    child: _buildInfoItem(
                      context,
                      label: 'Servings',
                      value: '${recipe.servings}',
                    ),
                  ),
                if (recipe.prepTime != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 32),
                    child: _buildInfoItem(
                      context,
                      label: 'Prep Time',
                      value: DurationFormatter.formatMinutes(recipe.prepTime!),
                    ),
                  ),
                if (recipe.cookTime != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 32),
                    child: _buildInfoItem(
                      context,
                      label: 'Cook Time',
                      value: DurationFormatter.formatMinutes(recipe.cookTime!),
                    ),
                  ),
                if (totalTime.isNotEmpty)
                  _buildInfoItem(
                    context,
                    label: 'Total',
                    value: totalTime,
                  ),
              ],
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

            const SizedBox(height: 32),

            // Ingredients with pantry match indicators
            RecipeIngredientsView(
              ingredients: recipe.ingredients ?? [],
              recipeId: recipe.id,
              // Add a unique key to force rebuild
              key: ValueKey('IngredientsView-${recipe.id}'),
            ),

            const SizedBox(height: 24),

            // Steps
            RecipeStepsView(steps: recipe.steps ?? []),

            // Notes (if available)
            if (recipe.generalNotes != null && recipe.generalNotes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Notes',
                style: AppTypography.h2Serif.copyWith(
                  color: AppColors.of(context).headingSecondary,
                ),
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
        required String label,
        required String value,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.of(context).textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildCookingButton(BuildContext context, WidgetRef ref, RecipeEntry recipe) {
    // Don't show button if recipe has no steps
    if (recipe.steps == null || recipe.steps!.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeCook = ref.watch(activeCookForRecipeProvider(recipe.id));
    final cookNotifier = ref.read(cookNotifierProvider.notifier);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    final isActive = activeCook != null;
    final buttonText = isActive ? 'Resume Cooking' : 'Start Cooking';

    return AppButton(
      text: buttonText,
      style: AppButtonStyle.outline,
      size: AppButtonSize.small,
      leadingIcon: const Icon(Icons.play_arrow, size: 18),
      onPressed: () async {
        String cookId;
        if (isActive) {
          cookId = activeCook.id;
        } else {
          if (userId != null) {
            cookId = await cookNotifier.startCook(
              recipeId: recipe.id,
              userId: userId,
              recipeName: recipe.title,
              householdId: null,
            );
          } else {
            return; // No user ID, can't start cooking
          }
        }

        if (context.mounted) {
          showCookModal(
            context,
            cookId: cookId,
            recipeId: recipe.id,
          );
        }
      },
    );
  }
}
