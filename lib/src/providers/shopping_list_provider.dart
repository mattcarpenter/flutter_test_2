import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../database/powersync.dart';
import '../repositories/shopping_list_repository.dart';

class ShoppingListNotifier
    extends StateNotifier<AsyncValue<List<ShoppingListEntry>>> {
  final ShoppingListRepository _repo;
  late final StreamSubscription<List<ShoppingListEntry>> _sub;

  ShoppingListNotifier(this._repo) : super(const AsyncValue.loading()) {
    _sub = _repo.watchLists().listen(
          (lists) => state = AsyncValue.data(lists),
      onError: (e, st) => state = AsyncValue.error(e, st),
    );
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<String> createList({
    String? userId,
    String? householdId,
    String? name,
  }) =>
      _repo.createList(
        userId: userId,
        householdId: householdId,
        name: name,
      );

  Future<void> renameList(String id, String name) =>
      _repo.renameList(id, name);

  Future<void> deleteList(String id) =>
      _repo.deleteList(id);
}

class ShoppingListItemsNotifier extends StateNotifier<
    AsyncValue<List<ShoppingListItemEntry>>> {
  final ShoppingListRepository _repo;
  final String listId;
  late final StreamSubscription<List<ShoppingListItemEntry>> _sub;

  ShoppingListItemsNotifier(this._repo, this.listId)
      : super(const AsyncValue.loading()) {
    _sub = _repo.watchItems(listId).listen(
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
    String? userId,
    String? householdId,
    List<String>? normalizedTerms,
    String? sourceRecipeId,
    double? amount,
    String? unit,
  }) =>
      _repo.addItem(
        shoppingListId: listId,
        name: name,
        userId: userId,
        householdId: householdId,
        normalizedTerms: normalizedTerms,
        sourceRecipeId: sourceRecipeId,
        amount: amount,
        unit: unit,
      );

  Future<void> updateItem({
    required String itemId,
    String? name,
    List<String>? normalizedTerms,
    String? sourceRecipeId,
    double? amount,
    String? unit,
    bool? bought,
  }) =>
      _repo.updateItem(
        itemId: itemId,
        name: name,
        normalizedTerms: normalizedTerms,
        sourceRecipeId: sourceRecipeId,
        amount: amount,
        unit: unit,
        bought: bought,
      );

  Future<void> deleteItem(String itemId) =>
      _repo.deleteItem(itemId);

  Future<void> markBought(String itemId, {bool bought = true}) =>
      _repo.markBought(itemId, bought: bought);
}

final shoppingListRepositoryProvider =
Provider<ShoppingListRepository>((ref) {
  return ShoppingListRepository(appDb);
});

final shoppingListsProvider =
StateNotifierProvider<ShoppingListNotifier,
    AsyncValue<List<ShoppingListEntry>>>((ref) {
  final repo = ref.watch(shoppingListRepositoryProvider);
  return ShoppingListNotifier(repo);
});

final shoppingListItemsProvider = StateNotifierProvider
    .family<ShoppingListItemsNotifier,
    AsyncValue<List<ShoppingListItemEntry>>, String>(
      (ref, listId) {
    final repo = ref.watch(shoppingListRepositoryProvider);
    return ShoppingListItemsNotifier(repo, listId);
  },
);
