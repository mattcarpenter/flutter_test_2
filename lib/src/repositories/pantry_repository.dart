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
    bool isStaple = false,
    String? userId,
    String? householdId,
    List<PantryItemTerm>? terms,
    String? unit,
    double? quantity,
    String? baseUnit,
    double? baseQuantity,
    double? price,
    String? category,
  }) async {
    final newId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Always ensure the name is the first term for immediate matching capability
    final ensuredTerms = terms ?? [];
    final hasNameTerm = ensuredTerms.any((term) => term.value.toLowerCase() == name.toLowerCase());
    
    if (!hasNameTerm) {
      // Add name as first term
      ensuredTerms.insert(0, PantryItemTerm(
        value: name,
        source: 'user',
        sort: 0,
      ));
      
      // Reorder sort indices for existing terms
      for (int i = 1; i < ensuredTerms.length; i++) {
        ensuredTerms[i] = PantryItemTerm(
          value: ensuredTerms[i].value,
          source: ensuredTerms[i].source,
          sort: i,
        );
      }
    }

    final companion = PantryItemsCompanion.insert(
      id: Value(newId),
      name: name,
      stockStatus: Value(stockStatus),
      isStaple: Value(isStaple),
      isCanonicalised: const Value(false), // Always start as not canonicalized
      userId: Value(userId),
      householdId: Value(householdId),
      unit: Value(unit),
      quantity: Value(quantity),
      baseUnit: Value(baseUnit),
      baseQuantity: Value(baseQuantity),
      price: Value(price),
      createdAt: Value(now),
      updatedAt: Value(now),
      terms: Value(ensuredTerms), // Always has at least the name term
      category: Value(category),
    );

    await _db.into(_db.pantryItems).insert(companion);

    // Always queue for canonicalization (based on flag, not empty terms)
    if (_pantryItemTermQueueManager != null) {
      await _pantryItemTermQueueManager!.queuePantryItem(
        pantryItemId: newId,
        name: name,
        existingTerms: ensuredTerms,
        isCanonicalised: false, // Always false for new items
      );
    }

    return newId;
  }

  /// Update an existing pantry item.
  Future<void> updateItem({
    required String id,
    String? name,
    StockStatus? stockStatus,
    bool? isStaple,
    bool? isCanonicalised,
    List<PantryItemTerm>? terms,
    String? unit,
    double? quantity,
    String? baseUnit,
    double? baseQuantity,
    double? price,
    String? category,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Get the current pantry item to check if name changed and terms need updating
    final currentItem = await (_db.select(_db.pantryItems)
      ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (currentItem == null) {
      throw Exception('Pantry item with id $id not found');
    }

    // Handle name changes and term updates
    List<PantryItemTerm>? updatedTerms = terms;
    bool resetCanonicalisation = false;
    final newName = name ?? currentItem.name;

    if (name != null && name != currentItem.name) {
      // Name changed - update first term and reset canonicalization
      final currentTerms = currentItem.terms ?? [];
      updatedTerms = List<PantryItemTerm>.from(currentTerms);
      
      if (updatedTerms.isNotEmpty) {
        // Update the first term to the new name
        updatedTerms[0] = PantryItemTerm(
          value: name,
          source: 'user',
          sort: 0,
        );
      } else {
        // Add name as first term if no terms exist
        updatedTerms.add(PantryItemTerm(
          value: name,
          source: 'user',
          sort: 0,
        ));
      }
      
      resetCanonicalisation = true;
    } else if (terms != null) {
      // Terms were explicitly provided - ensure name is still first term
      final ensuredTerms = List<PantryItemTerm>.from(terms);
      final hasNameTerm = ensuredTerms.any((term) => term.value.toLowerCase() == newName.toLowerCase());
      
      if (!hasNameTerm) {
        // Add name as first term
        ensuredTerms.insert(0, PantryItemTerm(
          value: newName,
          source: 'user',
          sort: 0,
        ));
        
        // Reorder sort indices for existing terms
        for (int i = 1; i < ensuredTerms.length; i++) {
          ensuredTerms[i] = PantryItemTerm(
            value: ensuredTerms[i].value,
            source: ensuredTerms[i].source,
            sort: i,
          );
        }
      }
      
      updatedTerms = ensuredTerms;
    }

    final companion = PantryItemsCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      stockStatus: stockStatus != null ? Value(stockStatus) : const Value.absent(),
      isStaple: isStaple != null ? Value(isStaple) : const Value.absent(),
      isCanonicalised: resetCanonicalisation ? const Value(false) : 
                      isCanonicalised != null ? Value(isCanonicalised) : const Value.absent(),
      unit: unit != null ? Value(unit) : const Value.absent(),
      quantity: quantity != null ? Value(quantity) : const Value.absent(),
      baseUnit: baseUnit != null ? Value(baseUnit) : const Value.absent(),
      baseQuantity: baseQuantity != null ? Value(baseQuantity) : const Value.absent(),
      price: price != null ? Value(price) : const Value.absent(),
      updatedAt: Value(now),
      terms: updatedTerms != null ? Value(updatedTerms) : const Value.absent(),
      category: category != null ? Value(category) : const Value.absent(),
    );

    await (_db.update(_db.pantryItems)..where((t) => t.id.equals(id)))
        .write(companion);

    // Queue for re-canonicalization if name changed or canonicalization was reset
    if (_pantryItemTermQueueManager != null && resetCanonicalisation) {
      // First, remove any existing queue entries
      await _pantryItemTermQueueManager!.repository.deleteEntriesByPantryItemId(id);

      // Queue the item for canonicalization
      await _pantryItemTermQueueManager!.queuePantryItem(
        pantryItemId: id,
        name: newName,
        existingTerms: updatedTerms,
        isCanonicalised: false, // Reset to false when re-queuing
      );
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

  /// Soft-delete multiple pantry items.
  Future<void> deleteMultipleItems(List<String> ids) async {
    if (ids.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    // Remove any pending queue entries for all items
    if (_pantryItemTermQueueManager != null) {
      for (final id in ids) {
        await _pantryItemTermQueueManager!.repository.deleteEntriesByPantryItemId(id);
      }
    }

    // Bulk update all items to set deletedAt
    await (_db.update(_db.pantryItems)..where((t) => t.id.isIn(ids)))
        .write(PantryItemsCompanion(deletedAt: Value(now)));
  }

  /// Update stock status for multiple pantry items.
  Future<void> updateMultipleStockStatus(List<String> ids, StockStatus stockStatus) async {
    if (ids.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.pantryItems)..where((t) => t.id.isIn(ids)))
        .write(PantryItemsCompanion(
          stockStatus: Value(stockStatus),
          updatedAt: Value(now),
        ));
  }

  /// Find pantry items by matching terms
  Future<List<PantryItemEntry>> findItemsByTerms(List<String> searchTerms) async {
    if (searchTerms.isEmpty) return [];
    
    // Get all non-deleted pantry items
    final allItems = await (_db.select(_db.pantryItems)
      ..where((t) => t.deletedAt.isNull()))
      .get();
    
    // Normalize search terms for comparison
    final normalizedSearchTerms = searchTerms
        .map((term) => term.toLowerCase().trim())
        .toSet();
    
    // Find items with matching terms
    final matchingItems = <PantryItemEntry>[];
    for (final item in allItems) {
      final itemTerms = item.terms ?? [];
      
      // Check if any item term matches any search term
      for (final itemTerm in itemTerms) {
        final normalizedItemTerm = itemTerm.value.toLowerCase().trim();
        if (normalizedSearchTerms.contains(normalizedItemTerm)) {
          matchingItems.add(item);
          break; // Found a match, no need to check other terms
        }
      }
    }
    
    return matchingItems;
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
