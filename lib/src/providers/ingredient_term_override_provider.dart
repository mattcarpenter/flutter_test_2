import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/database/database.dart';
import '../repositories/ingredient_term_override_repository.dart';

class IngredientTermOverrideNotifier extends StateNotifier<AsyncValue<List<IngredientTermOverrideEntry>>> {
  final IngredientTermOverrideRepository _repository;
  late final StreamSubscription<List<IngredientTermOverrideEntry>> _subscription;

  IngredientTermOverrideNotifier(this._repository) : super(const AsyncValue.loading()) {
    _subscription = _repository.watchOverrides().listen(
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
    required String inputTerm,
    required String mappedTerm,
    String? userId,
    String? householdId,
  }) async {
    try {
      await _repository.addOverride(
        inputTerm: inputTerm,
        mappedTerm: mappedTerm,
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

final ingredientTermOverrideNotifierProvider = StateNotifierProvider<
    IngredientTermOverrideNotifier,
    AsyncValue<List<IngredientTermOverrideEntry>>
>((ref) {
  final repository = ref.watch(ingredientTermOverrideRepositoryProvider);
  return IngredientTermOverrideNotifier(repository);
});
