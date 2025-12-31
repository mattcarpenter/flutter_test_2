import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/database/models/meal_plan_items.dart';
import 'package:recipe_app/database/powersync.dart';
import '../repositories/meal_plan_repository.dart';
import '../services/logging/app_logger.dart';
import 'auth_provider.dart';
import 'household_provider.dart';

// Repository provider
final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  return MealPlanRepository(appDb);
});

// Stream provider for meal plan by date (for real-time updates)
// Uses watch() instead of watchSingleOrNull() to handle duplicate records gracefully
final mealPlanByDateStreamProvider = StreamProvider.family<MealPlanEntry?, String>((ref, date) {
  final stream = (appDb.select(appDb.mealPlans)
      ..where((tbl) => tbl.date.equals(date))
      ..where((tbl) => tbl.deletedAt.isNull()))
      .watch();

  // Transform the list stream to single entry, handling duplicates
  return stream.map((results) {
    if (results.isEmpty) return null;
    if (results.length > 1) {
      // Log duplicate records for debugging
      AppLogger.warning(
        'MEAL_PLAN_DUPLICATE: Found ${results.length} records for date $date. '
        'Records: ${results.map((r) => "id=${r.id}, userId=${r.userId}, householdId=${r.householdId}").join("; ")}'
      );
    }
    // Return the first record (preferring household-scoped if available)
    final householdRecord = results.where((r) => r.householdId != null).firstOrNull;
    return householdRecord ?? results.first;
  });
});

// Notifier for meal plan operations
final mealPlanNotifierProvider = NotifierProvider<MealPlanNotifier, void>(MealPlanNotifier.new);

class MealPlanNotifier extends Notifier<void> {
  late MealPlanRepository _repository;

  @override
  void build() {
    _repository = ref.read(mealPlanRepositoryProvider);
  }

  /// Get current user ID from auth provider
  String? _getCurrentUserId() {
    return ref.read(currentUserProvider)?.id;
  }

  /// Get current household ID if user is in a household
  String? _getCurrentHouseholdId() {
    try {
      final householdState = ref.read(householdNotifierProvider);
      final householdId = householdState.currentHousehold?.id;
      AppLogger.debug(
        'MEAL_PLAN_HOUSEHOLD_LOOKUP: currentHousehold=${householdState.currentHousehold != null}, '
        'householdId=$householdId'
      );
      return householdId;
    } catch (e) {
      // User may not be authenticated or household provider not ready
      AppLogger.warning('MEAL_PLAN_HOUSEHOLD_LOOKUP_ERROR: $e');
      return null;
    }
  }

  /// Resolve userId and householdId with smart defaults.
  ///
  /// Strategy:
  /// - Always set userId (identifies the creator)
  /// - Set householdId if user is in a household (makes it shared)
  /// - If explicit values are provided, they take precedence
  /// - Never blocks if values can't be determined (graceful degradation)
  ({String? userId, String? householdId}) _resolveOwnership({
    String? userId,
    String? householdId,
  }) {
    // Use provided values or fall back to current user/household
    final resolvedUserId = userId ?? _getCurrentUserId();
    final resolvedHouseholdId = householdId ?? _getCurrentHouseholdId();

    return (userId: resolvedUserId, householdId: resolvedHouseholdId);
  }

  Future<void> addRecipe({
    required String date,
    required String recipeId,
    required String recipeTitle,
    String? userId,
    String? householdId,
  }) async {
    final ownership = _resolveOwnership(userId: userId, householdId: householdId);

    AppLogger.info(
      'MEAL_PLAN_ADD_RECIPE: date=$date, recipeId=$recipeId, '
      'userId=${ownership.userId}, householdId=${ownership.householdId}'
    );

    await _repository.addRecipe(
      date: date,
      recipeId: recipeId,
      recipeTitle: recipeTitle,
      userId: ownership.userId,
      householdId: ownership.householdId,
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
    final ownership = _resolveOwnership(userId: userId, householdId: householdId);

    await _repository.addNote(
      date: date,
      noteText: noteText,
      noteTitle: noteTitle,
      userId: ownership.userId,
      householdId: ownership.householdId,
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
    final ownership = _resolveOwnership(userId: userId, householdId: householdId);

    await _repository.removeItem(
      date: date,
      itemId: itemId,
      userId: ownership.userId,
      householdId: ownership.householdId,
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
    final ownership = _resolveOwnership(userId: userId, householdId: householdId);

    await _repository.reorderItems(
      date: date,
      reorderedItems: reorderedItems,
      userId: ownership.userId,
      householdId: ownership.householdId,
    );

    // Invalidate providers to trigger refresh
    ref.invalidate(mealPlanByDateStreamProvider(date));
  }

  Future<void> clearItems({
    required String date,
    String? userId,
    String? householdId,
  }) async {
    final ownership = _resolveOwnership(userId: userId, householdId: householdId);

    await _repository.clearItems(
      date: date,
      userId: ownership.userId,
      householdId: ownership.householdId,
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
    final ownership = _resolveOwnership(userId: userId, householdId: householdId);

    await _repository.updateItem(
      date: date,
      itemId: itemId,
      noteText: noteText,
      noteTitle: noteTitle,
      userId: ownership.userId,
      householdId: ownership.householdId,
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
    final ownership = _resolveOwnership(userId: userId, householdId: householdId);

    return await _repository.getRecipeIdsForDate(
      date: date,
      userId: ownership.userId,
      householdId: ownership.householdId,
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
    // For drag operations, use unfiltered query to find the records being displayed.
    // This handles the case where User B is dragging an item from User A's household record.
    // We inherit ownership from the source record to ensure we update the correct record.
    final sourceMealPlan = await _repository.getMealPlanByDateUnfiltered(sourceDate);
    final targetMealPlan = await _repository.getMealPlanByDateUnfiltered(targetDate);

    // Inherit ownership from source record, or fall back to resolved ownership for new records
    final sourceOwnership = sourceMealPlan != null
        ? (userId: sourceMealPlan.userId, householdId: sourceMealPlan.householdId)
        : _resolveOwnership(userId: userId, householdId: householdId);

    // For target, prefer source's ownership (keep items in same scope),
    // or use target's existing ownership, or fall back to resolved
    final targetOwnership = targetMealPlan != null
        ? (userId: targetMealPlan.userId, householdId: targetMealPlan.householdId)
        : sourceOwnership;

    AppLogger.info(
      'MEAL_PLAN_MOVE_START: sourceDate=$sourceDate, targetDate=$targetDate, '
      'itemId=${item.id}, sourceOwnership=(userId=${sourceOwnership.userId}, householdId=${sourceOwnership.householdId}), '
      'targetOwnership=(userId=${targetOwnership.userId}, householdId=${targetOwnership.householdId})'
    );

    AppLogger.debug(
      'MEAL_PLAN_MOVE_FOUND: sourceMealPlan=${sourceMealPlan != null ? "id=${sourceMealPlan.id}, items=${sourceMealPlan.items?.length ?? 0}" : "null"}, '
      'targetMealPlan=${targetMealPlan != null ? "id=${targetMealPlan.id}, items=${targetMealPlan.items?.length ?? 0}" : "null"}'
    );

    // Extract items from source
    final sourceItems = sourceMealPlan?.items != null
        ? List<MealPlanItem>.from(sourceMealPlan!.items as List)
        : <MealPlanItem>[];

    // Extract items from target
    final targetItems = targetMealPlan?.items != null
        ? List<MealPlanItem>.from(targetMealPlan!.items as List)
        : <MealPlanItem>[];

    final sourceItemCountBefore = sourceItems.length;

    // Remove from source by ID (not by index) for reliability
    sourceItems.removeWhere((sourceItem) => sourceItem.id == item.id);

    AppLogger.debug(
      'MEAL_PLAN_MOVE_REMOVE: itemId=${item.id}, sourceItemsBefore=$sourceItemCountBefore, sourceItemsAfter=${sourceItems.length}, '
      'removed=${sourceItemCountBefore - sourceItems.length}'
    );

    // Update positions in source
    for (int i = 0; i < sourceItems.length; i++) {
      sourceItems[i] = sourceItems[i].copyWith(position: i);
    }

    // Check if item already exists in target (prevent duplicates)
    final existsInTarget = targetItems.any((targetItem) => targetItem.id == item.id);
    if (existsInTarget) {
      // Remove existing instance before adding new one
      targetItems.removeWhere((targetItem) => targetItem.id == item.id);
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

    // Batch database operations to minimize race condition window
    // Note: Always use createOrUpdateMealPlan for both source and target.
    // Don't use clearItems (soft-delete) for empty source - that causes record
    // accumulation when items are dragged back and forth between dates.
    await Future.wait([
      // Update source (empty items list is fine - keeps the record for reuse)
      _repository.createOrUpdateMealPlan(
        date: sourceDate,
        items: sourceItems,
        userId: sourceOwnership.userId,
        householdId: sourceOwnership.householdId,
      ),

      // Update target - use source ownership to keep items in same scope
      // (if User A created a household record, User B's drag should update that same household record)
      _repository.createOrUpdateMealPlan(
        date: targetDate,
        items: targetItems,
        userId: sourceOwnership.userId,
        householdId: sourceOwnership.householdId,
      ),
    ]);

    // Invalidate both date providers after both operations complete
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

// Global drag state - tracks which item is being dragged and from which date
class MealPlanDragState {
  final String itemId;
  final String sourceDate;

  const MealPlanDragState({required this.itemId, required this.sourceDate});
}

final mealPlanDraggingItemProvider = StateProvider<MealPlanDragState?>((ref) => null);