import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_folder.dart';
import '../repositories/recipe_folder_repository.dart';

// Firestore repository provider
final recipeFolderRepositoryProvider = Provider<RecipeFolderRepository>((ref) {
  return RecipeFolderRepository();
});

// RecipeFolderNotifier for state management
class RecipeFolderNotifier extends StateNotifier<List<RecipeFolder>> {
  final RecipeFolderRepository _repository;

  RecipeFolderNotifier(this._repository) : super([]) {
    loadFolders();
  }

  Future<void> loadFolders() async {
    state = await _repository.getAllFolders();
  }

  Future<void> addFolder(RecipeFolder folder) async {
    state = [...state, folder];
    await _repository.addFolder(folder);
  }

  Future<void> deleteFolder(String id) async {
    await _repository.deleteFolder(id);
    await loadFolders();
  }
}

// StateNotifierProvider
final recipeFolderNotifierProvider =
StateNotifierProvider<RecipeFolderNotifier, List<RecipeFolder>>((ref) {
  final repository = ref.watch(recipeFolderRepositoryProvider);
  return RecipeFolderNotifier(repository);
});
