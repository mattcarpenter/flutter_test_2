import 'package:flutter/cupertino.dart';
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
          'Members (${members.length})',
          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...members.map((member) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: HouseholdMemberTile(
            member: member,
            isCurrentUser: member.userId == currentUserId,
            canRemove: canManageMembers && 
                      member.userId != currentUserId && 
                      !member.isOwner,
            onRemove: () => onRemoveMember(member.id),
          ),
        )),
      ],
    );
  }
}