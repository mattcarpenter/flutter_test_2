import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:recipe_app/database/models/pantry_items.dart'; // For StockStatus enum
import 'package:recipe_app/src/models/ingredient_pantry_match.dart';

/// A widget that displays a colored circle indicating the pantry match status
/// of a recipe ingredient.
class IngredientMatchCircle extends StatelessWidget {
  /// The ingredient-pantry match to display status for
  final IngredientPantryMatch match;
  
  /// Callback when the circle is tapped
  final VoidCallback onTap;
  
  /// Size of the circle
  final double size;

  const IngredientMatchCircle({
    Key? key,
    required this.match,
    required this.onTap,
    this.size = 8.0,
  }) : super(key: key);
  
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<IngredientPantryMatch>('match', match));
    properties.add(DiagnosticsProperty<bool>('hasMatch', match.hasMatch));
    if (match.hasMatch) {
      properties.add(EnumProperty<StockStatus>('stockStatus', match.pantryItem!.stockStatus));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getColorForMatch(),
        ),
      ),
    );
  }

  /// Returns the appropriate color based on the match status
  Color _getColorForMatch() {
    if (!match.hasMatch) {
      return Colors.grey; // No match found
    }
    
    // Match found, get color based on stock status
    switch (match.pantryItem!.stockStatus) {
      case StockStatus.outOfStock:
        return Colors.red;
      case StockStatus.lowStock:
        return Colors.yellow.shade700; // Darker yellow for better visibility
      case StockStatus.inStock:
        return Colors.green;
      default:
        return Colors.grey; // Fallback
    }
  }
}