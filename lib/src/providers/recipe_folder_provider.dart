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

  RecipeFolderNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadFolders();
  }

  Future<void> loadFolders() async {
    try {
      final folders = await _repository.getAllFolders();
      state = AsyncValue.data(folders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFolder(RecipeFolder folder) async {
    try {
      await _repository.addFolder(folder);
      loadFolders(); // Refresh state after adding
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteFolder(RecipeFolder folder) async {
    try {
      await _repository.deleteFolder(folder);
      loadFolders(); // Refresh state after deleting
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// StateNotifierProvider for Recipe Folders
final recipeFolderNotifierProvider =
StateNotifierProvider<RecipeFolderNotifier, AsyncValue<List<RecipeFolder>>>((ref) {
  final repository = ref.watch(recipeFolderRepositoryProvider);
  return RecipeFolderNotifier(repository);
});
