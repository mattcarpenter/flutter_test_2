import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../database/models/pantry_item_terms.dart';
import '../../database/models/pantry_items.dart'; // For StockStatus enum
import '../repositories/pantry_repository.dart';

/// Manages the global list of pantry items.
class PantryNotifier
    extends StateNotifier<AsyncValue<List<PantryItemEntry>>> {
  final PantryRepository _repo;
  late final StreamSubscription<List<PantryItemEntry>> _sub;

  PantryNotifier(this._repo) : super(const AsyncValue.loading()) {
    _sub = _repo.watchItems().listen(
          (items) => state = AsyncValue.data(items),
      onError: (e, st) => state = AsyncValue.error(e, st),
    );
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<String> addItem({
    required String name,
    StockStatus stockStatus = StockStatus.inStock,
    bool isStaple = false,
    String? userId,
    String? householdId,
    String? unit,
    double? quantity,
    String? baseUnit,
    double? baseQuantity,
    double? price,
    List<PantryItemTerm>? terms,
    String? category,
  }) async {
    // Add the item to the repository
    final itemId = await _repo.addItem(
      name: name,
      stockStatus: stockStatus,
      isStaple: isStaple,
      userId: userId,
      householdId: householdId,
      unit: unit,
      quantity: quantity,
      baseUnit: baseUnit,
      baseQuantity: baseQuantity,
      price: price,
      terms: terms,
      category: category,
    );

    // We don't need to manually refresh - Drift and our StreamSubscription will handle it
    // The database events will trigger the watchItems() stream, which our subscription
    // is already listening to in the constructor

    return itemId;
  }

  Future<void> updateItem({
    required String id,
    String? name,
    StockStatus? stockStatus,
    bool? isStaple,
    bool? isCanonicalised,
    String? unit,
    double? quantity,
    String? baseUnit,
    double? baseQuantity,
    double? price,
    List<PantryItemTerm>? terms,
    String? category,
  }) async {
    await _repo.updateItem(
      id: id,
      name: name,
      stockStatus: stockStatus,
      isStaple: isStaple,
      isCanonicalised: isCanonicalised,
      unit: unit,
      quantity: quantity,
      baseUnit: baseUnit,
      baseQuantity: baseQuantity,
      price: price,
      terms: terms,
      category: category,
    );

    // Database change events will automatically trigger the stream
  }

  Future<void> deleteItem(String id) async {
    await _repo.deleteItem(id);

    // Database change events will automatically trigger the stream
  }

  Future<void> deleteMultipleItems(List<String> ids) async {
    await _repo.deleteMultipleItems(ids);

    // Database change events will automatically trigger the stream
  }

  Future<void> updateMultipleStockStatus(List<String> ids, StockStatus stockStatus) async {
    await _repo.updateMultipleStockStatus(ids, stockStatus);

    // Database change events will automatically trigger the stream
  }
}

// Expose PantryNotifier
final pantryNotifierProvider =
StateNotifierProvider<PantryNotifier, AsyncValue<List<PantryItemEntry>>>(
      (ref) {
    final repo = ref.watch(pantryRepositoryProvider);
    return PantryNotifier(repo);
  },
);

/// Use the [PantryRepository] provider from pantry_repository.dart
/// pantryRepositoryProvider is defined in src/repositories/pantry_repository.dart

/// Expose the global pantry-item list.
final pantryItemsProvider =
StateNotifierProvider<PantryNotifier, AsyncValue<List<PantryItemEntry>>>(
      (ref) {
    final repo = ref.watch(pantryRepositoryProvider);
    return PantryNotifier(repo);
  },
);
