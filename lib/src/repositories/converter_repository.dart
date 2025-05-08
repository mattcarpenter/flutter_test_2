import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../database/database.dart';

class ConverterRepository {
  final AppDatabase _db;
  ConverterRepository(this._db);

  /// Watch all converters that are not deleted.
  Stream<List<ConverterEntry>> watchConverters() {
    return (_db.select(_db.converters)
      ..where((t) => t.deletedAt.isNull()))
        .watch();
  }

  /// Get all converters for a specific term that are not deleted.
  Stream<List<ConverterEntry>> watchConvertersForTerm(String term) {
    return (_db.select(_db.converters)
      ..where((t) => t.deletedAt.isNull() & t.term.equals(term)))
        .watch();
  }

  /// Create a new converter. Returns the new converter's ID.
  Future<String> addConverter({
    required String term,
    required String fromUnit,
    required String toBaseUnit,
    required double conversionFactor,
    bool isApproximate = false,
    String? notes,
    String? userId,
    String? householdId,
  }) async {
    final newId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    final companion = ConvertersCompanion.insert(
      id: Value(newId),
      term: term,
      fromUnit: fromUnit,
      toBaseUnit: toBaseUnit,
      conversionFactor: conversionFactor,
      isApproximate: Value(isApproximate),
      notes: Value(notes),
      userId: Value(userId),
      householdId: Value(householdId),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    await _db.into(_db.converters).insert(companion);
    return newId;
  }

  /// Update an existing converter.
  Future<void> updateConverter({
    required String id,
    String? term,
    String? fromUnit,
    String? toBaseUnit,
    double? conversionFactor,
    bool? isApproximate,
    String? notes,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;

    final companion = ConvertersCompanion(
      term: term != null ? Value(term) : const Value.absent(),
      fromUnit: fromUnit != null ? Value(fromUnit) : const Value.absent(),
      toBaseUnit: toBaseUnit != null ? Value(toBaseUnit) : const Value.absent(),
      conversionFactor: conversionFactor != null ? Value(conversionFactor) : const Value.absent(),
      isApproximate: isApproximate != null ? Value(isApproximate) : const Value.absent(),
      notes: notes != null ? Value(notes) : const Value.absent(),
      updatedAt: Value(now),
    );

    return (_db.update(_db.converters)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  /// Soft-delete a converter.
  Future<void> deleteConverter(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.converters)..where((t) => t.id.equals(id)))
        .write(ConvertersCompanion(deletedAt: Value(now)));
  }

  /// Find the best converter for a term and unit.
  /// Attempts to find an exact match first, then falls back to longest matching terms.
  Future<ConverterEntry?> findBestConverter({
    required String term,
    required String unit,
  }) async {
    // First try to find an exact match
    final exactMatch = await (_db.select(_db.converters)
      ..where((c) =>
          c.deletedAt.isNull() &
          c.term.equals(term) &
          c.fromUnit.equals(unit)))
        .getSingleOrNull();

    if (exactMatch != null) {
      return exactMatch;
    }

    // If no exact match, get all converters for the unit
    final converters = await (_db.select(_db.converters)
      ..where((c) =>
          c.deletedAt.isNull() &
          c.fromUnit.equals(unit)))
        .get();

    // Find converters with terms that match parts of our term
    final matchingConverters = converters.where((c) =>
        term.toLowerCase().contains(c.term.toLowerCase())).toList();

    if (matchingConverters.isEmpty) {
      return null;
    }

    // Sort by term length (descending) to get the most specific match
    matchingConverters.sort((a, b) => b.term.length.compareTo(a.term.length));
    return matchingConverters.first;
  }

  /// Check if a converter already exists for the given term, fromUnit, and toBaseUnit
  Future<bool> converterExists({
    required String term,
    required String fromUnit,
    required String toBaseUnit,
  }) async {
    final count = await (_db.select(_db.converters)
      ..where((c) =>
          c.deletedAt.isNull() &
          c.term.equals(term) &
          c.fromUnit.equals(fromUnit) &
          c.toBaseUnit.equals(toBaseUnit)))
        .get()
        .then((result) => result.length);

    return count > 0;
  }
}
