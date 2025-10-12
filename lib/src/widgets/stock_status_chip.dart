import 'package:flutter/material.dart';
import '../../database/models/pantry_items.dart';
import '../theme/colors.dart';

/// A chip widget that displays the stock status using semantic colors.
///
/// Shows different states:
/// - "In Stock" (success background)
/// - "Low Stock" (warning background)
/// - "Out of Stock" (error background)
/// - "New item" (success background)
class StockStatusChip extends StatelessWidget {
  final StockStatus? status;
  final bool isNewItem;

  const StockStatusChip({
    super.key,
    this.status,
    this.isNewItem = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    Color backgroundColor;
    String label;

    if (isNewItem) {
      backgroundColor = colors.successBackground;
      label = 'New item';
    } else if (status != null) {
      switch (status!) {
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
          color: colors.textPrimary,
        ),
      ),
    );
  }
}
