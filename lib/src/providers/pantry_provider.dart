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
  }) =>
      _repo.addItem(
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
  }) =>
      _repo.updateItem(
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

  Future<void> deleteItem(String id) =>
      _repo.deleteItem(id);
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
