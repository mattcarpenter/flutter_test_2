// lib/repositories/recipe_repository.dart

import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/converters.dart';
import '../../database/database.dart';
import '../../database/models/ingredients.dart';
import '../../database/models/recipe_images.dart';
import '../../database/models/steps.dart';
import '../../database/powersync.dart';
import '../models/recipe_with_folders.dart';

class RecipeRepository {
  final AppDatabase _db;

  RecipeRepository(this._db);

  // Watch all recipes.
  Stream<List<RecipeEntry>> watchAllRecipes() {
    return _db.select(_db.recipes).watch();
  }

  // Insert a new recipe.
  Future<int> addRecipe(RecipesCompanion recipe) {
    return _db.into(_db.recipes).insert(recipe);
  }

  // Update a recipe.
  Future<bool> updateRecipe(RecipeEntry recipe) {
    return _db.update(_db.recipes).replace(recipe);
  }

  Future<RecipeEntry?> getRecipeById(String id) {
    return (_db.select(_db.recipes)
      ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  // lib/repositories/recipe_repository.dart
  Future<bool> updateImageForRecipe({
    required String recipeId,
    required String fileName,
    required String publicUrl,
  }) async {
    // Query the recipe using recipeId.
    final recipe = await (_db.select(_db.recipes)
      ..where((tbl) => tbl.id.equals(recipeId)))
        .getSingle();

    // Get the current images list.
    final List<RecipeImage> images = recipe.images ?? [];

    // Update the image that matches fileName.
    final updatedImages = images.map((img) {
      if (img.fileName == fileName) {
        return img.copyWith(publicUrl: publicUrl);
      }
      return img;
    }).toList();

    // Create an updated copy of the recipe.
    final updatedRecipe = recipe.copyWith(images: Value(updatedImages));

    // Update the recipe in the database.
    return updateRecipe(updatedRecipe);
  }

  // Soft delete a recipe using the deletedAt timestamp
  Future<bool> deleteRecipe(String id) async {
    final recipe = await getRecipeById(id);
    if (recipe != null) {
      final updatedRecipe = recipe.copyWith(deletedAt: Value(DateTime.now().millisecondsSinceEpoch));
      return updateRecipe(updatedRecipe);
    }
    return false;
  }

  // Helper: Add a folder assignment to a recipe by updating its folder_ids array.
  Future<void> addFolderToRecipe({
    required String recipeId,
    required String folderId,
  }) async {
    // Fetch the recipe record.
    final recipe = await (_db.select(_db.recipes)
      ..where((tbl) => tbl.id.equals(recipeId)))
        .getSingle();
    // Assuming folderIds is converted to List<String> using a custom type converter.
    final currentFolderIds = recipe.folderIds ?? <String>[];
    if (!currentFolderIds.contains(folderId)) {
      final updatedFolderIds = List<String>.from(currentFolderIds)..add(folderId);
      // Create an updated copy of the recipe.
      final updatedRecipe = recipe.copyWith(folderIds: Value(updatedFolderIds));
      await updateRecipe(updatedRecipe);
    }
  }

  // Helper: Remove a folder assignment from a recipe.
  Future<void> removeFolderFromRecipe({
    required String recipeId,
    required String folderId,
  }) async {
    final recipe = await (_db.select(_db.recipes)
      ..where((tbl) => tbl.id.equals(recipeId)))
        .getSingle();
    final currentFolderIds = recipe.folderIds ?? <String>[];
    if (currentFolderIds.contains(folderId)) {
      final updatedFolderIds = List<String>.from(currentFolderIds)..remove(folderId);
      final updatedRecipe = recipe.copyWith(folderIds: Value(updatedFolderIds));
      await updateRecipe(updatedRecipe);
    }
  }

  // Batch update: Replace the entire ingredients package for a recipe.
  Future<bool> updateIngredients(String recipeId, List<Ingredient> ingredients) async {
    final recipe = await (_db.select(_db.recipes)
      ..where((tbl) => tbl.id.equals(recipeId)))
        .getSingle();
    final updatedRecipe = recipe.copyWith(ingredients: Value(ingredients));
    return updateRecipe(updatedRecipe);
  }

  // Batch update: Replace the entire steps package for a recipe.
  Future<bool> updateSteps(String recipeId, List<Step> steps) async {
    final recipe = await (_db.select(_db.recipes)
      ..where((tbl) => tbl.id.equals(recipeId)))
        .getSingle();
    final updatedRecipe = recipe.copyWith(steps: Value(steps));
    return updateRecipe(updatedRecipe);
  }

  // Watch recipes along with their folder details.
  // Update this method if you have a different strategy now to retrieve folder details.
  // For instance, you may need to join recipes with recipe_folders by checking if folderIds contains the folder's id.
  Stream<List<RecipeWithFolders>> watchRecipesWithFolders() {
    final query = _db.customSelect(
      '''
    SELECT 
      r.id AS recipe_id, 
      r.title AS recipe_title,
      r.description AS recipe_description,
      r.rating AS recipe_rating,
      r.language AS recipe_language,
      r.servings AS recipe_servings,
      r.prep_time AS recipe_prep_time,
      r.cook_time AS recipe_cook_time,
      r.total_time AS recipe_total_time,
      r.source AS recipe_source,
      r.nutrition AS recipe_nutrition,
      r.general_notes AS recipe_general_notes,
      r.user_id AS recipe_user_id,
      r.household_id AS recipe_household_id,
      r.created_at AS recipe_created_at,
      r.updated_at AS recipe_updated_at,
      r.ingredients AS recipe_ingredients,
      r.steps AS recipe_steps,
      r.folder_ids AS recipe_folder_ids,
      r.images AS recipe_images,
      r.deleted_at AS recipe_deleted_at,
      
      f.id AS folder_id, 
      f.name AS folder_name,
      f.deleted_at AS folder_deleted_at
    FROM recipes r
    LEFT JOIN recipe_folders f 
      ON f.id IN (SELECT value FROM json_each(r.folder_ids))
    WHERE r.deleted_at IS NULL
    ORDER BY r.created_at, r.id DESC
    ''',
      readsFrom: {
        _db.recipes,
        _db.recipeFolders,
      },
    ).watch();

    return query.map((rows) {
      // Group rows by recipe id.
      final Map<String, RecipeWithFolders> recipeMap = {};
      for (final row in rows) {
        final recipeId = row.read<String>('recipe_id');
        if (!recipeMap.containsKey(recipeId)) {
          // Build the RecipeEntry.
          final recipe = RecipeEntry(
            id: recipeId,
            title: row.read<String>('recipe_title'),
            description: row.read<String?>('recipe_description') ?? '',
            rating: row.read<int?>('recipe_rating'),
            language: row.read<String>('recipe_language'),
            servings: row.read<int?>('recipe_servings'),
            prepTime: row.read<int?>('recipe_prep_time'),
            cookTime: row.read<int?>('recipe_cook_time'),
            totalTime: row.read<int?>('recipe_total_time'),
            source: row.read<String?>('recipe_source'),
            nutrition: row.read<String?>('recipe_nutrition'),
            generalNotes: row.read<String?>('recipe_general_notes'),
            userId: row.read<String>('recipe_user_id'),
            householdId: row.read<String?>('recipe_household_id'),
            createdAt: row.read<int?>('recipe_created_at'),
            updatedAt: row.read<int?>('recipe_updated_at'),
            deletedAt: row.read<int?>('recipe_deleted_at'),

            // Convert JSON String to List<Ingredient>
            ingredients: row.read<String?>('recipe_ingredients') != null
                ? const IngredientListConverter().fromSql(row.read<String>('recipe_ingredients'))
                : [],

            // Convert JSON String to List<Step>
            steps: row.read<String?>('recipe_steps') != null
                ? const StepListConverter().fromSql(row.read<String>('recipe_steps'))
                : [],

            images: row.read<String?>('recipe_images') != null
                ? const RecipeImageListConverter().fromSql(row.read<String>('recipe_images'))
                : [],

            folderIds: List<String>.from(jsonDecode(row.read<String>('recipe_folder_ids'))),
          );
          recipeMap[recipeId] = RecipeWithFolders(recipe: recipe, folders: []);
        }
        // If a folder is joined, add it to the composite.
        final folderId = row.read<String?>('folder_id');
        if (folderId != null) {
          final folder = RecipeFolderEntry(
            id: folderId,
            name: row.read<String>('folder_name'),
            deletedAt: row.read<int?>('folder_deleted_at'),
          );
          recipeMap[recipeId]!.folders.add(folder);
        }
      }
      return recipeMap.values.toList();
    });
  }

  // Add this to your RecipeRepository class
  Stream<List<RecipeWithFolders>> watchRecipesByFolderId(String folderId) {
    final query = _db.customSelect(
      '''
    SELECT 
      r.id AS recipe_id, 
      r.title AS recipe_title,
      r.description AS recipe_description,
      r.rating AS recipe_rating,
      r.language AS recipe_language,
      r.servings AS recipe_servings,
      r.prep_time AS recipe_prep_time,
      r.cook_time AS recipe_cook_time,
      r.total_time AS recipe_total_time,
      r.source AS recipe_source,
      r.nutrition AS recipe_nutrition,
      r.general_notes AS recipe_general_notes,
      r.user_id AS recipe_user_id,
      r.household_id AS recipe_household_id,
      r.created_at AS recipe_created_at,
      r.updated_at AS recipe_updated_at,
      r.ingredients AS recipe_ingredients,
      r.steps AS recipe_steps,
      r.folder_ids AS recipe_folder_ids,
      r.images AS recipe_images,
      r.deleted_at AS recipe_deleted_at,
      
      f.id AS folder_id, 
      f.name AS folder_name,
      f.deleted_at AS folder_deleted_at
    FROM recipes r
    LEFT JOIN recipe_folders f 
      ON f.id IN (SELECT value FROM json_each(r.folder_ids))
    WHERE (json_array_contains(r.folder_ids, ?)
    OR (? IS NULL AND r.folder_ids IS NULL))
    AND r.deleted_at IS NULL
    ORDER BY r.created_at, r.id DESC
    ''',
      variables: [
        Variable(folderId),
        Variable(folderId)
      ],
      readsFrom: {
        _db.recipes,
        _db.recipeFolders,
      },
    ).watch();

    return query.map((rows) {
      // Group rows by recipe id
      final Map<String, RecipeWithFolders> recipeMap = {};
      for (final row in rows) {
        final recipeId = row.read<String>('recipe_id');
        if (!recipeMap.containsKey(recipeId)) {
          // Build the RecipeEntry
          final recipe = RecipeEntry(
            id: recipeId,
            title: row.read<String>('recipe_title'),
            description: row.read<String?>('recipe_description') ?? '',
            rating: row.read<int?>('recipe_rating'),
            language: row.read<String>('recipe_language'),
            servings: row.read<int?>('recipe_servings'),
            prepTime: row.read<int?>('recipe_prep_time'),
            cookTime: row.read<int?>('recipe_cook_time'),
            totalTime: row.read<int?>('recipe_total_time'),
            source: row.read<String?>('recipe_source'),
            nutrition: row.read<String?>('recipe_nutrition'),
            generalNotes: row.read<String?>('recipe_general_notes'),
            userId: row.read<String>('recipe_user_id'),
            householdId: row.read<String?>('recipe_household_id'),
            createdAt: row.read<int?>('recipe_created_at'),
            updatedAt: row.read<int?>('recipe_updated_at'),
            deletedAt: row.read<int?>('recipe_deleted_at'),

            // Convert JSON String to List<Ingredient>
            ingredients: row.read<String?>('recipe_ingredients') != null
                ? const IngredientListConverter().fromSql(row.read<String>('recipe_ingredients'))
                : [],

            // Convert JSON String to List<Step>
            steps: row.read<String?>('recipe_steps') != null
                ? const StepListConverter().fromSql(row.read<String>('recipe_steps'))
                : [],

            folderIds: row.read<String?>('recipe_folder_ids') != null
                ? List<String>.from(jsonDecode(row.read<String>('recipe_folder_ids')))
                : [],

            images: row.read<String?>('recipe_images') != null
                ? const RecipeImageListConverter().fromSql(row.read<String>('recipe_images'))
                : [],
          );
          recipeMap[recipeId] = RecipeWithFolders(recipe: recipe, folders: []);
        }

        // If a folder is joined, add it to the composite
        final folderId = row.read<String?>('folder_id');
        if (folderId != null) {
          final folder = RecipeFolderEntry(
            id: folderId,
            name: row.read<String>('folder_name'),
            deletedAt: row.read<int?>('folder_deleted_at'),
          );
          recipeMap[recipeId]!.folders.add(folder);
        }
      }
      return recipeMap.values.toList();
    });
  }

  Stream<RecipeEntry?> watchRecipeById(String id) {
    return (_db.select(_db.recipes)
      ..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }
}

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(appDb);
});
