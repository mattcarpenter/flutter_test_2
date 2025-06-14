import 'package:recipe_app/database/models/meal_plan_items.dart';

// Model for a date with its meal plan items
class DayMealPlan {
  final String date;
  final DateTime dateTime;
  final List<MealPlanItem> items;
  final bool isEmpty;

  DayMealPlan({
    required this.date,
    required this.dateTime,
    required this.items,
  }) : isEmpty = items.isEmpty;

  // Helper getters
  List<MealPlanItem> get recipes => items.where((item) => item.isRecipe).toList();
  List<MealPlanItem> get notes => items.where((item) => item.isNote).toList();
  
  // Sort items by position
  List<MealPlanItem> get sortedItems {
    final sorted = List<MealPlanItem>.from(items);
    sorted.sort((a, b) => a.position.compareTo(b.position));
    return sorted;
  }

  DayMealPlan copyWith({
    String? date,
    DateTime? dateTime,
    List<MealPlanItem>? items,
  }) {
    return DayMealPlan(
      date: date ?? this.date,
      dateTime: dateTime ?? this.dateTime,
      items: items ?? this.items,
    );
  }
}

// Model for shopping list ingredient aggregation
class MealPlanIngredient {
  final String recipeId;
  final String recipeTitle;
  final String ingredientName;
  final String? amount;
  final String? unit;
  final String? note;
  final bool alreadyInPantry;
  final bool alreadyInShoppingList;
  final bool shouldAdd; // Default state for checkbox

  MealPlanIngredient({
    required this.recipeId,
    required this.recipeTitle,
    required this.ingredientName,
    this.amount,
    this.unit,
    this.note,
    required this.alreadyInPantry,
    required this.alreadyInShoppingList,
    required this.shouldAdd,
  });

  MealPlanIngredient copyWith({
    String? recipeId,
    String? recipeTitle,
    String? ingredientName,
    String? amount,
    String? unit,
    String? note,
    bool? alreadyInPantry,
    bool? alreadyInShoppingList,
    bool? shouldAdd,
  }) {
    return MealPlanIngredient(
      recipeId: recipeId ?? this.recipeId,
      recipeTitle: recipeTitle ?? this.recipeTitle,
      ingredientName: ingredientName ?? this.ingredientName,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      note: note ?? this.note,
      alreadyInPantry: alreadyInPantry ?? this.alreadyInPantry,
      alreadyInShoppingList: alreadyInShoppingList ?? this.alreadyInShoppingList,
      shouldAdd: shouldAdd ?? this.shouldAdd,
    );
  }
}

// Model for pantry check results
class PantryCheckResult {
  final String recipeId;
  final String recipeTitle;
  final int totalIngredients;
  final int availableIngredients;
  final double matchPercentage;
  final List<String> missingIngredients;

  PantryCheckResult({
    required this.recipeId,
    required this.recipeTitle,
    required this.totalIngredients,
    required this.availableIngredients,
    required this.missingIngredients,
  }) : matchPercentage = totalIngredients > 0 ? availableIngredients / totalIngredients : 0.0;

  bool get isFullyAvailable => availableIngredients == totalIngredients;
  bool get isPartiallyAvailable => availableIngredients > 0 && availableIngredients < totalIngredients;
  bool get isNotAvailable => availableIngredients == 0;
}