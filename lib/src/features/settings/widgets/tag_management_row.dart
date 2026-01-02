import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../constants/tag_colors.dart';
import '../../../../database/database.dart';
import '../../../localization/l10n_extension.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/utils/grouped_list_styling.dart';

/// Widget for managing individual tags in the tag management page
/// Shows tag info, recipe count, and provides color change/delete actions
class TagManagementRow extends StatelessWidget {
  final RecipeTagEntry tag;
  final int recipeCount;
  final Function(String color) onColorChanged;
  final VoidCallback onDelete;
  final bool isFirst;
  final bool isLast;

  const TagManagementRow({
    super.key,
    required this.tag,
    required this.recipeCount,
    required this.onColorChanged,
    required this.onDelete,
    this.isFirst = true,
    this.isLast = true,
  });

  List<AdaptiveMenuItem> _buildColorMenuItems() {
    return TagColors.palette.map((paletteColor) {
      final colorHex = TagColors.toHex(paletteColor);
      final isSelected = colorHex.toUpperCase() == tag.color.toUpperCase();
      
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

  void _confirmDelete(BuildContext context) {
    if (recipeCount > 0) {
      // Show warning for tags with recipes
      showCupertinoDialog(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(context.l10n.settingsTagsDeleteTitle(tag.name)),
          content: Text(
            context.l10n.settingsTagsDeleteMessageWithRecipes(recipeCount),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(context.l10n.commonCancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onDelete();
              },
              child: Text(context.l10n.commonDelete),
            ),
          ],
        ),
      );
    } else {
      // Simple confirmation for unused tags
      showCupertinoDialog(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(context.l10n.settingsTagsDeleteTitle(tag.name)),
          content: Text(context.l10n.settingsTagsDeleteMessageNoRecipes),
          actions: [
            CupertinoDialogAction(
              child: Text(context.l10n.commonCancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onDelete();
              },
              child: Text(context.l10n.commonDelete),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final tagColor = TagColors.fromHex(tag.color);

    // Get grouped list styling
    final borderRadius = GroupedListStyling.getBorderRadius(
      isGrouped: true,
      isFirstInGroup: isFirst,
      isLastInGroup: isLast,
    );
    final border = GroupedListStyling.getBorder(
      context: context,
      isGrouped: true,
      isFirstInGroup: isFirst,
      isLastInGroup: isLast,
      isDragging: false,
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.groupedListBackground,
        borderRadius: borderRadius,
        border: border,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Color indicator with tap to change color
          AdaptivePullDownButton(
            items: _buildColorMenuItems(),
            child: Container(
              width: 32,
              height: 32,
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
          
          SizedBox(width: AppSpacing.md),
          
          // Tag name and recipe count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag.name,
                  style: AppTypography.body.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  context.l10n.settingsTagsRecipeCount(recipeCount),
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: AppSpacing.sm),
          
          // Delete button
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(32, 32),
            onPressed: () => _confirmDelete(context),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedDelete02,
              color: colors.error,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}