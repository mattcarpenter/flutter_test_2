import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../database/database.dart';
import '../services/logging/app_logger.dart';
import 'package:recipe_app/database/powersync.dart';

class ClippingsRepository {
  final AppDatabase _db;

  ClippingsRepository(this._db);

  /// Watch all non-deleted clippings
  Stream<List<ClippingEntry>> watchClippings() {
    return (_db.select(_db.clippings)
          ..where((c) => c.deletedAt.isNull())
          ..orderBy([
            (c) => OrderingTerm(expression: c.updatedAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Get a single clipping by ID
  Future<ClippingEntry?> getClipping(String id) async {
    return (_db.select(_db.clippings)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Create a new clipping
  /// userId can be null for offline-created clippings (will be claimed on sign-in)
  Future<String> addClipping({
    String? userId,
    String? householdId,
    String? title,
    String? content,
  }) async {
    final newId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.into(_db.clippings).insert(ClippingsCompanion(
      id: Value(newId),
      title: Value(title),
      content: Value(content),
      userId: Value(userId),
      householdId: Value(householdId),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    AppLogger.debug('Created clipping: $newId');
    return newId;
  }

  /// Update an existing clipping
  Future<void> updateClipping({
    required String id,
    String? title,
    String? content,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.clippings)..where((c) => c.id.equals(id))).write(
      ClippingsCompanion(
        title: Value(title),
        content: Value(content),
        updatedAt: Value(now),
      ),
    );

    AppLogger.debug('Updated clipping: $id');
  }

  /// Soft delete a clipping
  Future<void> deleteClipping(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.clippings)..where((c) => c.id.equals(id))).write(
      ClippingsCompanion(
        deletedAt: Value(now),
      ),
    );

    AppLogger.debug('Soft deleted clipping: $id');
  }

  /// Bulk soft delete multiple clippings
  Future<void> deleteMultipleClippings(List<String> ids) async {
    if (ids.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.clippings)..where((c) => c.id.isIn(ids))).write(
      ClippingsCompanion(
        deletedAt: Value(now),
      ),
    );

    AppLogger.debug('Soft deleted ${ids.length} clippings');
  }
}

/// Provider for ClippingsRepository
final clippingsRepositoryProvider = Provider<ClippingsRepository>((ref) {
  return ClippingsRepository(appDb);
});
