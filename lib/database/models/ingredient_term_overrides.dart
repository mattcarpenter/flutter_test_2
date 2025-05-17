import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('IngredientTermOverrideEntry')
class IngredientTermOverrides extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get inputTerm => text()();      // e.g., "margarine"
  TextColumn get mappedTerm => text()();     // e.g., "butter"
  TextColumn get userId => text().nullable()();
  TextColumn get householdId => text().nullable()();
  IntColumn get createdAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()(); // Soft delete
}
