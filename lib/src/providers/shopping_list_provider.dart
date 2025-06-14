import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/database.dart';
import '../../database/powersync.dart';
import '../repositories/shopping_list_repository.dart';
import '../repositories/shopping_list_item_term_queue_repository.dart';
import '../managers/shopping_list_item_term_queue_manager.dart';
import '../services/ingredient_canonicalization_service.dart';

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
  final String? listId;
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
    List<String>? terms,
    String? category,
    String? sourceRecipeId,
    double? amount,
    String? unit,
  }) =>
      _repo.addItem(
        shoppingListId: listId,
        name: name,
        userId: userId,
        householdId: householdId,
        terms: terms,
        category: category,
        sourceRecipeId: sourceRecipeId,
        amount: amount,
        unit: unit,
      );

  Future<void> updateItem({
    required String itemId,
    String? name,
    List<String>? terms,
    String? category,
    String? sourceRecipeId,
    double? amount,
    String? unit,
    bool? bought,
  }) =>
      _repo.updateItem(
        itemId: itemId,
        name: name,
        terms: terms,
        category: category,
        sourceRecipeId: sourceRecipeId,
        amount: amount,
        unit: unit,
        bought: bought,
      );

  Future<void> deleteItem(String itemId) =>
      _repo.deleteItem(itemId);

  Future<void> markBought(String itemId, {bool bought = true}) =>
      _repo.markBought(itemId, bought: bought);

  Future<void> markMultipleBought(List<String> itemIds, {bool bought = true}) =>
      _repo.markMultipleBought(itemIds, bought: bought);

  Future<void> deleteMultipleItems(List<String> itemIds) =>
      _repo.deleteMultipleItems(itemIds);
}

// Repository providers
final shoppingListItemTermQueueRepositoryProvider =
Provider<ShoppingListItemTermQueueRepository>((ref) {
  return ShoppingListItemTermQueueRepository(appDb);
});

// Base repository provider without circular dependency
final _baseShoppingListRepositoryProvider =
Provider<ShoppingListRepository>((ref) {
  return ShoppingListRepository(appDb);
});

// Queue manager provider
final shoppingListItemTermQueueManagerProvider =
Provider<ShoppingListItemTermQueueManager>((ref) {
  final queueRepo = ref.watch(shoppingListItemTermQueueRepositoryProvider);
  final canonicalizer = ref.watch(ingredientCanonicalizerProvider);
  final shoppingListRepo = ref.read(_baseShoppingListRepositoryProvider);
  
  final manager = ShoppingListItemTermQueueManager(
    repository: queueRepo,
    shoppingListRepository: shoppingListRepo,
    canonicalizer: canonicalizer,
    db: appDb,
  );
  
  // Set up circular dependency
  shoppingListRepo.termQueueManager = manager;
  
  return manager;
});

// Final repository provider with injected dependencies
final shoppingListRepositoryProvider =
Provider<ShoppingListRepository>((ref) {
  final repo = ref.read(_baseShoppingListRepositoryProvider);
  // Ensure the term queue manager is created and connected
  ref.read(shoppingListItemTermQueueManagerProvider);
  return repo;
});

// Current shopping list selection provider
class CurrentShoppingListNotifier extends StateNotifier<String?> {
  static const String _prefKey = 'current_shopping_list_id';

  CurrentShoppingListNotifier() : super(null) {
    _loadSelectedList();
  }

  Future<void> _loadSelectedList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedListId = prefs.getString(_prefKey);
      state = savedListId;
    } catch (e) {
      // Ignore errors, use null as default
    }
  }

  Future<void> setCurrentList(String? listId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (listId != null) {
        await prefs.setString(_prefKey, listId);
      } else {
        await prefs.remove(_prefKey);
      }
      state = listId;
    } catch (e) {
      // Still update state even if storage fails
      state = listId;
    }
  }
}

final currentShoppingListProvider = StateNotifierProvider<CurrentShoppingListNotifier, String?>((ref) {
  return CurrentShoppingListNotifier();
});

// State providers
final shoppingListsProvider =
StateNotifierProvider<ShoppingListNotifier,
    AsyncValue<List<ShoppingListEntry>>>((ref) {
  final repo = ref.watch(shoppingListRepositoryProvider);
  return ShoppingListNotifier(repo);
});

final shoppingListItemsProvider = StateNotifierProvider
    .family<ShoppingListItemsNotifier,
    AsyncValue<List<ShoppingListItemEntry>>, String?>(
      (ref, listId) {
    final repo = ref.watch(shoppingListRepositoryProvider);
    return ShoppingListItemsNotifier(repo, listId);
  },
);

// Current shopping list items provider (based on current selection)
final currentShoppingListItemsProvider = Provider<AsyncValue<List<ShoppingListItemEntry>>>((ref) {
  final currentListId = ref.watch(currentShoppingListProvider);
  return ref.watch(shoppingListItemsProvider(currentListId));
});
