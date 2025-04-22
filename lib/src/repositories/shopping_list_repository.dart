import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../database/database.dart';

class ShoppingListRepository {
  final AppDatabase _db;
  ShoppingListRepository(this._db);

  Stream<List<ShoppingListEntry>> watchLists() {
    return (_db.select(_db.shoppingLists)
      ..where((t) => t.deletedAt.isNull()))
        .watch();
  }

  Future<String> createList({
    String? userId,
    String? householdId,
    String? name,
  }) async {
    final newId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = ShoppingListsCompanion.insert(
      id: Value(newId),
      userId: Value(userId),
      householdId: Value(householdId),
      name: Value(name),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    await _db.into(_db.shoppingLists).insert(companion);
    return newId;
  }

  Future<void> renameList(String listId, String newName) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.shoppingLists)
      ..where((t) => t.id.equals(listId)))
        .write(ShoppingListsCompanion(
      name: Value(newName),
      updatedAt: Value(now),
    ));
  }

  Future<void> deleteList(String listId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.shoppingLists)
      ..where((t) => t.id.equals(listId)))
        .write(ShoppingListsCompanion(deletedAt: Value(now)));
  }

  Stream<List<ShoppingListItemEntry>> watchItems(String listId) {
    return (_db.select(_db.shoppingListItems)
      ..where((t) =>
      t.shoppingListId.equals(listId) & t.deletedAt.isNull()))
        .watch();
  }

  Future<String> addItem({
    required String shoppingListId,
    required String name,
    String? userId,
    String? householdId,
    List<String>? normalizedTerms,
    String? sourceRecipeId,
    double? amount,
    String? unit,
  }) async {
    final newId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = ShoppingListItemsCompanion.insert(
      id: Value(newId),
      shoppingListId: shoppingListId,
      name: name,
      userId: Value(userId),
      householdId: Value(householdId),
      normalizedTerms: Value(normalizedTerms),
      sourceRecipeId: Value(sourceRecipeId),
      amount: Value(amount),
      unit: Value(unit),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    await _db.into(_db.shoppingListItems).insert(companion);
    return newId;
  }

  Future<void> updateItem({
    required String itemId,
    String? name,
    List<String>? normalizedTerms,
    String? sourceRecipeId,
    double? amount,
    String? unit,
    bool? bought,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = ShoppingListItemsCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      normalizedTerms: normalizedTerms != null
          ? Value(normalizedTerms)
          : const Value.absent(),
      sourceRecipeId: sourceRecipeId != null
          ? Value(sourceRecipeId)
          : const Value.absent(),
      amount:
      amount != null ? Value(amount) : const Value.absent(),
      unit: unit != null ? Value(unit) : const Value.absent(),
      bought:
      bought != null ? Value(bought) : const Value.absent(),
      updatedAt: Value(now),
    );
    return (_db.update(_db.shoppingListItems)
      ..where((t) => t.id.equals(itemId)))
        .write(companion);
  }

  Future<void> deleteItem(String itemId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.shoppingListItems)
      ..where((t) => t.id.equals(itemId)))
        .write(ShoppingListItemsCompanion(deletedAt: Value(now)));
  }

  Future<void> markBought(String itemId, {bool bought = true}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.shoppingListItems)
      ..where((t) => t.id.equals(itemId)))
        .write(ShoppingListItemsCompanion(
      bought: Value(bought),
      updatedAt: Value(now),
    ));
  }
}
