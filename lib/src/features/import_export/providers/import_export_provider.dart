import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/import_service.dart';
import '../services/export_service.dart';
import '../../../repositories/recipe_repository.dart';
import '../../../repositories/recipe_tag_repository.dart';
import '../../../repositories/recipe_folder_repository.dart';

/// Provider for ExportService
final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

/// Provider for ImportService with dependencies
final importServiceProvider = Provider<ImportService>((ref) {
  final recipeRepo = ref.watch(recipeRepositoryProvider);
  final tagRepo = ref.watch(recipeTagRepositoryProvider);
  final folderRepo = ref.watch(recipeFolderRepositoryProvider);

  return ImportService(
    recipeRepository: recipeRepo,
    tagRepository: tagRepo,
    folderRepository: folderRepo,
  );
});

/// Provider for getting all recipes in export format
final exportRecipesProvider = FutureProvider<List<RecipeExportData>>((ref) async {
  final recipeRepo = ref.watch(recipeRepositoryProvider);
  final tagRepo = ref.watch(recipeTagRepositoryProvider);
  final folderRepo = ref.watch(recipeFolderRepositoryProvider);

  // Get all recipes
  final recipesStream = recipeRepo.watchAllRecipes();
  final recipes = await recipesStream.first;

  // Get tags and folders for name resolution
  final tags = await tagRepo.watchTags().first;
  final folders = await folderRepo.watchFolders().first;

  // Build lookup maps
  final tagIdToName = {for (final t in tags) t.id: t.name};
  final folderIdToName = {for (final f in folders) f.id: f.name};

  // Convert to RecipeExportData
  return recipes.map((recipe) {
    return RecipeExportData(
      id: recipe.id,
      title: recipe.title,
      description: recipe.description,
      rating: recipe.rating,
      language: recipe.language,
      servings: recipe.servings,
      prepTime: recipe.prepTime,
      cookTime: recipe.cookTime,
      totalTime: recipe.totalTime,
      source: recipe.source,
      nutrition: recipe.nutrition,
      generalNotes: recipe.generalNotes,
      createdAt: recipe.createdAt,
      updatedAt: recipe.updatedAt,
      pinned: recipe.pinned == 1,
      folderNames: (recipe.folderIds ?? [])
          .map((id) => folderIdToName[id])
          .where((name) => name != null)
          .cast<String>()
          .toList(),
      tagNames: (recipe.tagIds ?? [])
          .map((id) => tagIdToName[id])
          .where((name) => name != null)
          .cast<String>()
          .toList(),
      ingredients: recipe.ingredients,
      steps: recipe.steps,
      images: recipe.images,
    );
  }).toList();
});
