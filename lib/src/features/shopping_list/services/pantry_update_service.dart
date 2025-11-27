import '../../../../database/database.dart';
import '../../../../database/models/pantry_items.dart';
import '../../../services/logging/app_logger.dart';
import '../models/pantry_update_models.dart';

class PantryUpdateService {
  /// Analyzes shopping list items against pantry items to determine what needs updating
  static PantryUpdateResult analyzeUpdates({
    required List<ShoppingListItemEntry> shoppingListItems,
    required List<PantryItemEntry> pantryItems,
  }) {
    final itemsToAdd = <PantryUpdateItem>[];
    final itemsToUpdate = <PantryUpdateItem>[];

    // Filter to only active pantry items (not soft deleted)
    final activePantryItems = pantryItems.where((item) => item.deletedAt == null).toList();
    
    // If no pantry items, all shopping items are new
    if (activePantryItems.isEmpty) {
      for (final shoppingItem in shoppingListItems) {
        if (shoppingItem.bought) {
          itemsToAdd.add(PantryUpdateItem(
            shoppingListItem: shoppingItem,
            matchingPantryItem: null,
          ));
        }
      }
      return PantryUpdateResult(
        itemsToAdd: itemsToAdd,
        itemsToUpdate: itemsToUpdate,
      );
    }

    for (final shoppingItem in shoppingListItems) {
      // Skip if not marked as bought
      if (!shoppingItem.bought) continue;

      // Find matching pantry item based on terms
      final matchingPantryItem = _findMatchingPantryItem(shoppingItem, activePantryItems);

      if (matchingPantryItem == null) {
        // No match - this is a new item to add
        AppLogger.debug('No pantry match found for shopping item: ${shoppingItem.name}');
        itemsToAdd.add(PantryUpdateItem(
          shoppingListItem: shoppingItem,
          matchingPantryItem: null,
        ));
      } else if (matchingPantryItem.stockStatus != StockStatus.inStock) {
        // Match found but not in stock - needs update
        AppLogger.info('Pantry match found for shopping item "${shoppingItem.name}" -> "${matchingPantryItem.name}" (${matchingPantryItem.stockStatus.name})');
        itemsToUpdate.add(PantryUpdateItem(
          shoppingListItem: shoppingItem,
          matchingPantryItem: matchingPantryItem,
        ));
      } else {
        // If match found and already in stock, we skip it (no action needed)
        AppLogger.debug('Shopping item "${shoppingItem.name}" already in stock as "${matchingPantryItem.name}"');
      }
    }

    return PantryUpdateResult(
      itemsToAdd: itemsToAdd,
      itemsToUpdate: itemsToUpdate,
    );
  }

  /// Finds a matching pantry item based on term matching
  static PantryItemEntry? _findMatchingPantryItem(
    ShoppingListItemEntry shoppingItem,
    List<PantryItemEntry> pantryItems,
  ) {
    // Get shopping item terms, use name as fallback if no terms
    final rawTerms = shoppingItem.terms ?? [];
    final shoppingTerms = rawTerms.isNotEmpty ? rawTerms : [shoppingItem.name];

    // Normalize shopping terms for comparison
    final normalizedShoppingTerms = shoppingTerms
        .map((term) => term.toLowerCase().trim())
        .toSet();

    // Check each pantry item for a match
    for (final pantryItem in pantryItems) {
      final pantryTerms = pantryItem.terms ?? [];
      
      // Check if any pantry term matches any shopping term
      for (final pantryTerm in pantryTerms) {
        final normalizedPantryTerm = pantryTerm.value.toLowerCase().trim();
        if (normalizedShoppingTerms.contains(normalizedPantryTerm)) {
          // Found a match - return first match as per requirement
          return pantryItem;
        }
      }
    }

    return null;
  }
}