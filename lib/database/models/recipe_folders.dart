import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('RecipeFolderEntry')
class RecipeFolders extends Table {
  // Use a client-side default so every inserted row gets a unique UUID.
  TextColumn get id => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get name => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get householdId => text().nullable()();
  IntColumn get deletedAt => integer().nullable()();
}
