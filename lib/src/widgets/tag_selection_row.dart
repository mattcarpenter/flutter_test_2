import 'package:flutter/material.dart';

import '../constants/tag_colors.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../widgets/app_checkbox_square.dart';

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

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(
          top: first ? const Radius.circular(8) : Radius.zero,
          bottom: last ? const Radius.circular(8) : Radius.zero,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.vertical(
            top: first ? const Radius.circular(8) : Radius.zero,
            bottom: last ? const Radius.circular(8) : Radius.zero,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                AppCheckboxSquare(
                  checked: checked,
                  onTap: onToggle,
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.body.copyWith(
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
      ),
    );
  }
}