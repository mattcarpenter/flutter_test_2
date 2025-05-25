import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/models/pantry_items.dart';

/// A custom segmented control for selecting stock status with polished design.
/// Features floating button segments inside a container with proper spacing and colors.
class StockStatusSegmentedControl extends StatelessWidget {
  final StockStatus value;
  final ValueChanged<StockStatus> onChanged;
  final double? width;
  final double? height;

  const StockStatusSegmentedControl({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 150,
    this.height = 32,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const double containerRadius = 8.0;
    const double padding = 3.0;
    const double buttonRadius = containerRadius - padding; // 5.0

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(containerRadius),
      ),
      padding: const EdgeInsets.all(padding),
      child: Row(
        children: [
          _SegmentButton(
            status: StockStatus.outOfStock,
            label: 'Out',
            isSelected: value == StockStatus.outOfStock,
            selectedTextColor: _getSelectedTextColor(StockStatus.outOfStock),
            buttonRadius: buttonRadius,
            onTap: () => onChanged(StockStatus.outOfStock),
          ),
          const SizedBox(width: 2),
          _SegmentButton(
            status: StockStatus.lowStock,
            label: 'Low',
            isSelected: value == StockStatus.lowStock,
            selectedTextColor: _getSelectedTextColor(StockStatus.lowStock),
            buttonRadius: buttonRadius,
            onTap: () => onChanged(StockStatus.lowStock),
          ),
          const SizedBox(width: 2),
          _SegmentButton(
            status: StockStatus.inStock,
            label: 'Stock',
            isSelected: value == StockStatus.inStock,
            selectedTextColor: _getSelectedTextColor(StockStatus.inStock),
            buttonRadius: buttonRadius,
            onTap: () => onChanged(StockStatus.inStock),
          ),
        ],
      ),
    );
  }

  /// Get the selected text color based on stock status
  Color _getSelectedTextColor(StockStatus status) {
    switch (status) {
      case StockStatus.outOfStock:
        return const Color(0xFFDC2626); // Red
      case StockStatus.lowStock:
        return const Color(0xFFD97706); // Amber/Gold
      case StockStatus.inStock:
        return const Color(0xFF16A34A); // Green
    }
  }
}

/// Individual segment button widget
class _SegmentButton extends StatelessWidget {
  final StockStatus status;
  final String label;
  final bool isSelected;
  final Color selectedTextColor;
  final double buttonRadius;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.status,
    required this.label,
    required this.isSelected,
    required this.selectedTextColor,
    required this.buttonRadius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(buttonRadius),
            // Add subtle shadow for selected state
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? selectedTextColor : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}