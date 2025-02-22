import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import '../../database/database.dart';
import '../../database/powersync.dart';
import '../../database/recipe_folder.dart';
import '../../main.dart';

class RecipeFolderRepository {
  final AppDatabase _db;

  RecipeFolderRepository(this._db);

  // Watch all recipe folders that are not marked as deleted.
  Stream<List<RecipeFolderEntry>> watchFolders() {
    return (_db.select(_db.recipeFolders)
      ..where((tbl) => tbl.deletedAt.isNull())
    ).watch();
  }

  // Insert a new folder. We use a companion so that the auto-generated fields work properly.
  Future<int> addFolder(RecipeFoldersCompanion folder) {
    return _db.into(_db.recipeFolders).insert(folder);
  }

  // Soft delete a folder by updating its deletedAt column.
  Future<int> deleteFolder(String id) {
    return (_db.update(_db.recipeFolders)
      ..where((tbl) => tbl.id.equals(id))
    ).write(RecipeFoldersCompanion(
      deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }
}


final recipeFolderRepositoryProvider = Provider<RecipeFolderRepository>((ref) {
  // Ensure the database is ready; if not, throw an exception.
  //final db = ref.watch(databaseProvider).maybeWhen(
  //  data: (db) => db,
  //  orElse: () => throw Exception('Database not initialized'),
  //);
  return RecipeFolderRepository(appDb);
});
