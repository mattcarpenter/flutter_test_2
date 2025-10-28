import 'package:flutter/material.dart';
import '../../../../database/models/pantry_items.dart';
import '../../../theme/colors.dart';

/// A compact stock status chip for pantry items
/// Uses rounded rectangle with subtle tinted text to minimize visual competition
class PantryStockStatusChip extends StatelessWidget {
  final StockStatus status;

  const PantryStockStatusChip({
    super.key,
    required this.status,
  });

  String get _label {
    switch (status) {
      case StockStatus.outOfStock:
        return 'Out of Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.inStock:
        return 'In Stock';
    }
  }

  Color get _backgroundColor {
    switch (status) {
      case StockStatus.outOfStock:
        return AppColorSwatches.error[50]!; // Very light red
      case StockStatus.lowStock:
        return AppColorSwatches.warning[50]!; // Very light orange
      case StockStatus.inStock:
        return AppColorSwatches.success[50]!; // Very light green
    }
  }

  Color get _textColor {
    switch (status) {
      case StockStatus.outOfStock:
        return AppColorSwatches.error[600]!; // Darker red (tinted)
      case StockStatus.lowStock:
        return AppColorSwatches.warning[600]!; // Darker orange (tinted)
      case StockStatus.inStock:
        return AppColorSwatches.success[700]!; // Darker green (tinted)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _textColor,
          height: 1.0,
        ),
      ),
    );
  }
}
