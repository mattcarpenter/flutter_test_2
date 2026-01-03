import 'package:flutter/cupertino.dart';
import 'package:shimmer/shimmer.dart';
import '../../../localization/l10n_extension.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/utils/grouped_list_styling.dart';
import '../models/household_member.dart';

class HouseholdMemberTile extends StatelessWidget {
  final HouseholdMember member;
  final bool canRemove;
  final VoidCallback? onRemove;
  final bool isFirst;
  final bool isLast;

  const HouseholdMemberTile({
    super.key,
    required this.member,
    required this.canRemove,
    this.onRemove,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
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
        color: AppColors.of(context).groupedListBackground,
        borderRadius: borderRadius,
        border: border,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Member name/email
            Expanded(
              child: _buildMemberName(context),
            ),
            // Owner chip (only for owners)
            if (member.isOwner) ...[
              SizedBox(width: AppSpacing.sm),
              _buildOwnerChip(context),
            ],
            // Remove button
            if (canRemove && onRemove != null) ...[
              SizedBox(width: AppSpacing.sm),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 32,
                onPressed: () => _showRemoveConfirmation(context),
                child: Icon(
                  CupertinoIcons.minus_circle,
                  color: AppColors.of(context).error,
                  size: 20,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMemberName(BuildContext context) {
    final displayName = member.userName ?? member.userEmail;
    final textStyle = AppTypography.body.copyWith(
      color: AppColors.of(context).textPrimary,
      fontWeight: FontWeight.w500,
    );

    // Calculate the actual line height to prevent layout shift
    final fontSize = textStyle.fontSize ?? 15;
    final lineHeight = textStyle.height ?? 1.5;
    final actualHeight = fontSize * lineHeight;

    // Show shimmer while loading (when we only have the userId)
    if (displayName == null) {
      final colors = AppColors.of(context);
      final isDark = colors.brightness == Brightness.dark;
      return SizedBox(
        height: actualHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Shimmer.fromColors(
            baseColor: isDark ? colors.surfaceElevated : CupertinoColors.systemGrey5,
            highlightColor: isDark ? colors.surfaceElevatedBorder : CupertinoColors.systemGrey6,
            child: Container(
              height: fontSize, // Shimmer bar slightly shorter than line height
              width: 140,
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      );
    }

    return Text(
      displayName,
      style: textStyle,
    );
  }

  Widget _buildOwnerChip(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: colors.warningBackground,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        context.l10n.householdOwnerBadge,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: colors.warning,
          height: 1.0,
        ),
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context) {
    final l10n = context.l10n;
    final displayName = member.userName ?? member.userEmail ?? l10n.householdThisMember;
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.householdRemoveMemberTitle),
        content: Text(l10n.householdRemoveMemberConfirmation(displayName)),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.commonCancel),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onRemove?.call();
            },
            child: Text(l10n.householdRemoveButton),
          ),
        ],
      ),
    );
  }
}
