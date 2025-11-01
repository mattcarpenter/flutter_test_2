import 'package:flutter/material.dart';
import '../../database/models/pantry_items.dart';
import '../models/ingredient_pantry_match.dart';
import 'stock_chip.dart';

/// A chip widget that displays the stock status of an ingredient based on its pantry match.
///
/// Shows different states:
/// - "In Stock" (green) - pantry item is in stock OR ingredient can be made via sub-recipe
/// - "Low Stock" (orange) - pantry item is low stock
/// - "Out" (red) - pantry item is out of stock
/// - null (no chip) - ingredient has no match
class IngredientStockChip extends StatelessWidget {
  final IngredientPantryMatch match;

  const IngredientStockChip({
    super.key,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    if (!match.hasMatch) {
      return const SizedBox.shrink(); // No chip for no match
    }

    // Determine stock status to display
    StockStatus? status;

    if (match.hasPantryMatch) {
      // Direct pantry match - use actual stock status
      status = match.pantryItem!.stockStatus;
    } else if (match.hasRecipeMatch) {
      // Recipe-based match - show as "In Stock" (makeable via sub-recipe)
      status = StockStatus.inStock;
    }

    return StockChip(status: status);
  }
}
