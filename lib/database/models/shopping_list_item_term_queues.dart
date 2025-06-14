import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('ShoppingListItemTermQueueEntry')
class ShoppingListItemTermQueues extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  @override Set<Column> get primaryKey => {id};

  TextColumn get shoppingListItemId => text()();
  TextColumn get name => text()();
  TextColumn get userId => text().nullable()();
  RealColumn get amount => real().nullable()();
  TextColumn get unit => text().nullable()();

  // Queue status: pending, processing, completed, failed
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get error => text().nullable()();

  IntColumn get createdAt => integer().nullable()();
  IntColumn get updatedAt => integer().nullable()();
}