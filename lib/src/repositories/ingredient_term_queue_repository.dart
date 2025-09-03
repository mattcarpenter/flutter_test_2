import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../database/database.dart';
import '../../database/models/ingredient_term_queues.dart';
import '../../database/models/ingredients.dart';
import '../../database/powersync.dart';
import '../services/ingredient_parser_service.dart';

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
    // Parse the ingredient string to extract clean name for canonicalization
    final parserService = IngredientParserService();
    final parseResult = parserService.parse(ingredient.name);
    
    final Map<String, dynamic> apiIngredientData = {
      'name': parseResult.cleanName.isNotEmpty 
          ? parseResult.cleanName 
          : ingredient.name, // Fallback to original if parsing fails
      'quantity': null,
      'unit': null,
    };

    // Generate a UUID for the entry
    final id = const Uuid().v4();

    final entry = IngredientTermQueuesCompanion.insert(
      id: Value(id),  // Explicitly provide the id as a Value
      recipeId: recipeId,
      ingredientId: ingredientId,
      requestTimestamp: now,
      ingredientData: json.encode(apiIngredientData),
      status: const Value('pending'),
      retryCount: const Value(0),  // Explicitly set retryCount to 0
      // Don't set lastTryTimestamp as it's defined as nullable in the model
      // responseData is also nullable, so we don't need to set it
    );

    await _db.into(_db.ingredientTermQueues).insert(entry);
    return id;
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

}

final ingredientTermQueueRepositoryProvider = Provider<IngredientTermQueueRepository>((ref) {
  return IngredientTermQueueRepository(appDb);
});
