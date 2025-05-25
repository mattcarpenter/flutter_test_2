import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/models/pantry_items.dart';

/// A custom segmented control for selecting stock status with animated sliding background.
/// Features floating button segments inside a container with a sliding colored background.
class StockStatusSegmentedControl extends StatefulWidget {
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
  State<StockStatusSegmentedControl> createState() => _StockStatusSegmentedControlState();
}

class _StockStatusSegmentedControlState extends State<StockStatusSegmentedControl>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _widthAnimation;

  static const double containerRadius = 8.0;
  static const double padding = 3.0;
  static const double buttonRadius = containerRadius - padding; // 5.0
  static const double segmentSpacing = 2.0;
  static const double horizontalPadding = 12.0;

  // Labels for each status
  static const Map<StockStatus, String> _labels = {
    StockStatus.outOfStock: 'Out',
    StockStatus.lowStock: 'Low',
    StockStatus.inStock: 'In-Stock',
  };

  late Map<StockStatus, double> _segmentWidths;
  late Map<StockStatus, double> _segmentPositions;

  @override
  void initState() {
    super.initState();
    _calculateSegmentDimensions();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: _segmentPositions[widget.value]!,
      end: _segmentPositions[widget.value]!,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _widthAnimation = Tween<double>(
      begin: _segmentWidths[widget.value]!,
      end: _segmentWidths[widget.value]!,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: _getBackgroundColor(widget.value),
      end: _getBackgroundColor(widget.value),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _calculateSegmentDimensions() {
    const textStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    _segmentWidths = {};
    _segmentPositions = {};

    // Calculate segment widths to match the natural layout
    // Each segment: text width + horizontal padding (6px on each side = 12px total)
    const segmentHorizontalPadding = 12.0;
    
    for (final status in StockStatus.values) {
      final textPainter = TextPainter(
        text: TextSpan(text: _labels[status], style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      // Width = text width + padding to match _SegmentButton
      _segmentWidths[status] = textPainter.width + segmentHorizontalPadding;
    }

    // Calculate positions (cumulative widths + spacing)
    double currentPosition = 0;
    for (final status in StockStatus.values) {
      _segmentPositions[status] = currentPosition;
      currentPosition += _segmentWidths[status]! + segmentSpacing;
    }
  }

  @override
  void didUpdateWidget(StockStatusSegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animateToNewPosition();
    }
  }

  void _animateToNewPosition() {
    final newPosition = _segmentPositions[widget.value]!;
    final newWidth = _segmentWidths[widget.value]!;
    final newColor = _getBackgroundColor(widget.value);

    _slideAnimation = Tween<double>(
      begin: _slideAnimation.value,
      end: newPosition,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _widthAnimation = Tween<double>(
      begin: _widthAnimation.value,
      end: newWidth,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: _colorAnimation.value,
      end: newColor,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward(from: 0);
  }


  Color _getBackgroundColor(StockStatus status) {
    switch (status) {
      case StockStatus.outOfStock:
        return const Color(0xFFFFE6E6); // Light red
      case StockStatus.lowStock:
        return const Color(0xFFFFF7E6); // Light yellow
      case StockStatus.inStock:
        return Colors.white; // White
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(containerRadius),
      ),
      padding: const EdgeInsets.all(padding),
      child: IntrinsicWidth(
        child: Stack(
          children: [
            // Animated sliding background
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Positioned(
                  left: _slideAnimation.value,
                  top: 0,
                  child: Container(
                    width: _widthAnimation.value,
                    height: (widget.height ?? 32) - (2 * padding),
                    decoration: BoxDecoration(
                      color: _colorAnimation.value,
                      borderRadius: BorderRadius.circular(buttonRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Static text labels using natural layout
            Row(
              mainAxisSize: MainAxisSize.min,
              children: StockStatus.values.map((status) {
                final isLast = status == StockStatus.values.last;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SegmentButton(
                      label: _labels[status]!,
                      onTap: () => widget.onChanged(status),
                    ),
                    if (!isLast) const SizedBox(width: segmentSpacing),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

/// Individual segment button widget (now just handles text and tap)
class _SegmentButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 26, // Fixed height to match container
        padding: const EdgeInsets.symmetric(horizontal: 6.0), // Consistent padding for all segments
        decoration: const BoxDecoration(
          color: Colors.transparent, // No background - handled by animated layer
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black, // Always black text
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }
}
