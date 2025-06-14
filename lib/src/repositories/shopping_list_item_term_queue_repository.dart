import 'package:drift/drift.dart';
import '../../database/database.dart';

class ShoppingListItemTermQueueRepository {
  final AppDatabase _db;

  ShoppingListItemTermQueueRepository(this._db);

  // Get all pending entries
  Stream<List<ShoppingListItemTermQueueEntry>> watchPendingEntries() {
    return (_db.select(_db.shoppingListItemTermQueues)
          ..where((tbl) => tbl.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .watch();
  }

  // Get entry by shopping list item ID
  Future<ShoppingListItemTermQueueEntry?> getEntryByShoppingListItemId(String itemId) async {
    return (_db.select(_db.shoppingListItemTermQueues)
          ..where((tbl) => tbl.shoppingListItemId.equals(itemId)))
        .getSingleOrNull();
  }

  // Add new entry to queue
  Future<void> addEntry({
    required String shoppingListItemId,
    required String name,
    String? userId,
    double? amount,
    String? unit,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Check if entry already exists
    final existing = await getEntryByShoppingListItemId(shoppingListItemId);
    
    if (existing != null) {
      // Update existing entry
      await updateEntry(
        shoppingListItemId: shoppingListItemId,
        status: 'pending',
        retryCount: 0,
      );
    } else {
      // Insert new entry
      await _db.into(_db.shoppingListItemTermQueues).insert(
        ShoppingListItemTermQueuesCompanion.insert(
          shoppingListItemId: shoppingListItemId,
          name: name,
          userId: Value(userId),
          amount: Value(amount),
          unit: Value(unit),
          status: const Value('pending'),
          retryCount: const Value(0),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    }
  }

  // Update entry status
  Future<void> updateEntry({
    required String shoppingListItemId,
    required String status,
    int? retryCount,
    String? error,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await (_db.update(_db.shoppingListItemTermQueues)
          ..where((tbl) => tbl.shoppingListItemId.equals(shoppingListItemId)))
        .write(
      ShoppingListItemTermQueuesCompanion(
        status: Value(status),
        retryCount: retryCount != null ? Value(retryCount) : const Value.absent(),
        error: error != null ? Value(error) : const Value.absent(),
        updatedAt: Value(now),
      ),
    );
  }

  // Delete entry
  Future<void> deleteEntry(String shoppingListItemId) async {
    await (_db.delete(_db.shoppingListItemTermQueues)
          ..where((tbl) => tbl.shoppingListItemId.equals(shoppingListItemId)))
        .go();
  }

  // Get all entries that need retry
  Future<List<ShoppingListItemTermQueueEntry>> getRetryableEntries(int maxRetries) async {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
    
    return await (_db.select(_db.shoppingListItemTermQueues)
          ..where((tbl) => 
              tbl.status.equals('failed') & 
              tbl.retryCount.isSmallerThanValue(maxRetries) &
              tbl.updatedAt.isSmallerThanValue(oneHourAgo)))
        .get();
  }

  // Reset failed entries
  Future<void> resetFailedEntries() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await (_db.update(_db.shoppingListItemTermQueues)
          ..where((tbl) => tbl.status.equals('failed')))
        .write(
      const ShoppingListItemTermQueuesCompanion(
        status: Value('pending'),
        retryCount: Value(0),
        error: Value(null),
      ),
    );
  }
}