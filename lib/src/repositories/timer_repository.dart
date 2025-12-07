import 'package:drift/drift.dart';
import 'package:recipe_app/database/database.dart';
import 'package:uuid/uuid.dart';
import '../services/logging/app_logger.dart';

class TimerRepository {
  final AppDatabase _db;

  TimerRepository(this._db);

  /// Watch all active timers (not expired), ordered by end timestamp ascending.
  Stream<List<TimerEntry>> watchActiveTimers() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.select(_db.timers)
          ..where((tbl) => tbl.endTimestamp.isBiggerThanValue(now))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.endTimestamp)]))
        .watch();
  }

  /// Get all active timers (not expired).
  Future<List<TimerEntry>> getActiveTimers() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.select(_db.timers)
          ..where((tbl) => tbl.endTimestamp.isBiggerThanValue(now))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.endTimestamp)]))
        .get();
  }

  /// Get a specific timer by ID.
  Future<TimerEntry?> getTimer(String timerId) async {
    try {
      return await (_db.select(_db.timers)
            ..where((tbl) => tbl.id.equals(timerId)))
          .getSingleOrNull();
    } catch (e) {
      AppLogger.error('Error getting timer $timerId', e);
      return null;
    }
  }

  /// Create a new timer and return the timer ID.
  Future<String> createTimer({
    required String recipeId,
    required String recipeName,
    required String stepId,
    required int stepNumber,
    required int totalSteps,
    required String detectedText,
    required int durationSeconds,
    String? notificationId,
  }) async {
    final timerId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final endTimestamp = now + (durationSeconds * 1000);

    final companion = TimersCompanion.insert(
      id: Value(timerId),
      recipeId: recipeId,
      recipeName: recipeName,
      stepId: stepId,
      stepNumber: stepNumber,
      totalSteps: totalSteps,
      detectedText: detectedText,
      durationSeconds: durationSeconds,
      endTimestamp: endTimestamp,
      createdAt: now,
      notificationId: Value(notificationId),
    );

    try {
      await _db.into(_db.timers).insert(companion);
      AppLogger.debug(
          'Created timer $timerId for recipe $recipeName (step $stepNumber/$totalSteps, ${durationSeconds}s)');
      return timerId;
    } catch (e) {
      AppLogger.error('Error creating timer', e);
      rethrow;
    }
  }

  /// Extend a timer by adding additional seconds to its end timestamp.
  Future<void> extendTimer(String timerId, int additionalSeconds) async {
    try {
      final timer = await getTimer(timerId);
      if (timer == null) {
        AppLogger.warning('Cannot extend timer $timerId: not found');
        return;
      }

      final newEndTimestamp =
          timer.endTimestamp + (additionalSeconds * 1000);

      await (_db.update(_db.timers)..where((tbl) => tbl.id.equals(timerId)))
          .write(TimersCompanion(
        endTimestamp: Value(newEndTimestamp),
      ));

      AppLogger.debug(
          'Extended timer $timerId by ${additionalSeconds}s (new end: $newEndTimestamp)');
    } catch (e) {
      AppLogger.error('Error extending timer $timerId', e);
      rethrow;
    }
  }

  /// Cancel a timer by deleting it.
  Future<void> cancelTimer(String timerId) async {
    try {
      await (_db.delete(_db.timers)..where((tbl) => tbl.id.equals(timerId)))
          .go();
      AppLogger.debug('Cancelled timer $timerId');
    } catch (e) {
      AppLogger.error('Error cancelling timer $timerId', e);
      rethrow;
    }
  }

  /// Delete timers that expired more than 1 hour ago.
  Future<void> cleanupExpiredTimers() async {
    try {
      final oneHourAgo =
          DateTime.now().millisecondsSinceEpoch - (60 * 60 * 1000);

      final deletedCount = await (_db.delete(_db.timers)
            ..where((tbl) => tbl.endTimestamp.isSmallerThanValue(oneHourAgo)))
          .go();

      if (deletedCount > 0) {
        AppLogger.debug('Cleaned up $deletedCount expired timers');
      }
    } catch (e) {
      AppLogger.error('Error cleaning up expired timers', e);
    }
  }

  /// Update the notification ID for a timer.
  Future<void> updateNotificationId(
      String timerId, String notificationId) async {
    try {
      await (_db.update(_db.timers)..where((tbl) => tbl.id.equals(timerId)))
          .write(TimersCompanion(
        notificationId: Value(notificationId),
      ));
      AppLogger.debug(
          'Updated notification ID for timer $timerId: $notificationId');
    } catch (e) {
      AppLogger.error('Error updating notification ID for timer $timerId', e);
      rethrow;
    }
  }
}
