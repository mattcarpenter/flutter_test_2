import 'package:drift/drift.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/database/models/meal_plan_items.dart';
import '../services/logging/app_logger.dart';

class MealPlanRepository {
  final AppDatabase _db;

  MealPlanRepository(this._db);

  // Get meal plan for a specific date
  Future<MealPlanEntry?> getMealPlanByDate(String date, String? userId, String? householdId) async {
    var query = _db.select(_db.mealPlans)
      ..where((tbl) => tbl.date.equals(date))
      ..where((tbl) => tbl.deletedAt.isNull());

    // Query logic for household users:
    // - Match records with this household_id (shared records), OR
    // - Match records with NULL household_id AND matching user_id (legacy/personal records)
    // This handles the transition case where records were created before user joined household
    if (householdId != null && userId != null) {
      query = query..where((tbl) =>
        tbl.householdId.equals(householdId) |
        (tbl.householdId.isNull() & tbl.userId.equals(userId))
      );
    } else if (householdId != null) {
      query = query..where((tbl) => tbl.householdId.equals(householdId));
    } else if (userId != null) {
      query = query..where((tbl) => tbl.userId.equals(userId));
    }

    final results = await query.get();

    AppLogger.debug(
      'MEAL_PLAN_QUERY: date=$date, userId=$userId, householdId=$householdId, '
      'found=${results.length} records${results.isNotEmpty ? ": ${results.map((r) => "id=${r.id}, uId=${r.userId}, hId=${r.householdId}").join("; ")}" : ""}'
    );

    if (results.isEmpty) return null;

    // If multiple records exist (e.g., legacy personal + household), prefer household-scoped
    if (results.length > 1) {
      AppLogger.warning(
        'MEAL_PLAN_QUERY_DUPLICATE: Found ${results.length} records for date $date. '
        'Preferring household-scoped record.'
      );
      final householdRecord = results.where((r) => r.householdId != null).firstOrNull;
      return householdRecord ?? results.first;
    }

    return results.first;
  }

  /// Get meal plan by date without ownership filter.
  /// Used for drag operations where we need to find the record being displayed,
  /// regardless of who created it. Prefers household-scoped records.
  Future<MealPlanEntry?> getMealPlanByDateUnfiltered(String date) async {
    final query = _db.select(_db.mealPlans)
      ..where((tbl) => tbl.date.equals(date))
      ..where((tbl) => tbl.deletedAt.isNull());

    final results = await query.get();

    AppLogger.debug(
      'MEAL_PLAN_QUERY_UNFILTERED: date=$date, '
      'found=${results.length} records${results.isNotEmpty ? ": ${results.map((r) => "id=${r.id}, uId=${r.userId}, hId=${r.householdId}").join("; ")}" : ""}'
    );

    if (results.isEmpty) return null;

    // If multiple records exist, prefer household-scoped (matches stream provider behavior)
    if (results.length > 1) {
      AppLogger.warning(
        'MEAL_PLAN_QUERY_UNFILTERED_DUPLICATE: Found ${results.length} records for date $date. '
        'Preferring household-scoped record.'
      );
      final householdRecord = results.where((r) => r.householdId != null).firstOrNull;
      return householdRecord ?? results.first;
    }

    return results.first;
  }

  // Create or update meal plan for a date
  Future<MealPlanEntry> createOrUpdateMealPlan({
    required String date,
    required List<MealPlanItem> items,
    String? userId,
    String? householdId,
  }) async {
    final existing = await getMealPlanByDate(date, userId, householdId);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (existing != null) {
      // Check if we need to migrate a personal record to household scope
      final needsMigration = existing.householdId == null && householdId != null;

      AppLogger.info(
        'MEAL_PLAN_UPDATE: date=$date, existingId=${existing.id}, '
        'existingUserId=${existing.userId}, existingHouseholdId=${existing.householdId}, '
        'newHouseholdId=$householdId, needsMigration=$needsMigration, '
        'itemCount=${items.length}'
      );

      final updatedEntry = existing.copyWith(
        items: Value(items),
        updatedAt: Value(now),
        // Migrate personal records to household scope when applicable
        householdId: needsMigration ? Value(householdId) : Value.absent(),
      );

      await _db.update(_db.mealPlans).replace(updatedEntry);
      return updatedEntry;
    } else {
      // Create new
      AppLogger.info(
        'MEAL_PLAN_CREATE: date=$date, userId=$userId, householdId=$householdId, '
        'itemCount=${items.length}'
      );

      final newEntry = MealPlansCompanion.insert(
        date: date,
        userId: userId != null ? Value(userId) : const Value.absent(),
        householdId: householdId != null ? Value(householdId) : const Value.absent(),
        items: Value(items),
        createdAt: Value(now),
        updatedAt: Value(now),
      );

      await _db.into(_db.mealPlans).insert(newEntry);

      // Return the created entry
      return (await getMealPlanByDate(date, userId, householdId))!;
    }
  }

  // Add a recipe to a meal plan
  Future<void> addRecipe({
    required String date,
    required String recipeId,
    required String recipeTitle,
    String? userId,
    String? householdId,
  }) async {
    final existing = await getMealPlanByDate(date, userId, householdId);
    List<MealPlanItem> items = existing?.items ?? [];
    
    // Find next position
    final nextPosition = items.isEmpty ? 0 : items.map((e) => e.position).reduce((a, b) => a > b ? a : b) + 1;
    
    // Add new recipe item
    items.add(MealPlanItem.recipe(
      position: nextPosition,
      recipeId: recipeId,
      recipeTitle: recipeTitle,
    ));
    
    await createOrUpdateMealPlan(
      date: date,
      items: items,
      userId: userId,
      householdId: householdId,
    );
  }

  // Add a note to a meal plan
  Future<void> addNote({
    required String date,
    required String noteText,
    String? noteTitle,
    String? userId,
    String? householdId,
  }) async {
    final existing = await getMealPlanByDate(date, userId, householdId);
    List<MealPlanItem> items = existing?.items ?? [];
    
    // Find next position
    final nextPosition = items.isEmpty ? 0 : items.map((e) => e.position).reduce((a, b) => a > b ? a : b) + 1;
    
    // Add new note item
    items.add(MealPlanItem.note(
      position: nextPosition,
      noteText: noteText,
      noteTitle: noteTitle,
    ));
    
    await createOrUpdateMealPlan(
      date: date,
      items: items,
      userId: userId,
      householdId: householdId,
    );
  }

  // Remove an item from a meal plan
  Future<void> removeItem({
    required String date,
    required String itemId,
    String? userId,
    String? householdId,
  }) async {
    final existing = await getMealPlanByDate(date, userId, householdId);
    if (existing == null) return;
    
    List<MealPlanItem> items = existing.items ?? [];
    items.removeWhere((item) => item.id == itemId);
    
    // Reposition items
    items = _reorderItems(items);
    
    await createOrUpdateMealPlan(
      date: date,
      items: items,
      userId: userId,
      householdId: householdId,
    );
  }

  // Reorder items in a meal plan
  Future<void> reorderItems({
    required String date,
    required List<MealPlanItem> reorderedItems,
    String? userId,
    String? householdId,
  }) async {
    // Ensure proper positioning
    final items = _reorderItems(reorderedItems);
    
    await createOrUpdateMealPlan(
      date: date,
      items: items,
      userId: userId,
      householdId: householdId,
    );
  }

  // Clear all items for a date
  Future<void> clearItems({
    required String date,
    String? userId,
    String? householdId,
  }) async {
    final existing = await getMealPlanByDate(date, userId, householdId);
    if (existing != null) {
      // Soft delete the meal plan
      final now = DateTime.now().millisecondsSinceEpoch;
      final deletedEntry = existing.copyWith(deletedAt: Value(now));
      await _db.update(_db.mealPlans).replace(deletedEntry);
    }
  }

  // Update a specific item (for editing notes)
  Future<void> updateItem({
    required String date,
    required String itemId,
    String? noteText,
    String? noteTitle,
    String? userId,
    String? householdId,
  }) async {
    final existing = await getMealPlanByDate(date, userId, householdId);
    if (existing == null) return;
    
    List<MealPlanItem> items = existing.items ?? [];
    final itemIndex = items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;
    
    // Update the item
    items[itemIndex] = items[itemIndex].copyWith(
      noteText: noteText,
      noteTitle: noteTitle,
    );
    
    await createOrUpdateMealPlan(
      date: date,
      items: items,
      userId: userId,
      householdId: householdId,
    );
  }

  // Helper method to ensure proper positioning
  List<MealPlanItem> _reorderItems(List<MealPlanItem> items) {
    final reordered = List<MealPlanItem>.from(items);
    for (int i = 0; i < reordered.length; i++) {
      reordered[i] = reordered[i].copyWith(position: i);
    }
    return reordered;
  }

  // Get all meal plans for a user within a date range (for bulk operations)
  Future<List<MealPlanEntry>> getMealPlansInRange({
    required String startDate,
    required String endDate,
    String? userId,
    String? householdId,
  }) async {
    var query = _db.select(_db.mealPlans)
      ..where((tbl) => tbl.date.isBetweenValues(startDate, endDate))
      ..where((tbl) => tbl.deletedAt.isNull());

    // Query logic for household users:
    // - Match records with this household_id (shared records), OR
    // - Match records with NULL household_id AND matching user_id (legacy/personal records)
    if (householdId != null && userId != null) {
      query = query..where((tbl) =>
        tbl.householdId.equals(householdId) |
        (tbl.householdId.isNull() & tbl.userId.equals(userId))
      );
    } else if (householdId != null) {
      query = query..where((tbl) => tbl.householdId.equals(householdId));
    } else if (userId != null) {
      query = query..where((tbl) => tbl.userId.equals(userId));
    }

    return await query.get();
  }

  // Get all recipes from meal plans for a specific date (for shopping list integration)
  Future<List<String>> getRecipeIdsForDate({
    required String date,
    String? userId,
    String? householdId,
  }) async {
    final mealPlan = await getMealPlanByDate(date, userId, householdId);
    if (mealPlan?.items == null) return [];
    
    final items = mealPlan!.items;
    if (items == null) return [];
    
    final recipeIds = <String>[];
    for (final item in items) {
      if (item.isRecipe && item.recipeId != null) {
        recipeIds.add(item.recipeId!);
      }
    }
    return recipeIds;
  }
}