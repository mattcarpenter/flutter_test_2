import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../database/powersync.dart';
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
  }) =>
      _repo.addItem(
        name: name,
        inStock: inStock,
        userId: userId,
        householdId: householdId,
      );

  Future<void> updateItem({
    required String id,
    String? name,
    bool? inStock,
  }) =>
      _repo.updateItem(id: id, name: name, inStock: inStock);

  Future<void> deleteItem(String id) =>
      _repo.deleteItem(id);
}

/// Expose the [PantryRepository].
final pantryRepositoryProvider =
Provider<PantryRepository>((ref) => PantryRepository(appDb));

/// Expose the global pantry-item list.
final pantryItemsProvider =
StateNotifierProvider<PantryNotifier, AsyncValue<List<PantryItemEntry>>>(
      (ref) {
    final repo = ref.watch(pantryRepositoryProvider);
    return PantryNotifier(repo);
  },
);
