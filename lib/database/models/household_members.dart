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
  // Role in household: owner, admin, member
  TextColumn get role => text().withDefault(const Constant('member'))();
  // When the user joined the household
  IntColumn get joinedAt => integer()();
  // When the record was last updated
  IntColumn get updatedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {householdId, userId};
}
