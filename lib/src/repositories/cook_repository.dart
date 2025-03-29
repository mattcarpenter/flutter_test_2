import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../database/database.dart';
import '../../database/models/cooks.dart';

class CookRepository {
  final AppDatabase _db;

  CookRepository(this._db);

  /// Watch all cook entries that are not discarded.
  Stream<List<CookEntry>> watchCooks() {
    return (_db.select(_db.cooks)
      ..where((tbl) => tbl.status.equals('discarded').not())
    ).watch();
  }

  /// Start a new cook session.
  /// Returns the new cook's ID.
  Future<String> startCook({
    required String recipeId,
    required String recipeName,
    String? userId,
    String? householdId,
  }) async {
    final newId = const Uuid().v4();
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final cook = CooksCompanion.insert(
      id: Value(newId),
      recipeId: recipeId,
      userId: Value(userId),
      householdId: Value(householdId),
      recipeName: recipeName,
      currentStepIndex: Value(0),
      status: const Value(CookStatus.inProgress),
      startedAt: Value(currentTime),
    );
    await _db.into(_db.cooks).insert(cook);
    return newId;
  }

  /// Finish a cook session by updating its status to 'finished',
  /// setting the finishedAt timestamp, and optionally updating rating and notes.
  Future<void> finishCook({
    required String cookId,
    int? rating,
    String? notes,
  }) async {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.cooks)..where((tbl) => tbl.id.equals(cookId))).write(
      CooksCompanion(
        status: const Value(CookStatus.finished),
        finishedAt: Value(currentTime),
        rating: Value(rating),
        notes: Value(notes),
      ),
    );
  }

  /// Update cook details such as rating, notes, or progress (currentStepIndex).
  Future<void> updateCook({
    required String cookId,
    int? rating,
    String? notes,
    int? currentStepIndex,
  }) async {
    await (_db.update(_db.cooks)..where((tbl) => tbl.id.equals(cookId))).write(
      CooksCompanion(
        rating: rating != null ? Value(rating) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        currentStepIndex: currentStepIndex != null ? Value(currentStepIndex) : const Value.absent(),
      ),
    );
  }
}
