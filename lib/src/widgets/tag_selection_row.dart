import 'package:flutter/material.dart';

import '../constants/tag_colors.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../widgets/app_radio_button.dart';
import '../widgets/utils/grouped_list_styling.dart';

/// A row for selecting tags with checkbox, label, and color picker
class TagSelectionRow extends StatelessWidget {
  final String tagId;
  final String label;
  final String color;
  final bool checked;
  final VoidCallback? onToggle;
  final Function(String color) onColorChanged;
  final bool first;
  final bool last;

  const TagSelectionRow({
    super.key,
    required this.tagId,
    required this.label,
    required this.color,
    required this.checked,
    this.onToggle,
    required this.onColorChanged,
    this.first = false,
    this.last = false,
  });

  List<AdaptiveMenuItem> _buildColorMenuItems(BuildContext context) {
    return TagColors.palette.map((paletteColor) {
      final colorHex = TagColors.toHex(paletteColor);
      final isSelected = colorHex.toUpperCase() == color.toUpperCase();
      
      return AdaptiveMenuItem(
        title: TagColors.getColorName(paletteColor),
        icon: Icon(
          isSelected ? Icons.check_circle : Icons.circle,
          color: paletteColor,
        ),
        onTap: () => onColorChanged(colorHex),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final tagColor = TagColors.fromHex(color);

    // Get grouped styling
    final borderRadius = GroupedListStyling.getBorderRadius(
      isGrouped: true,
      isFirstInGroup: first,
      isLastInGroup: last,
    );
    final border = GroupedListStyling.getBorder(
      context: context,
      isGrouped: true,
      isFirstInGroup: first,
      isLastInGroup: last,
      isDragging: false,
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.groupedListBackground,
        border: border,
        borderRadius: borderRadius,
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AppRadioButton(
                selected: checked,
                onTap: onToggle,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              // Color indicator with overflow menu for color selection
              AdaptivePullDownButton(
                items: _buildColorMenuItems(context),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: tagColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.border,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}