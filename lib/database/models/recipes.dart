import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('RecipeEntry')
class Recipes extends Table {
  // Primary key with a client-side default UUID.
  TextColumn get id => text().clientDefault(() => const Uuid().v4()).unique()();

  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get rating => integer()();
  TextColumn get language => text()();
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
  TextColumn get ingredients => text().nullable()();
  TextColumn get steps => text().nullable()();
}

/*
Steps:
- text
- type
- position
- notes
- timerDurationSeconds
 */
