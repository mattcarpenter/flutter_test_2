import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../database/models/pantry_item_terms.dart';
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
    bool inStock = true,
    String? userId,
    String? householdId,
    String? unit,
    double? quantity,
    String? baseUnit,
    double? baseQuantity,
    double? price,
    List<PantryItemTerm>? terms,
  }) async {
    // Add the item to the repository
    final itemId = await _repo.addItem(
      name: name,
      inStock: inStock,
      userId: userId,
      householdId: householdId,
      unit: unit,
      quantity: quantity,
      baseUnit: baseUnit,
      baseQuantity: baseQuantity,
      price: price,
      terms: terms,
    );
    
    // We don't need to manually refresh - Drift and our StreamSubscription will handle it
    // The database events will trigger the watchItems() stream, which our subscription
    // is already listening to in the constructor
    
    return itemId;
  }

  Future<void> updateItem({
    required String id,
    String? name,
    bool? inStock,
    String? unit,
    double? quantity,
    String? baseUnit,
    double? baseQuantity,
    double? price,
    List<PantryItemTerm>? terms,
  }) async {
    await _repo.updateItem(
      id: id,
      name: name,
      inStock: inStock,
      unit: unit,
      quantity: quantity,
      baseUnit: baseUnit,
      baseQuantity: baseQuantity,
      price: price,
      terms: terms,
    );
    
    // Database change events will automatically trigger the stream
  }

  Future<void> deleteItem(String id) async {
    await _repo.deleteItem(id);
    
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
