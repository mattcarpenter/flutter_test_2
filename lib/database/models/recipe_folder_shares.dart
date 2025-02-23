import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('RecipeFolderShareEntry')
class RecipeFolderShares extends Table {
  // Surrogate primary key.
  TextColumn get id =>
      text().clientDefault(() => const Uuid().v4()).unique()();
  // The folder being shared.
  TextColumn get folderId => text()();
  // Optional: sharing to an entire household.
  TextColumn get householdId => text().nullable()();
  // Optional: sharing directly with a user.
  TextColumn get userId => text().nullable()();
  // Permission flag: 0 (read-only) or 1 (can edit)
  IntColumn get canEdit => integer().withDefault(const Constant(0))();
}
