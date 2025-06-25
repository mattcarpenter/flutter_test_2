import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('HouseholdInviteEntry')
class HouseholdInvites extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get householdId => text()();
  TextColumn get invitedByUserId => text()();
  TextColumn get inviteCode => text()();
  TextColumn get email => text().nullable()();
  TextColumn get displayName => text()();
  TextColumn get inviteType => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get lastSentAt => integer().nullable()();
  IntColumn get expiresAt => integer()();
  IntColumn get acceptedAt => integer().nullable()();
  TextColumn get acceptedByUserId => text().nullable()();
}