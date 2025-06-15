import '../../../../database/models/meal_plan_items.dart';

/// Data transfer object for meal plan drag operations
class MealPlanDragData {
  final MealPlanItem item;
  final String sourceDate;
  final int sourceIndex;

  const MealPlanDragData({
    required this.item,
    required this.sourceDate,
    required this.sourceIndex,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MealPlanDragData &&
        other.item == item &&
        other.sourceDate == sourceDate &&
        other.sourceIndex == sourceIndex;
  }

  @override
  int get hashCode => Object.hash(item, sourceDate, sourceIndex);

  @override
  String toString() => 'MealPlanDragData(item: ${item.id}, sourceDate: $sourceDate, sourceIndex: $sourceIndex)';
}