import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/database/models/steps.dart' as recipe_steps;
import 'package:recipe_app/database/models/ingredients.dart';
import 'package:recipe_app/src/providers/cook_provider.dart';
import '../../../../../database/database.dart';
import '../../../../widgets/wolt/button/wolt_elevated_button.dart';
import '../recipe_view/recipe_view.dart';
import 'ingredients_sheet.dart';
import 'package:collection/collection.dart';

class CookContent extends ConsumerStatefulWidget {
  final String cookId;
  final String recipeId;
  final BuildContext modalContext;

  const CookContent({
    Key? key,
    required this.cookId,
    required this.recipeId,
    required this.modalContext,
  }) : super(key: key);

  @override
  ConsumerState<CookContent> createState() => _CookContentState();
}

class _CookContentState extends ConsumerState<CookContent> {
  @override
  Widget build(BuildContext context) {
    // Get the cook entry from the provider
    final cooksAsyncValue = ref.watch(cookNotifierProvider);
    final CookEntry? cook = cooksAsyncValue.when(
      loading: () => null,
      error: (_, __) => null,
      data: (cooks) => cooks.firstWhereOrNull((c) => c.id == widget.cookId),
    );

    // Get the recipe details
    final recipeAsync = ref.watch(recipeByIdStreamProvider(widget.recipeId));

    return recipeAsync.when(
      loading: () => _buildLoadingContent(),
      error: (error, _) => _buildErrorContent(error.toString()),
      data: (recipe) {
        if (recipe == null) {
          return _buildErrorContent("Recipe not found");
        }

        // Get the steps and ingredients from the recipe
        final steps = recipe.steps ?? [];
        final ingredients = recipe.ingredients ?? [];

        // Get the current step index from the cook or default to 0
        final currentStepIndex = cook?.currentStepIndex ?? 0;

        // Ensure we have a valid step index and handle empty steps list
        if (steps.isEmpty) {
          return _buildErrorContent("No steps found for this recipe");
        }

        final validStepIndex = currentStepIndex.clamp(0, steps.length - 1);

        return _buildStepContent(
          recipe: recipe,
          steps: steps,
          ingredients: ingredients,
          currentStepIndex: validStepIndex.toInt(),
          totalSteps: steps.length,
        );
      },
    );
  }

  Widget _buildLoadingContent() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorContent(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: $errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent({
    required dynamic recipe,
    required List<recipe_steps.Step> steps,
    required List<Ingredient> ingredients,
    required int currentStepIndex,
    required int totalSteps,
  }) {
    // Find the current step
    final isFirstStep = currentStepIndex == 0;
    final isLastStep = currentStepIndex == totalSteps - 1;
    final currentStep = steps[currentStepIndex];

    // Find the current section
    String sectionTitle = "";
    for (int i = currentStepIndex; i >= 0; i--) {
      if (steps[i].type == 'section') {
        sectionTitle = steps[i].text;
        break;
      }
    }

    return Stack(
      children: [
        // Main content with padding at the bottom for action bar
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top actions row - Ingredients button and Finish button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Ingredients button
                  IconButton(
                    icon: const Icon(Icons.list),
                    tooltip: 'Ingredients',
                    onPressed: () => _showIngredientsSheet(context, ingredients),
                  ),
                  // Finish button
                  TextButton(
                    onPressed: () => _showFinishDialog(),
                    child: const Text('Finish'),
                  ),
                ],
              ),

              // Section title
              if (sectionTitle.isNotEmpty) ...[
                Text(
                  sectionTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Step number and progress
              Text(
                'Step ${currentStepIndex + 1} of $totalSteps',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Step instruction
              Text(
                currentStep.text,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),

              // Recipe card(s)
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Current recipe card
                    Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            recipe.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text('Now cooking'),
                        ],
                      ),
                    ),

                    // "Add another recipe" card
                    Container(
                      width: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline),
                            SizedBox(height: 8),
                            Text('Add Recipe'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Extra padding at the bottom
              const SizedBox(height: 40),
            ],
          ),
        ),

        // Bottom navigation buttons
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Back button
                if (!isFirstStep)
                  Expanded(
                    child: WoltElevatedButton(
                      theme: WoltElevatedButtonTheme.secondary,
                      onPressed: () => _updateStep(currentStepIndex - 1),
                      child: const Text('Previous'),
                    ),
                  ),

                if (!isFirstStep && !isLastStep)
                  const SizedBox(width: 16),

                // Next button
                if (!isLastStep)
                  Expanded(
                    child: WoltElevatedButton(
                      onPressed: () => _updateStep(currentStepIndex + 1),
                      child: const Text('Next'),
                    ),
                  ),

                // Complete button when on the last step
                if (isLastStep)
                  Expanded(
                    child: WoltElevatedButton(
                      onPressed: () => _showFinishDialog(),
                      child: const Text('Complete'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _updateStep(int newIndex) {
    ref.read(cookNotifierProvider.notifier).updateCook(
      cookId: widget.cookId,
      currentStepIndex: newIndex,
    );
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finish this cook?'),
        content: const Text('What would you like to do with this cooking session?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close dialog

              // Save the cook
              ref.read(cookNotifierProvider.notifier).finishCook(
                cookId: widget.cookId,
              );

              // Close modal
              Navigator.of(widget.modalContext).pop();
            },
            child: const Text('Save to My Cooks'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              // Discard the cook
              ref.read(cookNotifierProvider.notifier).updateCook(
                cookId: widget.cookId,
                notes: 'Discarded by user',
              );

              Navigator.of(dialogContext).pop(); // Close dialog
              Navigator.of(widget.modalContext).pop(); // Close modal
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  void _showIngredientsSheet(BuildContext context, List<Ingredient> ingredients) {
    showIngredientsModal(context, ingredients);
  }
}
