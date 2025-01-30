import 'base_repository.dart';
import '../models/recipe_folder.model.dart';

class RecipeFolderRepository {
  final BaseRepository _baseRepository;

  // Constructor now takes BaseRepository
  RecipeFolderRepository(this._baseRepository);

  Future<List<RecipeFolder>> getAllFolders() async {
    return _baseRepository.getAll<RecipeFolder>();
  }

  Future<void> addFolder(RecipeFolder folder) async {
    await _baseRepository.add(folder);
  }

  Future<void> deleteFolder(RecipeFolder folder) async {
    await _baseRepository.delete(folder);
  }
}
