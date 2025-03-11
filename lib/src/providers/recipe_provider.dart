// lib/notifiers/recipe_notifier.dart

import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../database/models/ingredients.dart';
import '../../database/models/steps.dart';
import '../models/recipe_with_folders.dart';
import '../repositories/recipe_repository.dart';

class RecipeNotifier extends StateNotifier<AsyncValue<List<RecipeWithFolders>>> {
  final RecipeRepository _repository;
  late final StreamSubscription<List<RecipeWithFolders>> _subscription;

  RecipeNotifier(this._repository) : super(const AsyncValue.loading()) {
    _subscription = _repository.watchRecipesWithFolders().listen(
          (recipesWithFolders) {
        state = AsyncValue.data(recipesWithFolders);
      },
      onError: (error, stack) {
        state = AsyncValue.error(error, stack);
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  // Add a new recipe.
  Future<void> addRecipe({
    required String title,
    required String language,
    required String userId,
    int? rating,
    String? description,
    int? servings,
    int? prepTime,
    int? cookTime,
    int? totalTime,
    String? source,
    String? nutrition,
    String? generalNotes,
    String? householdId,
    int? createdAt,
    int? updatedAt,
    List<Ingredient>? ingredients,
    List<Step>? steps,
    List<String>? folderIds,
  }) async {
    try {
      final recipeCompanion = RecipesCompanion.insert(
        title: title,
        description: Value(description),
        rating: Value(rating),
        language: language,
        servings: Value(servings),
        prepTime: Value(prepTime),
        cookTime: Value(cookTime),
        totalTime: Value(totalTime),
        source: Value(source),
        nutrition: Value(nutrition),
        generalNotes: Value(generalNotes),
        userId: userId,
        householdId: Value(householdId),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        ingredients: Value(ingredients),
        steps: Value(steps),
        folderIds: Value(folderIds ?? []),
      );

      await _repository.addRecipe(recipeCompanion);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Expose a method to add a folder assignment (i.e. add a folder ID) to a recipe.
  Future<void> addFolderAssignment({
    required String recipeId,
    required String folderId,
  }) async {
    await _repository.addFolderToRecipe(recipeId: recipeId, folderId: folderId);
  }

  // Optionally, expose a method to remove a folder assignment.
  Future<void> removeFolderAssignment({
    required String recipeId,
    required String folderId,
  }) async {
    await _repository.removeFolderFromRecipe(recipeId: recipeId, folderId: folderId);
  }

  // Batch update ingredients: Update the entire ingredients list for a recipe.
  Future<void> updateIngredients({
    required String recipeId,
    required List<Ingredient> ingredients,
  }) async {
    try {
      await _repository.updateIngredients(recipeId, ingredients);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Batch update steps: Update the entire steps list for a recipe.
  Future<void> updateSteps({
    required String recipeId,
    required List<Step> steps,
  }) async {
    try {
      await _repository.updateSteps(recipeId, steps);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Convenience: Create (append) a new ingredient to a recipe.
  Future<void> createIngredientForRecipe({
    required String recipeId,
    required Ingredient ingredient,
  }) async {
    final currentRecipes = state.value;
    if (currentRecipes == null) return;
    final index = currentRecipes.indexWhere((r) => r.recipe.id == recipeId);
    if (index == -1) return;
    final currentIngredients = currentRecipes[index].recipe.ingredients ?? [];
    final newIngredients = List<Ingredient>.from(currentIngredients)..add(ingredient);
    await updateIngredients(recipeId: recipeId, ingredients: newIngredients);
  }

  // Convenience: Create (append) a new step to a recipe.
  Future<void> createStepForRecipe({
    required String recipeId,
    required Step step,
  }) async {
    final currentRecipes = state.value;
    if (currentRecipes == null) return;
    final index = currentRecipes.indexWhere((r) => r.recipe.id == recipeId);
    if (index == -1) return;
    final currentSteps = currentRecipes[index].recipe.steps ?? [];
    final newSteps = List<Step>.from(currentSteps)..add(step);
    await updateSteps(recipeId: recipeId, steps: newSteps);
  }

  Future<void> updateRecipe(RecipeEntry updatedRecipe) async {
    try {
      await _repository.updateRecipe(updatedRecipe);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider for the RecipeNotifier.
final recipeNotifierProvider =
StateNotifierProvider<RecipeNotifier, AsyncValue<List<RecipeWithFolders>>>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return RecipeNotifier(repository);
});
