import 'package:drift/drift.dart';

@DataClassName('PantryItemTermEntry')
class PantryItemTerms extends Table {
  TextColumn get pantryItemId => text()();                   // FK → PantryItems.id
  TextColumn get term         => text()();                   // e.g. “mayonnaise”
  TextColumn get source       => text().withDefault(const Constant('user'))(); // "user" | "ai" | "inferred"
  TextColumn get userId      => text().nullable()();
  TextColumn get householdId => text().nullable()();        // Optional household-sharing context
  IntColumn get createdAt    => integer().nullable()();
  IntColumn get updatedAt    => integer().nullable()();
  IntColumn get deletedAt    => integer().nullable()(); // Soft delete
  @override Set<Column> get primaryKey => {pantryItemId, term};
}
