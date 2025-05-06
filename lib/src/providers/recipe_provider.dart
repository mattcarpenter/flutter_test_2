// lib/notifiers/recipe_notifier.dart

import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../database/database.dart';
import '../../database/models/ingredients.dart';
import '../../database/models/recipe_images.dart';
import '../../database/models/steps.dart';
import '../constants/folder_constants.dart';
import '../models/ingredient_pantry_match.dart';
import '../models/recipe_pantry_match.dart';
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
    String? language,
    String? userId,
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
        language: Value(language),
        servings: Value(servings),
        prepTime: Value(prepTime),
        cookTime: Value(cookTime),
        totalTime: Value(totalTime),
        source: Value(source),
        nutrition: Value(nutrition),
        generalNotes: Value(generalNotes),
        userId: Value(userId),
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

  /// Loads recipes from assets/recipes.json and adds them to the database
  ///
  /// [limit] controls how many recipes to import (null means import all)
  Future<int> importSeedRecipes({int? limit}) async {
    try {
      // Load and parse the JSON file
      final data = await rootBundle.loadString('assets/recipes.json');
      final List<dynamic> jsonRecipes = json.decode(data);

      // Apply limit if specified
      final recipesToImport = limit != null
          ? jsonRecipes.take(limit).toList()
          : jsonRecipes;

      int importedCount = 0;

      // Process each recipe
      for (final jsonRecipe in recipesToImport) {
        final id = const Uuid().v4();
        final now = DateTime.now().millisecondsSinceEpoch;

        // Convert ingredients to our app format
        List<Ingredient> ingredients = [];
        if (jsonRecipe['ingredients'] != null) {
          int index = 0;
          ingredients = (jsonRecipe['ingredients'] as List).map((item) {
            final ingredientId = const Uuid().v4();
            // Handle quantity safely - could be number, string, or null
            String? quantityString;
            if (item['quantity'] != null) {
              quantityString = item['quantity'].toString();
            }

            return Ingredient(
              id: ingredientId,
              name: item['ingredient'] ?? '',
              type: 'ingredient',  // Default to ingredient type
              primaryAmount1Value: quantityString,
              primaryAmount1Unit: item['unit']?.toString(),  // Convert possible null to string safely
              // All other fields are optional and can be left as their defaults/null
            );
          }).toList();
        }

        // Convert directions to steps
        List<Step> steps = [];
        if (jsonRecipe['directions'] != null) {
          int index = 0;
          steps = (jsonRecipe['directions'] as List).map((instruction) {
            final stepId = const Uuid().v4();
            return Step(
              id: stepId,
              type: 'step',  // Default to regular step, not section or timer
              text: instruction,  // The instruction text
              // No note or timer duration for imported steps
            );
          }).toList();
        }

        // Create the recipe object
        final recipeCompanion = RecipesCompanion.insert(
          id: Value(id),
          title: jsonRecipe['recipe_name'] ?? 'Untitled Recipe',
          description: Value(jsonRecipe['cuisine_path'] ?? ''),
          rating: Value(jsonRecipe['rating'] != null ? int.tryParse(jsonRecipe['rating'].toString()) : null),
          language: Value('en'),
          servings: Value(jsonRecipe['servings'] != null ? int.tryParse(jsonRecipe['servings'].toString()) : null),
          prepTime: Value(jsonRecipe['prep_time'] != null && jsonRecipe['prep_time'].toString().isNotEmpty
              ? int.tryParse(jsonRecipe['prep_time'].toString())
              : null),
          cookTime: Value(jsonRecipe['cook_time'] != null && jsonRecipe['cook_time'].toString().isNotEmpty
              ? int.tryParse(jsonRecipe['cook_time'].toString())
              : null),
          totalTime: Value(jsonRecipe['total_time'] != null && jsonRecipe['total_time'].toString().isNotEmpty
              ? int.tryParse(jsonRecipe['total_time'].toString())
              : null),
          source: Value(jsonRecipe['url'] ?? ''),
          nutrition: Value(jsonRecipe['nutrition'] ?? ''),
          generalNotes: Value('Imported from seed data'),
          userId: Supabase.instance.client.auth.currentUser?.id != null ? Value(Supabase.instance.client.auth.currentUser!.id) : const Value(null),
          householdId: Value(null),
          createdAt: Value(now),
          updatedAt: Value(now),
          ingredients: Value(ingredients),
          steps: Value(steps),
          folderIds: const Value([]),
          images: const Value([]),
        );

        try {
          await _repository.addRecipe(recipeCompanion);
          importedCount++;
        } catch(e) {
          // Handle any errors that occur during the import
          print('Error importing recipe: $e');
        }
      }

      return importedCount;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return 0;
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

/// State class for pantry recipe matches
class PantryRecipeMatchState {
  final List<RecipePantryMatch> matches;
  final bool isLoading;
  final Object? error;

  PantryRecipeMatchState({
    required this.matches,
    this.isLoading = false,
    this.error,
  });

  PantryRecipeMatchState copyWith({
    List<RecipePantryMatch>? matches,
    bool? isLoading,
    Object? error,
  }) {
    return PantryRecipeMatchState(
      matches: matches ?? this.matches,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for handling pantry recipe matches
class PantryRecipeMatchNotifier extends AsyncNotifier<PantryRecipeMatchState> {
  @override
  Future<PantryRecipeMatchState> build() async {
    return PantryRecipeMatchState(
      matches: [],
      isLoading: false,
    );
  }

  /// Find recipes that can be made with pantry items
  Future<void> findMatchingRecipes() async {
    try {
      // Handle potential null state.value
      if (state.value != null) {
        state = AsyncValue.data(state.value!.copyWith(isLoading: true));
      } else {
        state = AsyncValue.data(PantryRecipeMatchState(
          matches: [],
          isLoading: true,
        ));
      }
      
      final matches = await ref.read(recipeRepositoryProvider).findMatchingRecipesFromPantry();
      
      state = AsyncValue.data(PantryRecipeMatchState(
        matches: matches,
        isLoading: false,
      ));
    } catch (e, stack) {
      // Handle potential null state.value in the catch block too
      if (state.value != null) {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          error: e,
        ));
      } else {
        state = AsyncValue.data(PantryRecipeMatchState(
          matches: [],
          isLoading: false,
          error: e,
        ));
      }
    }
  }
}

/// Provider for pantry recipe matches
final pantryRecipeMatchProvider = AsyncNotifierProvider<PantryRecipeMatchNotifier, PantryRecipeMatchState>(
  PantryRecipeMatchNotifier.new,
);

/// Provider for finding matching pantry items for a specific recipe's ingredients
/// Takes recipeId as a parameter and returns RecipeIngredientMatches
final recipeIngredientMatchesProvider = FutureProvider.family<RecipeIngredientMatches, String>(
  (ref, recipeId) async {
    final repository = ref.read(recipeRepositoryProvider);
    return repository.findPantryMatchesForRecipe(recipeId);
  },
);


