import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/database/database.dart';
import '../repositories/recipe_ingredient_term_override_repository.dart';

class RecipeIngredientTermOverrideNotifier extends StateNotifier<AsyncValue<List<RecipeIngredientTermOverrideEntry>>> {
  final RecipeIngredientTermOverrideRepository _repository;
  late final StreamSubscription<List<RecipeIngredientTermOverrideEntry>> _subscription;

  RecipeIngredientTermOverrideNotifier(this._repository, String recipeId) : super(const AsyncValue.loading()) {
    _subscription = _repository.watchOverridesForRecipe(recipeId).listen(
          (overrides) {
        state = AsyncValue.data(overrides);
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

  Future<void> addOverride({
    required String recipeId,
    required String term,
    required String pantryItemId,
    String? userId,
    String? householdId,
  }) async {
    try {
      await _repository.addOverride(
        recipeId: recipeId,
        term: term,
        pantryItemId: pantryItemId,
        userId: userId,
        householdId: householdId,
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteOverrideById(String id) async {
    try {
      await _repository.deleteOverrideById(id);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final recipeIngredientTermOverrideNotifierProvider = StateNotifierProvider.family<
    RecipeIngredientTermOverrideNotifier,
    AsyncValue<List<RecipeIngredientTermOverrideEntry>>,
    String
>((ref, recipeId) {
  final repository = ref.watch(recipeIngredientTermOverrideRepositoryProvider);
  return RecipeIngredientTermOverrideNotifier(repository, recipeId);
});

