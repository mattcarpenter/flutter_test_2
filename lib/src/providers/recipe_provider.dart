// lib/notifiers/recipe_notifier.dart

import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../database/database.dart';
import '../../database/models/ingredients.dart';
import '../../database/models/recipe_images.dart';
import '../../database/models/steps.dart';
import '../constants/folder_constants.dart';
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
    required String id,
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
    List<RecipeImage>? images,
  }) async {
    try {
      final recipeCompanion = RecipesCompanion.insert(
        id: Value(id),
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
        images: Value(images),
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

  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _repository.deleteRecipe(recipeId);
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

final recipesInFolderProvider = Provider.family<Stream<List<RecipeWithFolders>>, String?>(
      (ref, folderId) {
    final repository = ref.watch(recipeRepositoryProvider);
    if (folderId == null) {
      return repository.watchRecipesWithFolders();
    }
    return repository.watchRecipesByFolderId(folderId);
  },
);

/// Provider that returns a map of folder IDs to recipe counts
final recipeFolderCountProvider = Provider<Map<String, int>>((ref) {
  final recipesAsyncValue = ref.watch(recipeNotifierProvider);

  // Default empty map
  Map<String, int> folderCounts = {};

  // Special counter for uncategorized
  int uncategorizedCount = 0;

  // Process only when we have recipe data
  recipesAsyncValue.whenData((recipesWithFolders) {
    final recipes = recipesWithFolders.map((r) => r.recipe).toList();

    // Count uncategorized recipes
    uncategorizedCount = recipes.where((recipe) {
      return recipe.folderIds == null || recipe.folderIds!.isEmpty;
    }).length;

    // Add uncategorized count
    folderCounts[kUncategorizedFolderId] = uncategorizedCount;

    // Count recipes per folder
    for (final recipe in recipes) {
      if (recipe.folderIds != null) {
        for (final folderId in recipe.folderIds!) {
          folderCounts[folderId] = (folderCounts[folderId] ?? 0) + 1;
        }
      }
    }
  });

  return folderCounts;
});

// Stream provider for a single recipe by ID
final recipeByIdStreamProvider = StreamProvider.family<RecipeEntry?, String>((ref, recipeId) {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.watchRecipeById(recipeId);
});

class RecipeSearchState {
  final List<RecipeEntry> results;
  final bool isLoading;
  final Object? error;

  RecipeSearchState({
    required this.results,
    this.isLoading = false,
    this.error,
  });

  RecipeSearchState copyWith({
    List<RecipeEntry>? results,
    bool? isLoading,
    Object? error,
  }) {
    return RecipeSearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Main search provider for the app
final recipeSearchNotifierProvider =
NotifierProvider<RecipeSearchNotifier, RecipeSearchState>(
    RecipeSearchNotifier.new);
    
// Dedicated search provider for the cook modal
final cookModalRecipeSearchProvider =
NotifierProvider<RecipeSearchNotifier, RecipeSearchState>(
    RecipeSearchNotifier.new);

class RecipeSearchNotifier extends Notifier<RecipeSearchState> {
  Timer? _loadingTimer;
  int _searchId = 0;

  @override
  RecipeSearchState build() {
    return RecipeSearchState(results: [], isLoading: false);
  }

  Future<void> search(String query) async {
    // Cancel previous timer immediately
    _loadingTimer?.cancel();
    final currentSearchId = ++_searchId;

    if (query.isEmpty) {
      state = state.copyWith(results: [], isLoading: false, error: null);
      return;
    }

    // Schedule loading indicator to appear after a delay
    _loadingTimer = Timer(const Duration(milliseconds: 250), () {
      if (_searchId == currentSearchId) {
        state = state.copyWith(isLoading: true);
      }
    });

    try {
      final results = await ref.read(recipeRepositoryProvider).searchRecipes(query);

      // Immediately cancel timer upon receiving results
      _loadingTimer?.cancel();

      // Only apply if this is still the most recent query
      if (_searchId == currentSearchId) {
        state = state.copyWith(results: results, isLoading: false, error: null);
      }
    } catch (e) {
      _loadingTimer?.cancel();

      if (_searchId == currentSearchId) {
        state = state.copyWith(isLoading: false, error: e);
      }
    }
  }
}


