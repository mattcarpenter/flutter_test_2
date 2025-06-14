import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';

@DataClassName('ShoppingListItemEntry')
class ShoppingListItems extends Table {
  // Primary key
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  @override Set<Column> get primaryKey => {id};

  // FK → list (nullable to support default "My Shopping List")
  TextColumn get shoppingListId => text().nullable()();

  // Visible label (what the user sees on the list)
  TextColumn get name => text()();                     // “yellow onion”

  /* Optional terms from canonicalization
     (comma‑delimited JSON string list via your StringListTypeConverter). */
  TextColumn get terms =>
      text().nullable().map(StringListTypeConverter())();

  // Category from canonicalization API
  TextColumn get category => text().nullable()();

  // Traceability back to recipe (optional)
  TextColumn get sourceRecipeId => text().nullable()();

  /* ──  Structured quantity  ──────────────────────────────── */
  RealColumn get amount => real().nullable()();        // 1, 0.5, 250, etc.
  TextColumn get unit   => text().nullable()();        // “g”, “kg”, “cup”

  // Check‑off flag
  BoolColumn get bought =>
      boolean().withDefault(const Constant(false))();

  TextColumn get userId => text().nullable()();
  TextColumn get householdId => text().nullable()();

  // Timestamps
  IntColumn get createdAt => integer().nullable()();
  IntColumn get updatedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()(); // Soft delete
}
