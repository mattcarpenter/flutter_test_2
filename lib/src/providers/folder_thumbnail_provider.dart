import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../database/models/recipe_images.dart';
import '../constants/folder_constants.dart';
import '../providers/recipe_provider.dart';

// Provider that returns the first recipe image for a given folder ID
final folderThumbnailProvider = FutureProvider.family<RecipeImage?, String>((ref, folderId) async {
  // Keep the provider alive to prevent rebuilds
  ref.keepAlive();
  // Get all recipes
  final recipesAsyncValue = ref.watch(recipeNotifierProvider);
  
  // Wait for data to be available
  final recipesWithFolders = await recipesAsyncValue.when(
    data: (data) async => data,
    loading: () async => <dynamic>[],
    error: (error, stack) async => <dynamic>[],
  );
  
  // Extract recipes from wrapper objects
  final recipes = recipesWithFolders.map((r) => r.recipe).toList();
  
  // Apply folder filtering logic (same as FilterUtils.applyFolderFilter)
  List<RecipeEntry> filteredRecipes;
  if (folderId == kUncategorizedFolderId) {
    // Show recipes with no folder assignments
    filteredRecipes = recipes.where((recipe) {
      return recipe.folderIds == null || recipe.folderIds!.isEmpty;
    }).cast<RecipeEntry>().toList();
  } else {
    // Show recipes in the specified folder
    filteredRecipes = recipes.where((recipe) {
      return recipe.folderIds != null && recipe.folderIds!.contains(folderId);
    }).cast<RecipeEntry>().toList();
  }
  
  // Find the first recipe that has images
  for (final recipe in filteredRecipes) {
    if (recipe.images != null && recipe.images!.isNotEmpty) {
      // Return the cover image, or first image if no cover is set
      final coverImage = RecipeImage.getCoverImage(recipe.images!);
      if (coverImage != null) {
        return coverImage;
      }
      // Fallback to first image
      return recipe.images!.first;
    }
  }
  
  // No images found in any recipe
  return null;
});