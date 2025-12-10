import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('ClippingEntry')
class Clippings extends Table {
  // Primary key with client-side UUID generation
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  @override
  Set<Column> get primaryKey => {id};

  // Content fields
  TextColumn get title => text().nullable()();
  TextColumn get content => text().nullable()(); // Quill Delta JSON

  // Ownership fields
  TextColumn get userId => text().nullable()();
  TextColumn get householdId => text().nullable()();

  // Timestamps
  IntColumn get createdAt => integer().nullable()();
  IntColumn get updatedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();
}
