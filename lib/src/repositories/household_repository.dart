import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../database/database.dart';
import '../../database/powersync.dart';

class HouseholdRepository {
  final AppDatabase _db;

  HouseholdRepository(this._db);

  // Existing methods
  Stream<List<HouseholdEntry>> watchHouseholds() {
    return _db.select(_db.households).watch();
  }

  Future<int> addHousehold(HouseholdsCompanion household) {
    return _db.into(_db.households).insert(household);
  }

  Future<int> deleteHousehold(String id) {
    return (_db.delete(_db.households)
      ..where((tbl) => tbl.id.equals(id))
    ).go();
  }

  // New household management methods
  Stream<HouseholdEntry?> watchCurrentUserHousehold(String userId) {
    final query = _db.select(_db.households).join([
      innerJoin(
        _db.householdMembers,
        _db.householdMembers.householdId.equalsExp(_db.households.id),
      )
    ]);
    
    query.where(_db.householdMembers.userId.equals(userId) & 
                _db.householdMembers.isActive.equals(1));
    
    return query.map((row) => row.readTable(_db.households)).watchSingleOrNull();
  }

  Stream<List<HouseholdMemberEntry>> watchHouseholdMembers(String householdId) {
    return (_db.select(_db.householdMembers)
      ..where((tbl) => tbl.householdId.equals(householdId) & 
                       tbl.isActive.equals(1))
    ).watch();
  }

  Future<HouseholdMemberEntry?> getCurrentUserMembership(String userId) async {
    return await (_db.select(_db.householdMembers)
      ..where((tbl) => tbl.userId.equals(userId) & 
                       tbl.isActive.equals(1))
    ).getSingleOrNull();
  }

  Future<bool> isHouseholdOwner(String userId, String householdId) async {
    final result = await (_db.select(_db.householdMembers)
      ..where((tbl) => tbl.userId.equals(userId) & 
                       tbl.householdId.equals(householdId) &
                       tbl.role.equals('owner') &
                       tbl.isActive.equals(1))
    ).getSingleOrNull();
    
    return result != null;
  }

  Future<void> addMember(HouseholdMembersCompanion member) {
    return _db.into(_db.householdMembers).insert(member);
  }

  Future<void> removeMember(String memberId) {
    return (_db.update(_db.householdMembers)
      ..where((tbl) => tbl.id.equals(memberId))
    ).write(HouseholdMembersCompanion(isActive: const Value(0)));
  }

  Future<void> updateMemberRole(String memberId, String role) {
    return (_db.update(_db.householdMembers)
      ..where((tbl) => tbl.id.equals(memberId))
    ).write(HouseholdMembersCompanion(role: Value(role)));
  }
  
  /// Watch all memberships for a user (active and inactive)
  Stream<List<HouseholdMemberEntry>> watchUserMemberships(String userId) {
    return (_db.select(_db.householdMembers)
      ..where((tbl) => tbl.userId.equals(userId))
    ).watch();
  }

  /// Get active memberships for startup check
  Future<List<HouseholdMemberEntry>> getActiveUserMemberships(String userId) async {
    return await (_db.select(_db.householdMembers)
      ..where((tbl) => tbl.userId.equals(userId) & tbl.isActive.equals(1))
    ).get();
  }
}

/// Provider for the HouseholdRepository. This uses the global [appDb] instance.
final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return HouseholdRepository(appDb);
});
