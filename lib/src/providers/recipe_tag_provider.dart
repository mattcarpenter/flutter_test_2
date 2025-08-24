import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../repositories/recipe_tag_repository.dart';
import '../repositories/recipe_repository.dart';

/// RecipeTagNotifier manages a list of RecipeTagEntry
class RecipeTagNotifier extends StateNotifier<AsyncValue<List<RecipeTagEntry>>> {
  final RecipeTagRepository _repository;
  final RecipeRepository _recipeRepository;
  late final StreamSubscription<List<RecipeTagEntry>> _subscription;

  RecipeTagNotifier(this._repository, this._recipeRepository) : super(const AsyncValue.loading()) {
    // Listen to the stream of tags from Drift
    _subscription = _repository.watchTags().listen(
      (tags) {
        state = AsyncValue.data(tags);
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

  /// Add a new tag
  Future<void> addTag({
    required String name,
    required String color,
    String? userId,
  }) async {
    try {
      await _repository.addTag(
        name: name,
        color: color,
        userId: userId,
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update a tag's properties
  Future<void> updateTag({
    required String tagId,
    String? name,
    String? color,
  }) async {
    try {
      await _repository.updateTag(
        tagId: tagId,
        name: name,
        color: color,
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Delete a tag and remove it from all recipes
  Future<void> deleteTag(String tagId) async {
    try {
      await _repository.deleteTagAndCleanupReferences(tagId, _recipeRepository);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider to expose the RecipeTagNotifier
final recipeTagNotifierProvider = StateNotifierProvider<RecipeTagNotifier, AsyncValue<List<RecipeTagEntry>>>(
  (ref) {
    final repository = ref.watch(recipeTagRepositoryProvider);
    final recipeRepository = ref.watch(recipeRepositoryProvider);
    return RecipeTagNotifier(repository, recipeRepository);
  },
);

/// Convenience provider to get tags by IDs
final tagsByIdsProvider = FutureProvider.family<List<RecipeTagEntry>, List<String>>((ref, tagIds) {
  final repository = ref.watch(recipeTagRepositoryProvider);
  return repository.getTagsByIds(tagIds);
});