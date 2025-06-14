import '../../../../database/database.dart';

/// Represents a single item in the pantry update process
class PantryUpdateItem {
  final ShoppingListItemEntry shoppingListItem;
  final PantryItemEntry? matchingPantryItem; // null = new item to add
  final bool isChecked;

  PantryUpdateItem({
    required this.shoppingListItem,
    this.matchingPantryItem,
    this.isChecked = true,
  });

  PantryUpdateItem copyWith({
    ShoppingListItemEntry? shoppingListItem,
    PantryItemEntry? matchingPantryItem,
    bool? isChecked,
  }) {
    return PantryUpdateItem(
      shoppingListItem: shoppingListItem ?? this.shoppingListItem,
      matchingPantryItem: matchingPantryItem ?? this.matchingPantryItem,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  bool get isNewItem => matchingPantryItem == null;
}

/// Result of analyzing shopping list items for pantry updates
class PantryUpdateResult {
  final List<PantryUpdateItem> itemsToAdd;
  final List<PantryUpdateItem> itemsToUpdate;

  PantryUpdateResult({
    required this.itemsToAdd,
    required this.itemsToUpdate,
  });

  bool get hasChanges => itemsToAdd.isNotEmpty || itemsToUpdate.isNotEmpty;
  int get totalItems => itemsToAdd.length + itemsToUpdate.length;
}