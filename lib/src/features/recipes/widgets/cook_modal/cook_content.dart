import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/database/models/steps.dart' as recipe_steps;
import 'package:recipe_app/database/models/ingredients.dart';
import 'package:recipe_app/src/providers/cook_provider.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart' as recipe_provider;
import '../../../../../database/database.dart';
import '../../../../../database/models/cooks.dart';
import '../../../../widgets/wolt/button/wolt_elevated_button.dart';
import 'ingredients_sheet.dart';
import 'add_recipe_search_modal.dart';
import 'package:collection/collection.dart';

class CookContent extends ConsumerStatefulWidget {
  final String initialCookId;
  final String initialRecipeId;
  final BuildContext modalContext;

  const CookContent({
    Key? key,
    required this.initialCookId,
    required this.initialRecipeId,
    required this.modalContext,
  }) : super(key: key);

  @override
  ConsumerState<CookContent> createState() => CookContentState();
}

class CookContentState extends ConsumerState<CookContent> {
  List<Ingredient>? _ingredients;

  // Public methods that can be called from the parent
  void showIngredientsSheet() {
    if (_ingredients != null) {
      showIngredientsModal(context, _ingredients!);
    }
  }

  void showFinishDialog() {
    _showFinishDialog();
  }

  @override
  void initState() {
    super.initState();
    // Set the initial active cook
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeCookInModalProvider.notifier).state = widget.initialCookId;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the active cook ID from our state provider
    final activeCookId = ref.watch(activeCookInModalProvider);
    
    // Get all in-progress cooks
    final cooksAsyncValue = ref.watch(cookNotifierProvider);
    
    // Find the currently active cook
    final CookEntry? activeCook = cooksAsyncValue.when(
      loading: () => null,
      error: (_, __) => null,
      data: (cooks) => cooks.firstWhereOrNull((c) => c.id == activeCookId),
    );
    
    // Get all in-progress cooks for the recipe list
    final List<CookEntry> inProgressCooks = cooksAsyncValue.when(
      loading: () => [],
      error: (_, __) => [],
      data: (cooks) => cooks.where((c) => c.status == CookStatus.inProgress).toList(),
    );

    // Get the active recipe details
    final String activeRecipeId = activeCook?.recipeId ?? widget.initialRecipeId;
    // Explicitly using the provider from recipe_provider.dart
    final recipeAsync = ref.watch(recipe_provider.recipeByIdStreamProvider(activeRecipeId));

    // Add fixed height to the entire content to avoid flex/expanded issues
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: recipeAsync.when(
        loading: () => _buildLoadingContent(),
        error: (error, _) => _buildErrorContent(error.toString()),
        data: (recipe) {
          if (recipe == null) {
            return _buildErrorContent("Recipe not found");
          }

          // Get the steps and ingredients from the recipe
          final steps = recipe.steps ?? [];
          final ingredients = recipe.ingredients ?? [];
          _ingredients = ingredients; // Store for action buttons

          // Get the current step index from the activeCook or default to 0
          final currentStepIndex = activeCook?.currentStepIndex ?? 0;

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
            inProgressCooks: inProgressCooks,
            activeCookId: activeCookId,
          );
        },
      ),
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
    required List<CookEntry> inProgressCooks,
    required String? activeCookId,
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

    return Column(
      mainAxisSize: MainAxisSize.max, // Take all available height
      children: [
        // Top section - Step number and section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title if available
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

              // Step number and progress indicator
              Text(
                'Step ${currentStepIndex + 1} of $totalSteps',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Middle section - Use Flexible instead of Expanded for better behavior
        Flexible(
          fit: FlexFit.tight, // This is important for proper sizing
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                currentStep.text,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        // Bottom section - Recipe cards and navigation buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Recipe cards - horizontal scrollable list
              SizedBox(
                height: 70, // Reduced height
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Active cooks as recipe cards
                    ...inProgressCooks.map((cook) {
                      final isActive = cook.id == activeCookId;
                      return GestureDetector(
                        onTap: () {
                          // Switch to this cook
                          ref.read(activeCookInModalProvider.notifier).state = cook.id;
                        },
                        child: Container(
                          width: 180,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade300,
                              width: isActive ? 2 : 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  cook.recipeName,
                                  style: TextStyle(
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                isActive ? 'Now cooking' : 'Tap to switch',
                                style: TextStyle(
                                  fontSize: 12, 
                                  color: isActive ? Theme.of(context).primaryColor : Colors.grey
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    // "Add another recipe" card
                    GestureDetector(
                      onTap: _showAddRecipeModal,
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(height: 4),
                            Text('Add Recipe',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Navigation buttons - Always show 2 equal width buttons
              Row(
                children: [
                  // Previous button (disabled when on first step)
                  Expanded(
                    child: WoltElevatedButton(
                      theme: WoltElevatedButtonTheme.secondary,
                      onPressed: isFirstStep ? () {} : () => _updateStep(currentStepIndex - 1),
                      enabled: !isFirstStep,
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Next/Complete button
                  Expanded(
                    child: WoltElevatedButton(
                      onPressed: () {
                        if (isLastStep) {
                          _showFinishDialog();
                        } else {
                          _updateStep(currentStepIndex + 1);
                        }
                      },
                      child: Text(isLastStep ? 'Complete' : 'Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _updateStep(int newIndex) {
    final activeCookId = ref.read(activeCookInModalProvider);
    if (activeCookId != null) {
      ref.read(cookNotifierProvider.notifier).updateCook(
        cookId: activeCookId,
        currentStepIndex: newIndex,
      );
    }
  }

  void _showFinishDialog() {
    final activeCookId = ref.read(activeCookInModalProvider);
    if (activeCookId == null) return;
    
    // Get all in-progress cooks for next cook selection
    final List<CookEntry> inProgressCooks = ref.read(cookNotifierProvider)
        .maybeWhen(
          data: (cooks) => cooks.where((c) => c.status == CookStatus.inProgress).toList(),
          orElse: () => [],
        );
    
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
                cookId: activeCookId,
              );

              // Find next cook to switch to
              final remainingCooks = inProgressCooks
                  .where((cook) => cook.id != activeCookId)
                  .toList();
                  
              if (remainingCooks.isNotEmpty) {
                // Switch to another cook if available
                ref.read(activeCookInModalProvider.notifier).state = remainingCooks.first.id;
              } else {
                // No more cooks, close the modal
                Navigator.of(widget.modalContext).pop();
              }
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
                cookId: activeCookId,
                status: CookStatus.discarded,
              );

              // Find next cook to switch to
              final remainingCooks = inProgressCooks
                  .where((cook) => cook.id != activeCookId)
                  .toList();
                  
              Navigator.of(dialogContext).pop(); // Close dialog
              
              if (remainingCooks.isNotEmpty) {
                // Switch to another cook if available
                ref.read(activeCookInModalProvider.notifier).state = remainingCooks.first.id;
              } else {
                // No more cooks, close the modal
                Navigator.of(widget.modalContext).pop();
              }
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  void _showAddRecipeModal() {
    showAddRecipeSearchModal(context, cookId: widget.initialCookId);
  }
}
