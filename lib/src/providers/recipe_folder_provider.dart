import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../repositories/recipe_folder_repository.dart';
import '../repositories/recipe_repository.dart';

// RecipeFolderNotifier manages a list of RecipeFolderEntry.
class RecipeFolderNotifier extends StateNotifier<AsyncValue<List<RecipeFolderEntry>>> {
  final RecipeFolderRepository _repository;
  final RecipeRepository _recipeRepository;
  late final StreamSubscription<List<RecipeFolderEntry>> _subscription;

  RecipeFolderNotifier(this._repository, this._recipeRepository) : super(const AsyncValue.loading()) {
    // Listen to the stream of folders from Drift.
    _subscription = _repository.watchFolders().listen(
          (folders) {
        state = AsyncValue.data(folders);
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

  // Add a new folder.
  Future<void> addFolder({
    required String name,
    String? householdId,
    String? userId,
  }) async {
    try {
      // Create a companion for insertion.
      final companion = RecipeFoldersCompanion.insert(
        name: name,
        userId: Value(userId),
        householdId: Value(householdId),
      );
      await _repository.addFolder(companion);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Delete a folder by id.
  Future<void> deleteFolder(String id) async {
    try {
      await _repository.deleteFolderAndCleanupReferences(id, _recipeRepository);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider to expose the RecipeFolderNotifier.
final recipeFolderNotifierProvider = StateNotifierProvider<RecipeFolderNotifier, AsyncValue<List<RecipeFolderEntry>>>(
      (ref) {
    final repository = ref.watch(recipeFolderRepositoryProvider);
    final recipeRepository = ref.watch(recipeRepositoryProvider);
    return RecipeFolderNotifier(repository, recipeRepository);
  },
);
