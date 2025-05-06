import 'package:drift/drift.dart';

/// Queue for pantry item term canonicalization
@DataClassName('PantryItemTermQueueEntry')
class PantryItemTermQueues extends Table {
  TextColumn get id => text()();
  TextColumn get pantryItemId => text()();
  IntColumn get requestTimestamp => integer()();
  TextColumn get pantryItemData => text()();
  TextColumn get status => text()();
  IntColumn get retryCount => integer().nullable()();
  IntColumn get lastTryTimestamp => integer().nullable()();
  TextColumn get responseData => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
