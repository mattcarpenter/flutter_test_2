import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';

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

  TextColumn get terms => text().nullable().map(const PantryItemTermListConverter())();
}
