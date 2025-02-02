import '../models/recipe_folder.model.dart';
import 'base_repository.dart';

class RecipeFolderRepository {
  final BaseRepository _baseRepository;

  RecipeFolderRepository(this._baseRepository);

  Future<void> addFolder(RecipeFolder folder) async {
    // This call triggers Brick’s upsert, which will update local SQLite first.
    await _baseRepository.add(folder);
    // No manual stream update is necessary.
  }

  Future<void> deleteFolder(RecipeFolder folder) async {
    await _baseRepository.delete(folder);
  }

  // Use Brick’s built-in subscription method for on-device reactivity.
  Stream<List<RecipeFolder>> watchFolders() {
    return _baseRepository.subscribe<RecipeFolder>();
  }
}
