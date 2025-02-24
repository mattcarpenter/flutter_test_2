import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('RecipeFolderShareEntry')
class RecipeFolderShares extends Table {
  // A unique identifier for the share.
  TextColumn get id => text().clientDefault(() => const Uuid().v4()).unique()();

  // The folder being shared.
  TextColumn get folderId => text()();

  // The user who is sharing the folder (should be the folder owner or someone authorized).
  TextColumn get sharerId => text()();

  // Optional: The specific target user (if sharing directly with a single user).
  TextColumn get targetUserId => text().nullable()();

  // Optional: The target household. If set, the share applies to all members of that household.
  TextColumn get targetHouseholdId => text().nullable()();

  // Permission flag: e.g. 1 for can_edit (allows adding recipes) or 0 for read-only.
  IntColumn get canEdit => integer().withDefault(const Constant(0))();

  // Timestamp (e.g. Unix epoch millis) when the share was created.
  IntColumn get createdAt => integer().nullable()();
}
