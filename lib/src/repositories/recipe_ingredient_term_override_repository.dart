import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/database/database.dart';
import '../../database/powersync.dart';
import '../../main.dart'; // For appDb access

class RecipeIngredientTermOverrideRepository {
  final AppDatabase _db;

  RecipeIngredientTermOverrideRepository(this._db);

  Stream<List<RecipeIngredientTermOverrideEntry>> watchOverridesForRecipe(String recipeId) {
    return (_db.select(_db.recipeIngredientTermOverrides)
      ..where((tbl) => tbl.recipeId.equals(recipeId) & tbl.deletedAt.isNull())
    ).watch();
  }

  Future<int> addOverride({
    required String recipeId,
    required String term,
    required String pantryItemId,
    String? userId,
    String? householdId,
  }) {
    return _db.into(_db.recipeIngredientTermOverrides).insert(
      RecipeIngredientTermOverridesCompanion.insert(
        recipeId: recipeId,
        term: term,
        pantryItemId: pantryItemId,
        userId: Value(userId),
        householdId: Value(householdId),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<int> deleteOverrideById(String id) {
    return (_db.update(_db.recipeIngredientTermOverrides)
      ..where((tbl) => tbl.id.equals(id))
    ).write(
      RecipeIngredientTermOverridesCompanion(
        deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}

final recipeIngredientTermOverrideRepositoryProvider = Provider<RecipeIngredientTermOverrideRepository>((ref) {
  return RecipeIngredientTermOverrideRepository(appDb);
});
