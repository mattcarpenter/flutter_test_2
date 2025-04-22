import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('ShoppingListEntry')
class ShoppingLists extends Table {
  TextColumn get id        => text().clientDefault(() => const Uuid().v4())();
  @override Set<Column> get primaryKey => {id};

  TextColumn get name      => text().nullable()();           // “Weekly Groceries”
  TextColumn get userId    => text()();
  TextColumn get householdId => text().nullable()();        // Optional household-sharing context
  IntColumn  get createdAt => integer().nullable()();
  IntColumn  get updatedAt => integer().nullable()();
}
