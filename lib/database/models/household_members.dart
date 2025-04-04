import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('HouseholdMemberEntry')
class HouseholdMembers extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4()).unique()();
  // Foreign key referencing the household.
  TextColumn get householdId => text()();
  // Foreign key referencing the user (from auth.users).
  TextColumn get userId => text()();
  // Active flag: 1 means active, 0 means inactive.
  IntColumn get isActive => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {householdId, userId};
}
