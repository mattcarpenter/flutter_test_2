import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/database.dart';
import '../repositories/recipe_repository.dart';
import '../services/recently_viewed_service.dart';

/// Notifier for managing recently viewed recipes.
/// Converts stored recipe IDs to full RecipeEntry objects and filters out deleted recipes.
class RecentlyViewedNotifier extends StateNotifier<AsyncValue<List<RecipeEntry>>> {
  final RecipeRepository _recipeRepository;
  final RecentlyViewedRecipesService _service;
  StreamSubscription<List<RecipeEntry>>? _recipesSubscription;

  RecentlyViewedNotifier(this._recipeRepository, this._service) 
      : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // Watch all recipes to detect changes/deletions
    _recipesSubscription = _recipeRepository.watchAllRecipes().listen(
      (allRecipes) async {
        await _refreshRecentlyViewed(allRecipes);
      },
      onError: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );
  }

  Future<void> _refreshRecentlyViewed(List<RecipeEntry> allRecipes) async {
    try {
      final recentIds = await _service.getRecentlyViewedRecipeIds();
      
      if (recentIds.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }

      // Create a map for efficient lookup
      final recipeMap = <String, RecipeEntry>{};
      for (final recipe in allRecipes) {
        recipeMap[recipe.id] = recipe;
      }

      // Filter recently viewed IDs to only include existing recipes
      final validRecipes = <RecipeEntry>[];
      final validIds = <String>[];
      
      for (final id in recentIds) {
        final recipe = recipeMap[id];
        if (recipe != null) {
          validRecipes.add(recipe);
          validIds.add(id);
        }
      }

      // Update stored IDs to remove deleted recipes
      if (validIds.length != recentIds.length) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('recently_viewed_recipes', validIds);
      }

      state = AsyncValue.data(validRecipes);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Adds a recipe to the recently viewed list.
  Future<void> addRecentlyViewed(String recipeId) async {
    await _service.addRecentlyViewed(recipeId);
    // Manually trigger refresh since SharedPreferences changes don't trigger recipe stream
    final allRecipes = await _recipeRepository.watchAllRecipes().first;
    await _refreshRecentlyViewed(allRecipes);
  }

  /// Removes a recipe from the recently viewed list.
  Future<void> removeRecentlyViewed(String recipeId) async {
    await _service.removeRecentlyViewed(recipeId);
    // Manually trigger refresh since SharedPreferences changes don't trigger recipe stream
    final allRecipes = await _recipeRepository.watchAllRecipes().first;
    await _refreshRecentlyViewed(allRecipes);
  }

  /// Clears all recently viewed recipes.
  Future<void> clearRecentlyViewed() async {
    await _service.clearRecentlyViewed();
    state = const AsyncValue.data([]);
  }

  @override
  void dispose() {
    _recipesSubscription?.cancel();
    super.dispose();
  }
}

// Service provider
final recentlyViewedServiceProvider = Provider<RecentlyViewedRecipesService>((ref) {
  return RecentlyViewedRecipesService();
});

// Recently viewed recipes provider
final recentlyViewedProvider = StateNotifierProvider<RecentlyViewedNotifier, AsyncValue<List<RecipeEntry>>>((ref) {
  final recipeRepository = ref.watch(recipeRepositoryProvider);
  final service = ref.watch(recentlyViewedServiceProvider);
  return RecentlyViewedNotifier(recipeRepository, service);
});

// Helper provider for getting last N recently viewed recipes (for sections)
final recentlyViewedLimitedProvider = Provider.family<AsyncValue<List<RecipeEntry>>, int>((ref, limit) {
  final recentlyViewed = ref.watch(recentlyViewedProvider);
  return recentlyViewed.when(
    data: (recipes) => AsyncValue.data(recipes.take(limit).toList()),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});