// lib/repositories/upload_queue_repository.dart
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../database/database.dart';
import '../../database/models/upload_queues.dart';
import '../../database/powersync.dart';

class UploadQueueRepository {
  final AppDatabase _db;

  UploadQueueRepository(this._db);

  // Insert a new upload queue entry.
  Future<int> insertUploadQueueEntry({
    required String fileName,
    required String recipeId,
  }) async {
    final entry = UploadQueuesCompanion.insert(
      fileName: fileName,
      status: const Value('pending'),
      recipeId: recipeId,
      retryCount: Value(0),
    );
    return await _db.into(_db.uploadQueues).insert(entry);
  }

  // Query pending entries.
  Future<List<UploadQueueEntry>> getPendingEntries() async {
    return await (_db.select(_db.uploadQueues)
      ..where((tbl) => tbl.status.equals('pending')))
        .get();
  }

  // Update an entry.
  Future<bool> updateEntry(UploadQueueEntry entry) async {
    return await _db.update(_db.uploadQueues).replace(entry);
  }

  // Optional: A method to mark an entry as uploaded.
  Future<int> markEntryAsUploaded(String id) async {
    return await (_db.update(_db.uploadQueues)
      ..where((tbl) => tbl.id.equals(id)))
        .write(UploadQueuesCompanion(
      status: const Value('uploaded'),
      lastTryTimestamp: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  // Helper: Resolve the full file path from a stored filename.
  Future<String> resolveFullPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }

  Future<UploadQueueEntry?> getEntryByFileName(String fileName) async {
    return await (_db.select(_db.uploadQueues)
      ..where((tbl) => tbl.fileName.equals(fileName)))
        .getSingleOrNull();
  }
}

// Provider for the UploadQueueRepository.
final uploadQueueRepositoryProvider = Provider<UploadQueueRepository>((ref) {
  return UploadQueueRepository(appDb);
});
