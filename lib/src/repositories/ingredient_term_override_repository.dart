import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/database/database.dart';
import '../../database/powersync.dart';
import '../../main.dart'; // For appDb access

class IngredientTermOverrideRepository {
  final AppDatabase _db;

  IngredientTermOverrideRepository(this._db);

  Stream<List<IngredientTermOverrideEntry>> watchOverrides() {
    return (_db.select(_db.ingredientTermOverrides)
      ..where((tbl) => tbl.deletedAt.isNull())
    ).watch();
  }

  Future<int> addOverride({
    required String inputTerm,
    required String mappedTerm,
    String? userId,
    String? householdId,
  }) {
    return _db.into(_db.ingredientTermOverrides).insert(
      IngredientTermOverridesCompanion.insert(
        inputTerm: inputTerm,
        mappedTerm: mappedTerm,
        userId: Value(userId),
        householdId: Value(householdId),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<int> deleteOverrideById(String id) {
    return (_db.update(_db.ingredientTermOverrides)
      ..where((tbl) => tbl.id.equals(id))
    ).write(
      IngredientTermOverridesCompanion(
        deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}

final ingredientTermOverrideRepositoryProvider = Provider<IngredientTermOverrideRepository>((ref) {
  return IngredientTermOverrideRepository(appDb);
});
