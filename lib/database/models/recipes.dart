import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';

@DataClassName('RecipeEntry')
class Recipes extends Table {
  // Primary key with a client-side default UUID.
  TextColumn get id => text().clientDefault(() => const Uuid().v4()).unique()();

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get rating => integer().nullable()();
  TextColumn get language => text().nullable()();
  IntColumn get servings => integer().nullable()();
  IntColumn get prepTime => integer().nullable()();
  IntColumn get cookTime => integer().nullable()();
  IntColumn get totalTime => integer().nullable()();
  TextColumn get source => text().nullable()();
  TextColumn get nutrition => text().nullable()();
  TextColumn get generalNotes => text().nullable()();
  TextColumn get userId => text().nullable()();
  // We no longer rely on folderId here; the association is in the join table.
  // TextColumn get folderId => text().nullable()();
  TextColumn get householdId => text().nullable()();
  // Timestamps stored as integers (e.g., Unix epoch milliseconds)
  IntColumn get createdAt => integer().nullable()();
  IntColumn get updatedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get pinned => integer().nullable().withDefault(const Constant(0))();
  IntColumn get pinnedAt => integer().nullable()();
  TextColumn get ingredients => text().map(const IngredientListConverter()).nullable()();
  TextColumn get steps => text().map(const StepListConverter()).nullable()();
  TextColumn get folderIds => text().nullable().map(StringListTypeConverter())();
  TextColumn get images => text().nullable().map(const RecipeImageListConverter())();
}

/*
Steps:
- text
- type
- position
- notes
- timerDurationSeconds
 */
