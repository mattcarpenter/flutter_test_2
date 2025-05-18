import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../database/database.dart';
import '../../database/models/pantry_item_terms.dart';
import '../../database/models/pantry_items.dart'; // For StockStatus enum
import '../../database/powersync.dart';
import '../managers/pantry_item_term_queue_manager.dart';

class PantryRepository {
  final AppDatabase _db;
  PantryItemTermQueueManager? _pantryItemTermQueueManager;

  PantryRepository(this._db);

  set pantryItemTermQueueManager(PantryItemTermQueueManager manager) {
    _pantryItemTermQueueManager = manager;
  }

  /// Watch all pantry items that are not deleted.
  Stream<List<PantryItemEntry>> watchItems() {
    return (_db.select(_db.pantryItems)
      ..where((t) => t.deletedAt.isNull()))
        .watch();
  }

  /// Create a new pantry item. Returns the new item's ID.
  Future<String> addItem({
    required String name,
    StockStatus stockStatus = StockStatus.inStock,
    String? userId,
    String? householdId,
    List<PantryItemTerm>? terms,
    String? unit,
    double? quantity,
    String? baseUnit,
    double? baseQuantity,
    double? price,
  }) async {
    final newId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    // No need for converter - it's handled internally by Drift
    final companion = PantryItemsCompanion.insert(
      id: Value(newId),
      name: name,
      stockStatus: Value(stockStatus),
      userId: Value(userId),
      householdId: Value(householdId),
      unit: Value(unit),
      quantity: Value(quantity),
      baseUnit: Value(baseUnit),
      baseQuantity: Value(baseQuantity),
      price: Value(price),
      createdAt: Value(now),
      updatedAt: Value(now),
      terms: terms != null ? Value(terms) : const Value.absent(),
    );

    await _db.into(_db.pantryItems).insert(companion);

    // Queue for term canonicalization if no terms are provided
    if ((terms == null || terms.isEmpty) && _pantryItemTermQueueManager != null) {
      await _pantryItemTermQueueManager!.queuePantryItem(
        pantryItemId: newId,
        name: name,
        existingTerms: terms,
      );
    }

    return newId;
  }

  /// Update an existing pantry item.
  Future<void> updateItem({
    required String id,
    String? name,
    StockStatus? stockStatus,
    List<PantryItemTerm>? terms,
    String? unit,
    double? quantity,
    String? baseUnit,
    double? baseQuantity,
    double? price,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Get the current pantry item to check if name changed and terms need updating
    final currentItem = await (_db.select(_db.pantryItems)
      ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    final companion = PantryItemsCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      stockStatus: stockStatus != null ? Value(stockStatus) : const Value.absent(),
      unit: unit != null ? Value(unit) : const Value.absent(),
      quantity: quantity != null ? Value(quantity) : const Value.absent(),
      baseUnit: baseUnit != null ? Value(baseUnit) : const Value.absent(),
      baseQuantity: baseQuantity != null ? Value(baseQuantity) : const Value.absent(),
      price: price != null ? Value(price) : const Value.absent(),
      updatedAt: Value(now),
      terms: terms != null ? Value(terms) : const Value.absent(),
    );

    await (_db.update(_db.pantryItems)..where((t) => t.id.equals(id)))
        .write(companion);

    // Check if we need to queue for term canonicalization
    if (_pantryItemTermQueueManager != null) {
      // Queue for term canonicalization if either:
      // 1. Terms were explicitly set to empty or
      // 2. The name changed and no new terms were provided
      final nameChanged = name != null && currentItem != null && name != currentItem.name;
      final emptyTermsProvided = terms != null && terms.isEmpty;
      final hasCurrentTerms = currentItem?.terms != null && currentItem!.terms!.isNotEmpty;

      if (emptyTermsProvided || (nameChanged && terms == null && !hasCurrentTerms)) {
        final itemName = name ?? currentItem?.name ?? "";
        if (itemName.isNotEmpty) {
          // First, remove any existing queue entries
          await _pantryItemTermQueueManager!.repository.deleteEntriesByPantryItemId(id);

          // Queue the item for canonicalization
          await _pantryItemTermQueueManager!.queuePantryItem(
            pantryItemId: id,
            name: itemName,
            existingTerms: terms ?? currentItem?.terms,
          );
        }
      }
    }
  }

  /// Soft-delete a pantry item.
  Future<void> deleteItem(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Also remove any pending queue entries
    if (_pantryItemTermQueueManager != null) {
      await _pantryItemTermQueueManager!.repository.deleteEntriesByPantryItemId(id);
    }

    await (_db.update(_db.pantryItems)..where((t) => t.id.equals(id)))
        .write(PantryItemsCompanion(deletedAt: Value(now)));
  }
}

// Provider for the pantry repository
final pantryRepositoryProvider = Provider<PantryRepository>((ref) {
  final repository = PantryRepository(appDb);

  // Connect the pantry repository with the queue manager
  final queueManager = ref.watch(pantryItemTermQueueManagerProvider);
  repository.pantryItemTermQueueManager = queueManager;

  // Complete the circular dependency by setting pantry repository in the queue manager
  queueManager.pantryRepository = repository;

  return repository;
});
