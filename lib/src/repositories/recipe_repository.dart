// lib/repositories/recipe_repository.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database.dart';
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

  // Delete a recipe.
  Future<int> deleteRecipe(String id) {
    return (_db.delete(_db.recipes)..where((tbl) => tbl.id.equals(id))).go();
  }

  // Watch recipes along with their folder details.
  Stream<List<RecipeWithFolders>> watchRecipesWithFolders() {
    final query = _db.customSelect(
      '''
    SELECT 
      r.id AS recipe_id, 
      r.title AS recipe_title,
      r.description AS recipe_description,
      r.rating AS recipe_rating,
      r.language AS recipe_language,
      -- You can select additional recipe columns as needed.
      
      a.id AS assignment_id, 
      a.recipe_id AS assignment_recipe_id, 
      a.folder_id AS assignment_folder_id,
      a.user_id AS assignment_user_id, 
      -- Include household_id if needed:
      a.household_id AS assignment_household_id,
      
      f.id AS folder_id, 
      f.name AS folder_name,
      f.deleted_at AS folder_deleted_at
      -- Select additional folder columns if necessary.
    FROM recipes r
    LEFT JOIN recipe_folder_assignments a ON a.recipe_id = r.id
    LEFT JOIN recipe_folders f ON f.id = a.folder_id
    ''',
      readsFrom: {
        _db.recipes,
        _db.recipeFolderAssignments,
        _db.recipeFolders,
      },
    ).watch();

    return query.map((rows) {
      // Group the rows by recipe id.
      final Map<String, RecipeWithFolders> recipeMap = {};
      for (final row in rows) {
        final recipeId = row.read<String>('recipe_id');
        // Create a composite object for each recipe if not already present.
        if (!recipeMap.containsKey(recipeId)) {
          final recipe = RecipeEntry(
            id: recipeId,
            title: row.read<String>('recipe_title'),
            description: row.read<String?>('recipe_description') ?? '',
            rating: row.read<int>('recipe_rating'),
            language: row.read<String>('recipe_language'),
            servings: row.read<int?>('recipe_servings'),
            prepTime: row.read<int?>('recipe_prep_time'),
            cookTime: row.read<int?>('recipe_cook_time'),
            totalTime: row.read<int?>('recipe_total_time'),
            source: row.read<String?>('recipe_source'),
            nutrition: row.read<String?>('recipe_nutrition'),
            generalNotes: row.read<String?>('recipe_general_notes'),
            userId: row.read<String?>('recipe_user_id'),
            householdId: row.read<String?>('recipe_household_id'),
            createdAt: row.read<int?>('recipe_created_at'),
            updatedAt: row.read<int?>('recipe_updated_at'),
            ingredients: row.read<String?>('recipe_ingredients'),
            steps: row.read<String?>('recipe_steps'),
          );
          recipeMap[recipeId] = RecipeWithFolders(recipe: recipe, folderDetails: []);
        }
        // If an assignment exists (assignment_id is not null), add folder details.
        final assignmentId = row.read<String?>('assignment_id');
        if (assignmentId != null) {
          final assignment = RecipeFolderAssignmentEntry(
            id: assignmentId,
            recipeId: row.read<String>('assignment_recipe_id'),
            folderId: row.read<String>('assignment_folder_id'),
            userId: row.read<String>('assignment_user_id'),
            householdId: row.read<String?>('assignment_household_id'),
            createdAt: null, // Set if you select created_at column.
          );
          final folderId = row.read<String?>('folder_id');
          if (folderId != null) {
            final folder = RecipeFolderEntry(
              id: folderId,
              name: row.read<String>('folder_name'),
              deletedAt: row.read<int?>('folder_deleted_at'),
            );
            recipeMap[recipeId]!.folderDetails.add(
              RecipeFolderDetail(assignment: assignment, folder: folder),
            );
          }
        }
      }
      return recipeMap.values.toList();
    });
  }


}

// Provider for the RecipeRepository.
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(appDb);
});
