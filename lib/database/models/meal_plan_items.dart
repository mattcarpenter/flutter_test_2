import 'package:json_annotation/json_annotation.dart';

part 'meal_plan_items.g.dart';

@JsonSerializable()
class MealPlanItem {
  final String id;
  final String type; // "recipe" or "note"
  final int position; // For ordering within the day
  final String? recipeId; // Only for recipe type
  final String? recipeTitle; // Cached recipe title for display
  final String? noteText; // Only for note type
  final String? noteTitle; // Optional title for notes

  MealPlanItem({
    required this.id,
    required this.type,
    required this.position,
    this.recipeId,
    this.recipeTitle,
    this.noteText,
    this.noteTitle,
  });

  factory MealPlanItem.fromJson(Map<String, dynamic> json) => _$MealPlanItemFromJson(json);
  Map<String, dynamic> toJson() => _$MealPlanItemToJson(this);

  MealPlanItem copyWith({
    String? id,
    String? type,
    int? position,
    String? recipeId,
    String? recipeTitle,
    String? noteText,
    String? noteTitle,
  }) {
    return MealPlanItem(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      recipeId: recipeId ?? this.recipeId,
      recipeTitle: recipeTitle ?? this.recipeTitle,
      noteText: noteText ?? this.noteText,
      noteTitle: noteTitle ?? this.noteTitle,
    );
  }

  // Factory constructors for convenience
  factory MealPlanItem.recipe({
    String? id,
    required int position,
    required String recipeId,
    required String recipeTitle,
  }) {
    return MealPlanItem(
      id: id ?? _generateId(),
      type: 'recipe',
      position: position,
      recipeId: recipeId,
      recipeTitle: recipeTitle,
    );
  }

  factory MealPlanItem.note({
    String? id,
    required int position,
    required String noteText,
    String? noteTitle,
  }) {
    return MealPlanItem(
      id: id ?? _generateId(),
      type: 'note',
      position: position,
      noteText: noteText,
      noteTitle: noteTitle,
    );
  }

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  bool get isRecipe => type == 'recipe';
  bool get isNote => type == 'note';
}