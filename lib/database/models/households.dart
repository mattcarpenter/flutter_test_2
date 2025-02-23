import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('HouseholdEntry')
class Households extends Table {
  // Primary key with a client-side default UUID.
  TextColumn get id =>
      text().clientDefault(() => const Uuid().v4()).unique()();
  // The name of the household.
  TextColumn get name => text()();
  // The user who created (or owns) the household.
  TextColumn get userId => text()();
// Optionally, you could add createdAt, updatedAt columns as integers.
}
