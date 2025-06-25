import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../database/database.dart';
import '../../database/powersync.dart';

class HouseholdInviteRepository {
  final AppDatabase _db;

  HouseholdInviteRepository(this._db);

  // READ OPERATIONS ONLY - Repository pattern for local database access
  
  Stream<List<HouseholdInviteEntry>> watchHouseholdInvites(String householdId) {
    return (_db.select(_db.householdInvites)
      ..where((tbl) => tbl.householdId.equals(householdId) &
                       tbl.status.equals('pending'))
    ).watch();
  }

  Stream<List<HouseholdInviteEntry>> watchUserInvites(String userEmail) {
    // Watch invites for current user's email address
    return (_db.select(_db.householdInvites)
      ..where((tbl) => tbl.email.equals(userEmail) &
                       tbl.status.equals('pending') &
                       tbl.expiresAt.isBiggerThan(
                         Variable(DateTime.now().millisecondsSinceEpoch)
                       ))
    ).watch();
  }

  Future<HouseholdInviteEntry?> getInviteByCode(String inviteCode) async {
    return await (_db.select(_db.householdInvites)
      ..where((tbl) => tbl.inviteCode.equals(inviteCode) &
                       tbl.status.equals('pending'))
    ).getSingleOrNull();
  }

  Future<List<HouseholdInviteEntry>> getPendingInvitesForHousehold(String householdId) async {
    return await (_db.select(_db.householdInvites)
      ..where((tbl) => tbl.householdId.equals(householdId) &
                       tbl.status.equals('pending'))
    ).get();
  }

  // Internal methods for PowerSync updates (not called by UI)
  Future<void> updateInviteStatus(String inviteId, String status) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.householdInvites)
      ..where((tbl) => tbl.id.equals(inviteId))
    ).write(HouseholdInvitesCompanion(
      status: Value(status),
      updatedAt: Value(now),
      acceptedAt: status == 'accepted' 
        ? Value(now) 
        : const Value.absent(),
    ));
  }
}

/// Provider for the HouseholdInviteRepository
final householdInviteRepositoryProvider = Provider<HouseholdInviteRepository>((ref) {
  return HouseholdInviteRepository(appDb);
});