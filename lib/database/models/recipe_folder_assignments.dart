import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('RecipeFolderAssignmentEntry')
class RecipeFolderAssignments extends Table {
  // Surrogate primary key.
  TextColumn get id => text().clientDefault(() => const Uuid().v4()).unique()();

  // Foreign key referencing a recipe.
  TextColumn get recipeId => text()();

  // Foreign key referencing a folder.
  TextColumn get folderId => text()();

  // NEW: Denormalized household id from the recipe/folder.
  TextColumn get householdId => text().nullable()();

  // Optional timestamp.
  IntColumn get createdAt => integer().nullable()();
}
