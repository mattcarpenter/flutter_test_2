import '../models/recipe_folder.model.dart';
import 'package:brick_core/query.dart';
import 'base_repository.dart';

class RecipeFolderRepository {
  final BaseRepository _baseRepository;

  RecipeFolderRepository(this._baseRepository);

  Future<void> addFolder(RecipeFolder folder) async {
    // This triggers Brick’s upsert, which writes to local SQLite immediately.
    await _baseRepository.add(folder);
  }

  Future<void> deleteFolder(RecipeFolder folder) async {
    // Instead of deleting, update the folder with a deletion timestamp.
    //final softDeletedFolder = folder.copyWith(deletedAt: DateTime.now());
    folder.deletedAt = DateTime.now();
    await _baseRepository.upsert(folder);
  }

  /// Use Brick’s built‑in subscription method for on-device reactivity.
  /// We filter out records that have been soft-deleted.
  Stream<List<RecipeFolder>> watchFolders() {
    final query = Query(where: [const Where('deletedAt').isExactly(null)]);
    return _baseRepository.subscribe<RecipeFolder>(query: query);
  }
}
