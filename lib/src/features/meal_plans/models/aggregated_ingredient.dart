import '../../../../database/database.dart';
import '../../../../database/models/pantry_items.dart';

class AggregatedIngredient {
  final String id;
  final String name;
  final List<String> terms;
  final List<String> sourceRecipeIds;
  final List<String> sourceRecipeTitles;
  final PantryItemEntry? matchingPantryItem;
  final bool existsInShoppingList;
  bool isChecked;

  AggregatedIngredient({
    required this.id,
    required this.name,
    required this.terms,
    required this.sourceRecipeIds,
    required this.sourceRecipeTitles,
    this.matchingPantryItem,
    this.existsInShoppingList = false,
    required this.isChecked,
  });

  // Helper to determine if should be checked by default
  static bool shouldBeCheckedByDefault({
    PantryItemEntry? pantryItem,
    required bool existsInShoppingList,
  }) {
    // Don't check if already in shopping list
    if (existsInShoppingList) return false;
    
    // Check if not in pantry or has low/out stock status
    if (pantryItem == null) return true;
    return pantryItem.stockStatus != StockStatus.inStock;
  }

  // Helper to get display text for sources
  String get sourcesDisplay {
    if (sourceRecipeTitles.length == 1) {
      return sourceRecipeTitles.first;
    }
    return '${sourceRecipeTitles.length} recipes';
  }

}