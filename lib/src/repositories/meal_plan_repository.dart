import 'package:drift/drift.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/database/models/meal_plan_items.dart';

class MealPlanRepository {
  final AppDatabase _db;

  MealPlanRepository(this._db);

  // Get meal plan for a specific date
  Future<MealPlanEntry?> getMealPlanByDate(String date, String? userId, String? householdId) async {
    var query = _db.select(_db.mealPlans)
      ..where((tbl) => tbl.date.equals(date))
      ..where((tbl) => tbl.deletedAt.isNull());

    // Only filter by userId if explicitly provided (for household vs personal distinction)
    // PowerSync already ensures local DB only contains current user's data
    if (userId != null) {
      query = query..where((tbl) => tbl.userId.equals(userId));
    }

    // Only filter by householdId if explicitly provided
    if (householdId != null) {
      query = query..where((tbl) => tbl.householdId.equals(householdId));
    }

    final results = await query.get();
    return results.isNotEmpty ? results.first : null;
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
      // Update existing
      final updatedEntry = existing.copyWith(
        items: Value(items),
        updatedAt: Value(now),
      );
      
      await _db.update(_db.mealPlans).replace(updatedEntry);
      return updatedEntry;
    } else {
      // Create new
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

    // Only filter by userId if explicitly provided (for household vs personal distinction)
    // PowerSync already ensures local DB only contains current user's data
    if (userId != null) {
      query = query..where((tbl) => tbl.userId.equals(userId));
    }

    // Only filter by householdId if explicitly provided
    if (householdId != null) {
      query = query..where((tbl) => tbl.householdId.equals(householdId));
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