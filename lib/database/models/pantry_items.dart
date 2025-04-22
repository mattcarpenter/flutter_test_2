import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('PantryItemEntry')
class PantryItems extends Table {
  TextColumn get id         => text().clientDefault(() => const Uuid().v4())();
  @override Set<Column> get primaryKey => {id};

  TextColumn get name       => text()();                     // “Kewpie Mayo”
  BoolColumn  get inStock   => boolean().withDefault(const Constant(true))();
  TextColumn  get userId    => text().nullable()();                     // or householdId if multi‑tenant
  TextColumn  get householdId => text().nullable()();

  IntColumn   get createdAt => integer().nullable()();
  IntColumn   get updatedAt => integer().nullable()();
  IntColumn   get deletedAt => integer().nullable()();
}

@DataClassName('PantryItemTermEntry')
class PantryItemTerms extends Table {
  TextColumn get pantryItemId => text()();                   // FK → PantryItems.id
  TextColumn get term         => text()();                   // e.g. “mayonnaise”
  TextColumn get source       => text().withDefault(const Constant('user'))(); // "user" | "ai" | "inferred"

  @override Set<Column> get primaryKey => {pantryItemId, term};
}
