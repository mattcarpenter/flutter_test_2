import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_folder.model.dart';
import '../repositories/recipe_folder_repository.dart';
import '../repositories/base_repository.dart';

// Provide the BaseRepository instance (singleton)
final baseRepositoryProvider = Provider<BaseRepository>((ref) {
  return BaseRepository();
});

// Provide RecipeFolderRepository using BaseRepository
final recipeFolderRepositoryProvider = Provider<RecipeFolderRepository>((ref) {
  final baseRepo = ref.watch(baseRepositoryProvider);
  return RecipeFolderRepository(baseRepo);
});

// RecipeFolderNotifier for state management
class RecipeFolderNotifier extends StateNotifier<AsyncValue<List<RecipeFolder>>> {
  final RecipeFolderRepository _repository;
  late final StreamSubscription<List<RecipeFolder>> _subscription;

  RecipeFolderNotifier(this._repository) : super(const AsyncValue.loading()) {
    // Instead of manually loading folders, subscribe to Brick's local data stream.
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

  // Updated addFolder method to accept a RecipeFolder object.
  Future<void> addFolder(RecipeFolder folder) async {
    try {
      print('Creating folder: ${folder.name} with parent: ${folder.parentId}');
      await _repository.addFolder(folder);
      print('Add operation complete; state will update via subscription.');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteFolder(RecipeFolder folder) async {
    try {
      await _repository.deleteFolder(folder);
      // The subscription will automatically update the state.
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// 🔹 StateNotifierProvider to expose the RecipeFolderNotifier
final recipeFolderNotifierProvider =
StateNotifierProvider<RecipeFolderNotifier, AsyncValue<List<RecipeFolder>>>(
      (ref) {
    final repository = ref.watch(recipeFolderRepositoryProvider);
    return RecipeFolderNotifier(repository);
  },
);
