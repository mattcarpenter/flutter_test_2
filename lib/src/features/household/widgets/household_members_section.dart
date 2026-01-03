import 'package:flutter/cupertino.dart';
import '../../../localization/l10n_extension.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../models/household_member.dart';
import 'household_member_tile.dart';

class HouseholdMembersSection extends StatelessWidget {
  final List<HouseholdMember> members;
  final String currentUserId;
  final bool canManageMembers;
  final Function(String memberId) onRemoveMember;

  const HouseholdMembersSection({
    super.key,
    required this.members,
    required this.currentUserId,
    required this.canManageMembers,
    required this.onRemoveMember,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.householdMembersCount(members.length),
          style: AppTypography.h5.copyWith(
            color: AppColors.of(context).textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        // Grouped list - no gaps between items
        ...members.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          final isFirst = index == 0;
          final isLast = index == members.length - 1;

          return HouseholdMemberTile(
            member: member,
            canRemove: canManageMembers &&
                      member.userId != currentUserId &&
                      !member.isOwner,
            onRemove: () => onRemoveMember(member.id),
            isFirst: isFirst,
            isLast: isLast,
          );
        }),
      ],
    );
  }
}
