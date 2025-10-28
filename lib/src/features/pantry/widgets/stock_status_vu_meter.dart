import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../database/models/pantry_items.dart';
import '../../../theme/colors.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';

/// A compact VU meter-style stock status indicator
/// Displays 3 horizontal circles that fill based on stock level:
/// - Out of Stock: 1 circle filled (red), 2 gray
/// - Low Stock: 2 circles filled (orange), 1 gray
/// - In Stock: 3 circles filled (green)
class StockStatusVuMeter extends StatelessWidget {
  final StockStatus value;
  final ValueChanged<StockStatus> onChanged;

  const StockStatusVuMeter({
    super.key,
    required this.value,
    required this.onChanged,
  });

  String _getStatusLabel(StockStatus status) {
    switch (status) {
      case StockStatus.outOfStock:
        return 'Out of Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.inStock:
        return 'In Stock';
    }
  }

  Color _getStatusColor(StockStatus status) {
    switch (status) {
      case StockStatus.outOfStock:
        return AppColorSwatches.error[500]!;
      case StockStatus.lowStock:
        return AppColorSwatches.warning[400]!;
      case StockStatus.inStock:
        return AppColorSwatches.success[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Tooltip(
      message: _getStatusLabel(value),
      child: Semantics(
        label: 'Stock status: ${_getStatusLabel(value)}',
        button: true,
        hint: 'Tap to change stock status',
        child: AdaptivePullDownButton(
          items: StockStatus.values.map((status) {
            return AdaptiveMenuItem(
              title: _getStatusLabel(status),
              icon: Icon(
                CupertinoIcons.circle_fill,
                color: _getStatusColor(status),
              ),
              onTap: () => onChanged(status),
            );
          }).toList(),
          child: Container(
            width: 48,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: AppColorSwatches.neutral[300]!,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: _VuMeterCircles(status: value),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 3-circle row that displays the stock level
class _VuMeterCircles extends StatelessWidget {
  final StockStatus status;

  const _VuMeterCircles({required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Circle(circleIndex: 0, status: status), // Left
        const SizedBox(width: 4),
        _Circle(circleIndex: 1, status: status), // Middle
        const SizedBox(width: 4),
        _Circle(circleIndex: 2, status: status), // Right
      ],
    );
  }
}

/// Individual circle in the VU meter
class _Circle extends StatelessWidget {
  final int circleIndex; // 0=left, 1=middle, 2=right
  final StockStatus status;

  const _Circle({required this.circleIndex, required this.status});

  bool get _isFilled {
    switch (status) {
      case StockStatus.outOfStock:
        return circleIndex == 0; // Only left circle
      case StockStatus.lowStock:
        return circleIndex <= 1; // Left 2 circles
      case StockStatus.inStock:
        return true; // All circles
    }
  }

  Color _getColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    if (!_isFilled) {
      // Unfilled circles
      return brightness == Brightness.light
          ? AppColorSwatches.neutral[300]! // Light gray
          : AppColorSwatches.neutral[700]!; // Dark gray
    }

    // Filled circles use status color
    switch (status) {
      case StockStatus.outOfStock:
        return AppColorSwatches.error[500]!;
      case StockStatus.lowStock:
        return AppColorSwatches.warning[400]!;
      case StockStatus.inStock:
        return brightness == Brightness.light
            ? AppColorSwatches.success[600]! // Darker green for light mode
            : AppColorSwatches.success[400]!; // Lighter green for dark mode
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: _getColor(context),
        shape: BoxShape.circle,
      ),
    );
  }
}
