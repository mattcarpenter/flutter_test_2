import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../database/models/ingredient_term_queues.dart';
import '../../database/models/ingredients.dart';
import '../../database/powersync.dart';

class IngredientTermQueueRepository {
  final AppDatabase _db;

  IngredientTermQueueRepository(this._db);

  /// Get all pending entries in the queue
  Future<List<IngredientTermQueueEntry>> getPendingEntries() async {
    return await (_db.select(_db.ingredientTermQueues)
          ..where((tbl) => tbl.status.equals('pending')))
        .get();
  }

  /// Get an entry by recipe ID and ingredient ID
  Future<IngredientTermQueueEntry?> getEntryByIds(
      String recipeId, String ingredientId) async {
    return await (_db.select(_db.ingredientTermQueues)
          ..where((tbl) =>
              tbl.recipeId.equals(recipeId) &
              tbl.ingredientId.equals(ingredientId)))
        .getSingleOrNull();
  }

  /// Insert a new entry into the queue
  Future<String> insertQueueEntry({
    required String recipeId,
    required String ingredientId,
    required Ingredient ingredient,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Prepare ingredient data for the API request
    // Extract only what's needed for the canonicalization API
    final Map<String, dynamic> apiIngredientData = {
      'name': ingredient.name,
      'quantity': _extractQuantity(ingredient),
      'unit': _extractUnit(ingredient),
    };
    
    final entry = IngredientTermQueuesCompanion.insert(
      recipeId: recipeId,
      ingredientId: ingredientId,
      requestTimestamp: now,
      ingredientData: json.encode(apiIngredientData),
    );
    
    await _db.into(_db.ingredientTermQueues).insert(entry);
    return entry.id.value;
  }

  /// Update an existing queue entry
  Future<void> updateEntry(IngredientTermQueueEntry entry) async {
    await (_db.update(_db.ingredientTermQueues)..where((tbl) => tbl.id.equals(entry.id)))
        .write(
          IngredientTermQueuesCompanion(
            status: Value(entry.status),
            retryCount: Value(entry.retryCount),
            lastTryTimestamp: Value(entry.lastTryTimestamp),
            responseData: Value(entry.responseData),
          ),
        );
  }

  /// Delete entries for a specific recipe
  Future<int> deleteEntriesByRecipeId(String recipeId) async {
    return await (_db.delete(_db.ingredientTermQueues)
          ..where((tbl) => tbl.recipeId.equals(recipeId)))
        .go();
  }

  /// Delete a specific entry
  Future<int> deleteEntry(String id) async {
    return await (_db.delete(_db.ingredientTermQueues)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  /// Helper function to extract the primary quantity from an ingredient
  double? _extractQuantity(Ingredient ingredient) {
    if (ingredient.primaryAmount1Value != null) {
      try {
        return double.parse(ingredient.primaryAmount1Value!);
      } catch (e) {
        // If it's not a number, return null
        return null;
      }
    }
    return null;
  }

  /// Helper function to extract the primary unit from an ingredient
  String? _extractUnit(Ingredient ingredient) {
    return ingredient.primaryAmount1Unit;
  }
}

final ingredientTermQueueRepositoryProvider = Provider<IngredientTermQueueRepository>((ref) {
  return IngredientTermQueueRepository(appDb);
});