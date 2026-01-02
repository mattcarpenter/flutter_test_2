import 'package:flutter/material.dart';
import '../../database/models/pantry_items.dart';
import '../localization/l10n_extension.dart';
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

  String _getLabel(BuildContext context) {
    if (isNewItem) {
      return context.l10n.stockStatusNewItem;
    } else if (showNotInPantry) {
      return context.l10n.stockStatusNotInPantry;
    } else if (status != null) {
      switch (status!) {
        case StockStatus.outOfStock:
          return context.l10n.stockStatusOut;
        case StockStatus.lowStock:
          return context.l10n.stockStatusLowStock;
        case StockStatus.inStock:
          return context.l10n.stockStatusInStock;
      }
    }
    return '';
  }

  Color _getBackgroundColor(AppColors colors) {
    if (isNewItem) {
      return colors.successBackground;
    } else if (showNotInPantry) {
      return colors.surfaceVariant;
    } else if (status != null) {
      switch (status!) {
        case StockStatus.outOfStock:
          return colors.errorBackground;
        case StockStatus.lowStock:
          return colors.warningBackground;
        case StockStatus.inStock:
          return colors.successBackground;
      }
    }
    return Colors.transparent;
  }

  Color _getTextColor(AppColors colors) {
    if (isNewItem) {
      return colors.success;
    } else if (showNotInPantry) {
      return colors.textSecondary;
    } else if (status != null) {
      switch (status!) {
        case StockStatus.outOfStock:
          return colors.error;
        case StockStatus.lowStock:
          return colors.warning;
        case StockStatus.inStock:
          return colors.success;
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

    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(colors),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        _getLabel(context),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _getTextColor(colors),
          height: 1.0,
        ),
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
