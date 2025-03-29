import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../database/models/cooks.dart';
import '../../database/powersync.dart';
import '../repositories/cook_repository.dart';
import 'package:collection/collection.dart';

/// [CookNotifier] manages a list of [CookEntry] records.
class CookNotifier extends StateNotifier<AsyncValue<List<CookEntry>>> {
  final CookRepository _repository;
  late final StreamSubscription<List<CookEntry>> _subscription;

  CookNotifier(this._repository) : super(const AsyncValue.loading()) {
    _subscription = _repository.watchCooks().listen(
          (cooks) {
        state = AsyncValue.data(cooks);
      },
      onError: (error, stack) {
        state = AsyncValue.error(error, stack);
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  /// Starts a new cook session.
  Future<String> startCook({
    required String recipeId,
    required String recipeName,
    String? userId,
    String? householdId,
  }) async {
    try {
      final id = await _repository.startCook(
        recipeId: recipeId,
        userId: userId,
        householdId: householdId,
        recipeName: recipeName,
      );
      return id;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Finishes an ongoing cook session.
  Future<void> finishCook({
    required String cookId,
    int? rating,
    String? notes,
  }) async {
    try {
      await _repository.finishCook(
        cookId: cookId,
        rating: rating,
        notes: notes,
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Updates a cook's details.
  Future<void> updateCook({
    required String cookId,
    int? rating,
    String? notes,
    int? currentStepIndex,
  }) async {
    try {
      await _repository.updateCook(
        cookId: cookId,
        rating: rating,
        notes: notes,
        currentStepIndex: currentStepIndex,
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider to expose the [CookRepository].
final cookRepositoryProvider = Provider<CookRepository>((ref) {
  return CookRepository(appDb);
});

/// Provider to expose the [CookNotifier].
final cookNotifierProvider = StateNotifierProvider<CookNotifier, AsyncValue<List<CookEntry>>>(
      (ref) {
    final repository = ref.watch(cookRepositoryProvider);
    return CookNotifier(repository);
  },
);

// Returns only cooks with status == in_progress
final inProgressCooksProvider = Provider<List<CookEntry>>((ref) {
  final allCooks = ref.watch(cookNotifierProvider).value ?? [];
  return allCooks.where((c) => c.status == CookStatus.inProgress).toList();
});

// Returns the first in-progress cook for a specific recipe
final activeCookForRecipeProvider = Provider.family<CookEntry?, String>((ref, recipeId) {
  final activeCooks = ref.watch(inProgressCooksProvider);
  return activeCooks.firstWhereOrNull((cook) => cook.recipeId == recipeId);
});

// Returns true if any in-progress cook exists for the given recipe
final hasActiveCookForRecipeProvider = Provider.family<bool, String>((ref, recipeId) {
  return ref.watch(activeCookForRecipeProvider(recipeId)) != null;
});
