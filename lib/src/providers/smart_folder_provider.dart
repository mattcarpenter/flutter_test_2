import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../models/ingredient_term_search_result.dart';
import '../repositories/recipe_folder_repository.dart';
import 'recipe_folder_provider.dart';

/// Provider for recipes in a smart folder
final smartFolderRecipesProvider = FutureProvider.family<List<RecipeEntry>, RecipeFolderEntry>((ref, folder) async {
  final folderRepo = ref.watch(recipeFolderRepositoryProvider);

  if (folder.folderType == 1) {
    // Tag-based smart folder
    final tags = folder.smartFilterTags != null
      ? (jsonDecode(folder.smartFilterTags!) as List).cast<String>()
      : <String>[];
    if (tags.isEmpty) return [];

    return folderRepo.getRecipesForTagSmartFolder(
      tagNames: tags,
      matchAll: folder.filterLogic == 1,
    );
  } else if (folder.folderType == 2) {
    // Ingredient-based smart folder
    final terms = folder.smartFilterTerms != null
      ? (jsonDecode(folder.smartFilterTerms!) as List).cast<String>()
      : <String>[];
    if (terms.isEmpty) return [];

    return folderRepo.getRecipesForIngredientSmartFolder(
      terms: terms,
      matchAll: folder.filterLogic == 1,
    );
  }

  return [];
});

/// Provider for ingredient term search results
final ingredientTermSearchProvider = FutureProvider.family<List<IngredientTermSearchResult>, String>((ref, query) async {
  final repo = ref.watch(recipeFolderRepositoryProvider);
  return repo.searchIngredientTerms(query);
});

/// Provider that returns recipe counts for all smart folders
/// Returns a map of folder ID to recipe count
final smartFolderCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final folderRepo = ref.watch(recipeFolderRepositoryProvider);
  final foldersAsync = ref.watch(recipeFolderNotifierProvider);

  final Map<String, int> counts = {};

  final folders = foldersAsync.valueOrNull ?? [];

  for (final folder in folders) {
    // Only process smart folders
    if (folder.folderType == 0) continue;

    if (folder.folderType == 1) {
      // Tag-based smart folder
      final tags = folder.smartFilterTags != null
        ? (jsonDecode(folder.smartFilterTags!) as List).cast<String>()
        : <String>[];
      if (tags.isEmpty) {
        counts[folder.id] = 0;
        continue;
      }

      final recipes = await folderRepo.getRecipesForTagSmartFolder(
        tagNames: tags,
        matchAll: folder.filterLogic == 1,
      );
      counts[folder.id] = recipes.length;
    } else if (folder.folderType == 2) {
      // Ingredient-based smart folder
      final terms = folder.smartFilterTerms != null
        ? (jsonDecode(folder.smartFilterTerms!) as List).cast<String>()
        : <String>[];
      if (terms.isEmpty) {
        counts[folder.id] = 0;
        continue;
      }

      final recipes = await folderRepo.getRecipesForIngredientSmartFolder(
        terms: terms,
        matchAll: folder.filterLogic == 1,
      );
      counts[folder.id] = recipes.length;
    }
  }

  return counts;
});
