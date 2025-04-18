import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:powersync/powersync.dart' hide Table;
import 'package:recipe_app/database/models/recipe_folders.dart';
import 'package:recipe_app/database/models/recipes.dart';
import 'package:uuid/uuid.dart';

import 'models/household_members.dart';
import 'models/households.dart';
import 'models/recipe_shares.dart';
import 'models/upload_queues.dart';

import 'models/ingredients.dart';
import 'models/steps.dart';
import 'models/recipe_images.dart';

import 'converters.dart';

part 'database.g.dart';

@DriftDatabase(tables: [RecipeFolders, Recipes, RecipeShares, HouseholdMembers, Households, UploadQueues])
class AppDatabase extends _$AppDatabase {
  AppDatabase(PowerSyncDatabase db) : super(SqliteAsyncDriftConnection(db));

  @override
  int get schemaVersion => 1;
}
