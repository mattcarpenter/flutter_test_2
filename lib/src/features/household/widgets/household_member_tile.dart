import 'package:flutter/cupertino.dart';
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
              child: Text(
                member.userName ?? member.userEmail ?? member.userId,
                style: AppTypography.body.copyWith(
                  color: AppColors.of(context).textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
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

  Widget _buildOwnerChip(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: colors.warningBackground,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        'Owner',
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
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member.userName ?? member.userEmail ?? member.userId} from the household?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              onRemove?.call();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
