import 'package:drift/drift.dart';

@DataClassName('HouseholdMemberEntry')
class HouseholdMembers extends Table {
  // Foreign key referencing the household.
  TextColumn get householdId => text()();
  // Foreign key referencing the user (from auth.users).
  TextColumn get userId => text()();

  @override
  Set<Column> get primaryKey => {householdId, userId};
}
