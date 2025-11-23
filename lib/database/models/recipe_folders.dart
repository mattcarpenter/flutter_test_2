import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Enum for folder types
enum FolderType {
  normal,           // value: 0
  smartTag,         // value: 1
  smartIngredient,  // value: 2
}

/// Enum for filter logic
enum FilterLogic {
  or,   // value: 0 - match any
  and,  // value: 1 - match all
}

@DataClassName('RecipeFolderEntry')
class RecipeFolders extends Table {
  // Use a client-side default so every inserted row gets a unique UUID.
  TextColumn get id => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get name => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get householdId => text().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  // Smart folder columns
  IntColumn get folderType => integer().withDefault(const Constant(0))(); // 0=normal, 1=smartTag, 2=smartIngredient
  IntColumn get filterLogic => integer().withDefault(const Constant(0))(); // 0=OR, 1=AND
  TextColumn get smartFilterTags => text().nullable()();  // JSON array of tag names (TEXT, not IDs)
  TextColumn get smartFilterTerms => text().nullable()(); // JSON array of ingredient term strings
}
