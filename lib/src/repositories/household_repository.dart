import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../database/powersync.dart';

class HouseholdRepository {
  final AppDatabase _db;

  HouseholdRepository(this._db);

  /// Watch all households.
  Stream<List<HouseholdEntry>> watchHouseholds() {
    return _db.select(_db.households).watch();
  }

  /// Insert a new household. The companion allows Drift to handle defaults.
  Future<int> addHousehold(HouseholdsCompanion household) {
    return _db.into(_db.households).insert(household);
  }

  /// Delete a household by its id.
  Future<int> deleteHousehold(String id) {
    return (_db.delete(_db.households)
      ..where((tbl) => tbl.id.equals(id))
    ).go();
  }
}

/// Provider for the HouseholdRepository. This uses the global [appDb] instance.
final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return HouseholdRepository(appDb);
});
