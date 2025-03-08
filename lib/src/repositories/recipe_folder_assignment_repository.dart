// lib/repositories/recipe_folder_assignment_repository.dart

import 'package:drift/drift.dart';

import '../../database/database.dart';

class RecipeFolderAssignmentRepository {
  final AppDatabase _db;

  RecipeFolderAssignmentRepository(this._db);

  // Insert a new folder assignment.
  Future<int> addAssignment(RecipeFolderAssignmentsCompanion assignment) {
    return _db.into(_db.recipeFolderAssignments).insert(assignment);
  }

  // Delete a folder assignment by id.
  Future<int> deleteAssignment(String id) {
    return (_db.delete(_db.recipeFolderAssignments)
      ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  // Get assignments for a given recipe.
  Future<List<RecipeFolderAssignmentEntry>> getAssignmentsForRecipe(String recipeId) {
    return (_db.select(_db.recipeFolderAssignments)
      ..where((tbl) => tbl.recipeId.equals(recipeId)))
        .get();
  }

  // Watch all folder assignments.
  Stream<List<RecipeFolderAssignmentEntry>> watchAssignments() {
    return _db.select(_db.recipeFolderAssignments).watch();
  }
}
