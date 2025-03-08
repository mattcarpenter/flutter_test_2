// lib/repositories/recipe_repository.dart

import 'dart:async';
import '../../database/database.dart';
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
    return _db.select(_db.recipes).watch().asyncMap((recipes) async {
      List<RecipeWithFolders> list = [];
      for (final recipe in recipes) {
        // Get all folder assignments for this recipe.
        final assignments = await (_db.select(_db.recipeFolderAssignments)
          ..where((tbl) => tbl.recipeId.equals(recipe.id))).get();

        final List<RecipeFolderDetail> folderDetails = [];
        for (final assignment in assignments) {
          // Get folder details from recipe_folders table.
          final folder = await (_db.select(_db.recipeFolders)
            ..where((tbl) => tbl.id.equals(assignment.folderId))).getSingleOrNull();
          if (folder != null) {
            folderDetails.add(RecipeFolderDetail(
              assignment: assignment,
              folder: folder,
            ));
          }
        }

        list.add(RecipeWithFolders(
          recipe: recipe,
          folderDetails: folderDetails,
        ));
      }
      return list;
    });
  }
}
