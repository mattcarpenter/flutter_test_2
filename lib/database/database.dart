import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:powersync/powersync.dart' hide Table;
import 'package:recipe_app/database/models/recipe_folders.dart';
import 'package:recipe_app/database/models/recipes.dart';
import 'package:uuid/uuid.dart';

part 'database.g.dart';

@DriftDatabase(tables: [RecipeFolders, Recipes])
class AppDatabase extends _$AppDatabase {
  AppDatabase(PowerSyncDatabase db) : super(SqliteAsyncDriftConnection(db));

  @override
  int get schemaVersion => 1;
}
