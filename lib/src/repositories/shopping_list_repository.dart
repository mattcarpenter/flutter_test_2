import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../database/database.dart';
import '../managers/shopping_list_item_term_queue_manager.dart';

class ShoppingListRepository {
  final AppDatabase _db;
  ShoppingListItemTermQueueManager? _termQueueManager;
  
  ShoppingListRepository(this._db);
  
  set termQueueManager(ShoppingListItemTermQueueManager? manager) {
    _termQueueManager = manager;
  }

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

  Future<void> deleteList(String listId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Delete the list
    await (_db.update(_db.shoppingLists)
      ..where((t) => t.id.equals(listId)))
        .write(ShoppingListsCompanion(deletedAt: Value(now)));
    // Delete all items in the list
    await deleteItemsForList(listId);
  }

  Stream<List<ShoppingListItemEntry>> watchItems(String? listId) {
    return (_db.select(_db.shoppingListItems)
      ..where((t) => listId != null 
          ? t.shoppingListId.equals(listId) & t.deletedAt.isNull()
          : t.shoppingListId.isNull() & t.deletedAt.isNull()))
        .watch();
  }

  Future<String> addItem({
    String? shoppingListId,
    required String name,
    String? userId,
    String? householdId,
    List<String>? terms,
    String? category,
    String? sourceRecipeId,
    double? amount,
    String? unit,
    bool? bought,
  }) async {
    final newId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = ShoppingListItemsCompanion.insert(
      id: Value(newId),
      shoppingListId: Value(shoppingListId),
      name: name,
      userId: Value(userId),
      householdId: Value(householdId),
      terms: Value(terms),
      category: Value(category),
      sourceRecipeId: Value(sourceRecipeId),
      amount: Value(amount),
      bought: Value(bought ?? false),
      unit: Value(unit),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    await _db.into(_db.shoppingListItems).insert(companion);
    
    // Queue for term canonicalization if terms are not already provided
    if (terms == null || terms.isEmpty) {
      await _termQueueManager?.queueShoppingListItem(
        shoppingListItemId: newId,
        name: name,
        userId: userId,
        amount: amount,
        unit: unit,
      );
    }
    
    return newId;
  }

  Future<void> updateItem({
    required String itemId,
    String? name,
    List<String>? terms,
    String? category,
    String? sourceRecipeId,
    double? amount,
    String? unit,
    bool? bought,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = ShoppingListItemsCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      terms: terms != null
          ? Value(terms)
          : const Value.absent(),
      category: category != null
          ? Value(category)
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
    
    await (_db.update(_db.shoppingListItems)
      ..where((t) => t.id.equals(itemId)))
        .write(companion);
        
    // If name was updated and no terms provided, queue for canonicalization
    if (name != null && (terms == null || terms.isEmpty)) {
      // Get the updated item to get user info for canonicalization
      final item = await (_db.select(_db.shoppingListItems)
        ..where((t) => t.id.equals(itemId)))
        .getSingleOrNull();
        
      if (item != null) {
        await _termQueueManager?.queueShoppingListItem(
          shoppingListItemId: itemId,
          name: name,
          userId: item.userId,
          amount: amount ?? item.amount,
          unit: unit ?? item.unit,
        );
      }
    }
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

  // Bulk operations
  Future<void> markMultipleBought(List<String> itemIds, {bool bought = true}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.shoppingListItems)
      ..where((t) => t.id.isIn(itemIds)))
        .write(ShoppingListItemsCompanion(
      bought: Value(bought),
      updatedAt: Value(now),
    ));
  }

  Future<void> deleteMultipleItems(List<String> itemIds) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.shoppingListItems)
      ..where((t) => t.id.isIn(itemIds)))
        .write(ShoppingListItemsCompanion(deletedAt: Value(now)));
  }

  // Delete all items for a list when the list is deleted
  Future<void> deleteItemsForList(String listId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.shoppingListItems)
      ..where((t) => t.shoppingListId.equals(listId)))
        .write(ShoppingListItemsCompanion(deletedAt: Value(now)));
  }
}
