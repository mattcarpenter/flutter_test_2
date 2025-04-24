import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../database/database.dart';

class PantryRepository {
  final AppDatabase _db;
  PantryRepository(this._db);

  /// Watch all pantry items that are not deleted.
  Stream<List<PantryItemEntry>> watchItems() {
    return (_db.select(_db.pantryItems)
      ..where((t) => t.deletedAt.isNull()))
        .watch();
  }

  /// Create a new pantry item. Returns the new item's ID.
  Future<String> addItem({
    required String name,
    bool inStock = true,
    String? userId,
    String? householdId,
  }) async {
    final newId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = PantryItemsCompanion.insert(
      id: Value(newId),
      name: name,
      inStock: Value(inStock),
      userId: Value(userId),
      householdId: Value(householdId),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    await _db.into(_db.pantryItems).insert(companion);
    return newId;
  }

  /// Update an existing pantry item.
  Future<void> updateItem({
    required String id,
    String? name,
    bool? inStock,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = PantryItemsCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      inStock: inStock != null ? Value(inStock) : const Value.absent(),
      updatedAt: Value(now),
    );
    return (_db.update(_db.pantryItems)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  /// Soft-delete a pantry item.
  Future<void> deleteItem(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.pantryItems)..where((t) => t.id.equals(id)))
        .write(PantryItemsCompanion(deletedAt: Value(now)));
  }
}
