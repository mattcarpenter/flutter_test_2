import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Utility class for creating grouped list item styling with connected borders.
///
/// This provides consistent border and border radius styling for list items
/// that should appear visually connected (like in the recipe editor form).
class GroupedListStyling {
  /// Private constructor to prevent instantiation
  GroupedListStyling._();

  /// Returns the border radius for a grouped list item.
  ///
  /// Parameters:
  /// - [isGrouped]: Whether grouping is enabled
  /// - [isFirstInGroup]: Whether this is the first item
  /// - [isLastInGroup]: Whether this is the last item
  /// - [radius]: The corner radius to use (default: 8.0)
  static BorderRadius getBorderRadius({
    required bool isGrouped,
    required bool isFirstInGroup,
    required bool isLastInGroup,
    double radius = 8.0,
  }) {
    if (!isGrouped) {
      return BorderRadius.circular(radius);
    }

    if (isFirstInGroup && isLastInGroup) {
      // Single item in group
      return BorderRadius.circular(radius);
    } else if (isFirstInGroup) {
      return BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
      );
    } else if (isLastInGroup) {
      return BorderRadius.only(
        bottomLeft: Radius.circular(radius),
        bottomRight: Radius.circular(radius),
      );
    } else {
      // Middle item - no rounded corners
      return BorderRadius.zero;
    }
  }

  /// Returns the border for a grouped list item.
  ///
  /// Parameters:
  /// - [context]: BuildContext for theme access
  /// - [isGrouped]: Whether grouping is enabled
  /// - [isFirstInGroup]: Whether this is the first item
  /// - [isLastInGroup]: Whether this is the last item
  /// - [isDragging]: Whether the item is currently being dragged
  /// - [borderWidth]: The border width (default: 1.0)
  static Border getBorder({
    required BuildContext context,
    required bool isGrouped,
    required bool isFirstInGroup,
    required bool isLastInGroup,
    required bool isDragging,
    double borderWidth = 1.0,
  }) {
    final colors = AppColors.of(context);
    final borderColor = colors.groupedListBorder;

    if (!isGrouped || isDragging) {
      // During drag, use full border to prevent animation glitches
      return Border.all(color: borderColor, width: borderWidth);
    }

    if (isFirstInGroup && isLastInGroup) {
      // Single item gets full border
      return Border.all(color: borderColor, width: borderWidth);
    } else if (isFirstInGroup) {
      // First item: full border
      return Border.all(color: borderColor, width: borderWidth);
    } else {
      // Non-first items: omit top border to prevent double borders
      return Border(
        left: BorderSide(color: borderColor, width: borderWidth),
        right: BorderSide(color: borderColor, width: borderWidth),
        bottom: BorderSide(color: borderColor, width: borderWidth),
      );
    }
  }

  /// Helper method to determine visual index during drag operations.
  ///
  /// Parameters:
  /// - [index]: The actual index of the item
  /// - [draggedIndex]: The index of the item being dragged (null if not dragging)
  ///
  /// Returns the visual index (position where the item appears during drag),
  /// or null if the item is the one being dragged.
  static int? getVisualIndex(int index, int? draggedIndex) {
    if (draggedIndex == null) return null;

    // The dragged item doesn't have a visual position (it's floating)
    if (index == draggedIndex) {
      return null;
    }
    // Items before the dragged item stay in the same visual position
    else if (index < draggedIndex) {
      return index;
    }
    // Items after the dragged item shift up by one visual position
    else {
      return index - 1;
    }
  }
}
