import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../database/models/pantry_items.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';

/// A compact dropdown for selecting stock status
/// Displays as an outlined button with colored indicator and launches a context menu
class StockStatusDropdown extends StatelessWidget {
  final StockStatus value;
  final ValueChanged<StockStatus> onChanged;

  const StockStatusDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  // Stock status display configuration
  static const Map<StockStatus, String> _labels = {
    StockStatus.outOfStock: 'Out',
    StockStatus.lowStock: 'Low',
    StockStatus.inStock: 'In Stock',
  };

  static const Map<StockStatus, Color> _colors = {
    StockStatus.outOfStock: Color(0xFFEF5350), // Red
    StockStatus.lowStock: Color(0xFFFFA726),    // Orange
    StockStatus.inStock: Color(0xFF66BB6A),     // Green
  };

  Color _getColor(StockStatus status) => _colors[status]!;
  String _getLabel(StockStatus status) => _labels[status]!;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return AdaptivePullDownButton(
      items: StockStatus.values.map((status) {
        return AdaptiveMenuItem(
          title: _getLabel(status),
          icon: Icon(
            CupertinoIcons.circle_fill,
            color: _getColor(status),
          ),
          onTap: () {
            onChanged(status);
          },
        );
      }).toList(),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: colors.input,
          border: Border.all(
            color: colors.border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filled circle indicator
            Icon(
              CupertinoIcons.circle_fill,
              size: 10,
              color: _getColor(value),
            ),

            SizedBox(width: 6),

            // Status text
            Text(
              _getLabel(value),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),

            SizedBox(width: 4),

            // Down chevron
            Icon(
              CupertinoIcons.chevron_down,
              size: 12,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
