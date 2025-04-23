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

/// Manages the list of terms for a single pantry item.
class PantryItemTermsNotifier extends StateNotifier<
    AsyncValue<List<PantryItemTermEntry>>> {
  final PantryRepository _repo;
  final String pantryItemId;
  late final StreamSubscription<List<PantryItemTermEntry>> _sub;

  PantryItemTermsNotifier(this._repo, this.pantryItemId)
      : super(const AsyncValue.loading()) {
    _sub = _repo.watchTerms(pantryItemId).listen(
          (terms) => state = AsyncValue.data(terms),
      onError: (e, st) => state = AsyncValue.error(e, st),
    );
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<void> addTerm(String term, {String source = 'user'}) =>
      _repo.addTerm(
        pantryItemId: pantryItemId,
        term: term,
        source: source,
      );

  Future<void> deleteTerm(String term) =>
      _repo.deleteTerm(
        pantryItemId: pantryItemId,
        term: term,
      );
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

/// Expose the terms for a particular pantry item.
final pantryItemTermsProvider = StateNotifierProvider
    .family<PantryItemTermsNotifier, AsyncValue<List<PantryItemTermEntry>>, String>(
      (ref, pantryItemId) {
    final repo = ref.watch(pantryRepositoryProvider);
    return PantryItemTermsNotifier(repo, pantryItemId);
  },
);
