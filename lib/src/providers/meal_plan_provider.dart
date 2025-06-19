import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/database/models/meal_plan_items.dart';
import 'package:recipe_app/database/powersync.dart';
import '../repositories/meal_plan_repository.dart';

// Repository provider
final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  return MealPlanRepository(appDb);
});

// Stream provider for meal plan by date (for real-time updates)
final mealPlanByDateStreamProvider = StreamProvider.family<MealPlanEntry?, String>((ref, date) {
  return (appDb.select(appDb.mealPlans)
      ..where((tbl) => tbl.date.equals(date))
      ..where((tbl) => tbl.deletedAt.isNull()))
      .watchSingleOrNull();
});

// Notifier for meal plan operations
final mealPlanNotifierProvider = NotifierProvider<MealPlanNotifier, void>(MealPlanNotifier.new);

class MealPlanNotifier extends Notifier<void> {
  late MealPlanRepository _repository;

  @override
  void build() {
    _repository = ref.read(mealPlanRepositoryProvider);
  }

  Future<void> addRecipe({
    required String date,
    required String recipeId,
    required String recipeTitle,
    String? userId,
    String? householdId,
  }) async {
    await _repository.addRecipe(
      date: date,
      recipeId: recipeId,
      recipeTitle: recipeTitle,
      userId: userId,
      householdId: householdId,
    );
    
    // Invalidate providers to trigger refresh
    ref.invalidate(mealPlanByDateStreamProvider(date));
  }

  Future<void> addNote({
    required String date,
    required String noteText,
    String? noteTitle,
    String? userId,
    String? householdId,
  }) async {
    await _repository.addNote(
      date: date,
      noteText: noteText,
      noteTitle: noteTitle,
      userId: userId,
      householdId: householdId,
    );
    
    // Invalidate providers to trigger refresh
    ref.invalidate(mealPlanByDateStreamProvider(date));
  }

  Future<void> removeItem({
    required String date,
    required String itemId,
    String? userId,
    String? householdId,
  }) async {
    await _repository.removeItem(
      date: date,
      itemId: itemId,
      userId: userId,
      householdId: householdId,
    );
    
    // Invalidate providers to trigger refresh
    ref.invalidate(mealPlanByDateStreamProvider(date));
  }

  Future<void> reorderItems({
    required String date,
    required List<MealPlanItem> reorderedItems,
    String? userId,
    String? householdId,
  }) async {
    await _repository.reorderItems(
      date: date,
      reorderedItems: reorderedItems,
      userId: userId,
      householdId: householdId,
    );
    
    // Invalidate providers to trigger refresh
    ref.invalidate(mealPlanByDateStreamProvider(date));
  }

  Future<void> clearItems({
    required String date,
    String? userId,
    String? householdId,
  }) async {
    await _repository.clearItems(
      date: date,
      userId: userId,
      householdId: householdId,
    );
    
    // Invalidate providers to trigger refresh
    ref.invalidate(mealPlanByDateStreamProvider(date));
  }

  Future<void> updateItem({
    required String date,
    required String itemId,
    String? noteText,
    String? noteTitle,
    String? userId,
    String? householdId,
  }) async {
    await _repository.updateItem(
      date: date,
      itemId: itemId,
      noteText: noteText,
      noteTitle: noteTitle,
      userId: userId,
      householdId: householdId,
    );
    
    // Invalidate providers to trigger refresh
    ref.invalidate(mealPlanByDateStreamProvider(date));
  }

  // Get recipe IDs for shopping list integration
  Future<List<String>> getRecipeIdsForDate({
    required String date,
    String? userId,
    String? householdId,
  }) async {
    return await _repository.getRecipeIdsForDate(
      date: date,
      userId: userId,
      householdId: householdId,
    );
  }

  // Move item between dates (for cross-date drag and drop)
  Future<void> moveItemBetweenDates({
    required String sourceDate,
    required String targetDate,
    required MealPlanItem item,
    required int sourceIndex,
    required int targetIndex,
    String? userId,
    String? householdId,
  }) async {
    // Get both meal plans
    final sourceMealPlan = await _repository.getMealPlanByDate(sourceDate, userId, householdId);
    final targetMealPlan = await _repository.getMealPlanByDate(targetDate, userId, householdId);
    
    // Extract items from source
    final sourceItems = sourceMealPlan?.items != null 
        ? List<MealPlanItem>.from(sourceMealPlan!.items as List)
        : <MealPlanItem>[];
    
    // Extract items from target
    final targetItems = targetMealPlan?.items != null 
        ? List<MealPlanItem>.from(targetMealPlan!.items as List)
        : <MealPlanItem>[];
    
    // Remove from source if index is valid
    if (sourceIndex < sourceItems.length) {
      sourceItems.removeAt(sourceIndex);
      // Update positions in source
      for (int i = 0; i < sourceItems.length; i++) {
        sourceItems[i] = sourceItems[i].copyWith(position: i);
      }
    }
    
    // Add to target at specified index
    final newItem = item.copyWith(position: targetIndex);
    if (targetIndex >= targetItems.length) {
      targetItems.add(newItem);
    } else {
      targetItems.insert(targetIndex, newItem);
    }
    
    // Update positions in target
    for (int i = 0; i < targetItems.length; i++) {
      targetItems[i] = targetItems[i].copyWith(position: i);
    }
    
    // Save both meal plans
    if (sourceItems.isEmpty) {
      // If source is now empty, clear it
      await _repository.clearItems(
        date: sourceDate,
        userId: userId,
        householdId: householdId,
      );
    } else {
      await _repository.createOrUpdateMealPlan(
        date: sourceDate,
        items: sourceItems,
        userId: userId,
        householdId: householdId,
      );
    }
    
    await _repository.createOrUpdateMealPlan(
      date: targetDate,
      items: targetItems,
      userId: userId,
      householdId: householdId,
    );
    
    // Invalidate both date providers
    ref.invalidate(mealPlanByDateStreamProvider(sourceDate));
    ref.invalidate(mealPlanByDateStreamProvider(targetDate));
  }
}

// Helper class for date range queries
class MealPlanDateRange {
  final String startDate;
  final String endDate;

  MealPlanDateRange({required this.startDate, required this.endDate});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MealPlanDateRange &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;
}

// Provider for generating date list (for infinite scroll)
final mealPlanDatesProvider = Provider<List<String>>((ref) {
  final today = DateTime.now();
  final dates = <String>[];
  
  // Generate 30 days starting from today
  for (int i = 0; i < 30; i++) {
    final date = today.add(Duration(days: i));
    dates.add(_formatDate(date));
  }
  
  return dates;
});

// State provider for tracking loaded date ranges (for infinite scroll)
final loadedDateRangeProvider = StateProvider<int>((ref) => 30); // Initial 30 days

// Provider for extended date list based on loaded range
final extendedMealPlanDatesProvider = Provider<List<String>>((ref) {
  final loadedDays = ref.watch(loadedDateRangeProvider);
  final today = DateTime.now();
  final dates = <String>[];
  
  // Generate dates based on loaded range
  for (int i = 0; i < loadedDays; i++) {
    final date = today.add(Duration(days: i));
    dates.add(_formatDate(date));
  }
  
  return dates;
});

// Helper function to format date as YYYY-MM-DD
String _formatDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}