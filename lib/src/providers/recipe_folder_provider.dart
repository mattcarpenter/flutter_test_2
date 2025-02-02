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
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addFolder(String folderName) async { // ✅ Accept only folderName
    try {
      print('creating folder: $folderName');
      final newFolder = RecipeFolder.create(folderName); // ✅ Create model inside the notifier
      print('calling repository...');
      await _repository.addFolder(newFolder);
      print('repo called. updating state...');
      state = AsyncValue.data([...state.value ?? [], newFolder]);
      print('state updated');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteFolder(RecipeFolder folder) async {
    try {
      await _repository.deleteFolder(folder);
      state = AsyncValue.data(state.value!.where((f) => f.id != folder.id).toList());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// StateNotifierProvider for Recipe Folders
final recipeFolderNotifierProvider =
StateNotifierProvider<RecipeFolderNotifier, AsyncValue<List<RecipeFolder>>>((ref) {
  final repository = ref.watch(recipeFolderRepositoryProvider);
  return RecipeFolderNotifier(repository);
});
