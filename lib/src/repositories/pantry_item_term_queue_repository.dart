import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../database/database.dart';
import '../../database/powersync.dart';

class PantryItemTermQueueRepository {
  final AppDatabase _db;

  PantryItemTermQueueRepository(this._db);

  /// Get all pending entries in the queue
  Future<List<PantryItemTermQueueEntry>> getPendingEntries() async {
    return await (_db.select(_db.pantryItemTermQueues)
          ..where((tbl) => tbl.status.equals('pending')))
        .get();
  }

  /// Get an entry by pantry item ID
  Future<PantryItemTermQueueEntry?> getEntryByPantryItemId(String pantryItemId) async {
    return await (_db.select(_db.pantryItemTermQueues)
          ..where((tbl) => tbl.pantryItemId.equals(pantryItemId)))
        .getSingleOrNull();
  }

  /// Insert a new entry into the queue
  Future<String> insertQueueEntry({
    required String pantryItemId,
    required String name,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Prepare pantry item data for the API request
    // Extract only what's needed for the canonicalization API
    final Map<String, dynamic> apiPantryItemData = {
      'name': name,
      // DO NOT include unit and quantity as per requirement
    };

    // Generate a UUID for the entry
    final id = const Uuid().v4();

    final entry = PantryItemTermQueuesCompanion.insert(
      id: id,  // id is a required field and should be a plain String
      pantryItemId: pantryItemId,
      requestTimestamp: now,
      pantryItemData: json.encode(apiPantryItemData),
      status: 'pending',  // Status is a required field
      retryCount: const Value(0),  // Explicitly set retryCount to 0 as a Value
      // Don't set lastTryTimestamp as it's defined as nullable in the model
      // responseData is also nullable, so we don't need to set it
    );

    await _db.into(_db.pantryItemTermQueues).insert(entry);
    return id;
  }

  /// Update an existing queue entry
  Future<void> updateEntry(PantryItemTermQueueEntry entry) async {
    await (_db.update(_db.pantryItemTermQueues)..where((tbl) => tbl.id.equals(entry.id)))
        .write(
          PantryItemTermQueuesCompanion(
            status: Value(entry.status),
            retryCount: Value(entry.retryCount),
            lastTryTimestamp: Value(entry.lastTryTimestamp),
            responseData: Value(entry.responseData),
          ),
        );
  }

  /// Delete a specific entry
  Future<int> deleteEntry(String id) async {
    return await (_db.delete(_db.pantryItemTermQueues)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  /// Delete entries for a specific pantry item
  Future<int> deleteEntriesByPantryItemId(String pantryItemId) async {
    return await (_db.delete(_db.pantryItemTermQueues)
          ..where((tbl) => tbl.pantryItemId.equals(pantryItemId)))
        .go();
  }
}

final pantryItemTermQueueRepositoryProvider = Provider<PantryItemTermQueueRepository>((ref) {
  return PantryItemTermQueueRepository(appDb);
});