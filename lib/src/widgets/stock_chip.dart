import 'package:flutter/material.dart';
import '../../database/models/pantry_items.dart';
import '../theme/colors.dart';

/// A compact stock status chip with subtle styling
///
/// Shows different states:
/// - "In Stock" (success colors)
/// - "Low Stock" (warning colors)
/// - "Out" (error colors)
/// - "New item" (success colors)
/// - "Not in Pantry" (neutral colors)
///
/// Uses subtle tinted backgrounds and darker text for minimal visual competition
class StockChip extends StatelessWidget {
  final StockStatus? status;
  final bool isNewItem;
  final bool showNotInPantry;

  const StockChip({
    super.key,
    this.status,
    this.isNewItem = false,
    this.showNotInPantry = false,
  });

  String get _label {
    if (isNewItem) {
      return 'New item';
    } else if (showNotInPantry) {
      return 'Not in Pantry';
    } else if (status != null) {
      switch (status!) {
        case StockStatus.outOfStock:
          return 'Out';
        case StockStatus.lowStock:
          return 'Low Stock';
        case StockStatus.inStock:
          return 'In Stock';
      }
    }
    return '';
  }

  Color get _backgroundColor {
    if (isNewItem) {
      return AppColorSwatches.success[50]!.withOpacity(0.5);
    } else if (showNotInPantry) {
      return AppColorSwatches.neutral[250]!;
    } else if (status != null) {
      switch (status!) {
        case StockStatus.outOfStock:
          return AppColorSwatches.error[100]!.withOpacity(0.5);
        case StockStatus.lowStock:
          return AppColorSwatches.warning[100]!.withOpacity(0.5);
        case StockStatus.inStock:
          return AppColorSwatches.success[50]!.withOpacity(0.5);
      }
    }
    return Colors.transparent;
  }

  Color get _textColor {
    if (isNewItem) {
      return AppColorSwatches.success[500]!;
    } else if (showNotInPantry) {
      return AppColorSwatches.neutral[600]!;
    } else if (status != null) {
      switch (status!) {
        case StockStatus.outOfStock:
          return AppColorSwatches.error[500]!;
        case StockStatus.lowStock:
          return AppColorSwatches.warning[500]!;
        case StockStatus.inStock:
          return AppColorSwatches.success[600]!;
      }
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if no status and not new item and not showing not in pantry
    if (!isNewItem && !showNotInPantry && status == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _textColor,
          height: 1.0,
        ),
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
