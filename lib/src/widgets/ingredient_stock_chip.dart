import 'package:flutter/material.dart';
import '../../database/models/pantry_items.dart';
import '../models/ingredient_pantry_match.dart';
import '../theme/colors.dart';

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

    final colors = AppColors.of(context);
    Color backgroundColor;
    String label;

    if (match.hasPantryMatch) {
      // Direct pantry match - use stock status colors
      switch (match.pantryItem!.stockStatus) {
        case StockStatus.outOfStock:
          backgroundColor = colors.errorBackground;
          label = 'Out';
        case StockStatus.lowStock:
          backgroundColor = colors.warningBackground;
          label = 'Low Stock';
        case StockStatus.inStock:
          backgroundColor = colors.successBackground;
          label = 'In Stock';
      }
    } else if (match.hasRecipeMatch) {
      // Recipe-based match - show as "In Stock" (makeable via sub-recipe)
      backgroundColor = colors.successBackground;
      label = 'In Stock';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.of(context).textPrimary,
        ),
      ),
    );
  }
}
