import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('RecipeTagEntry')
class RecipeTags extends Table {
  // Use a client-side default so every inserted row gets a unique UUID.
  TextColumn get id => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get name => text()();
  TextColumn get color => text().withDefault(const Constant('#4285F4'))(); // Default blue color
  TextColumn get userId => text().nullable()();
  TextColumn get householdId => text().nullable()();
  IntColumn get createdAt => integer().nullable()();
  IntColumn get updatedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();
}