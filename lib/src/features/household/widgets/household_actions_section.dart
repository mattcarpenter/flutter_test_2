import 'package:flutter/cupertino.dart';
import '../models/household_member.dart';
import 'leave_household_modal.dart';

class HouseholdActionsSection extends StatelessWidget {
  final String currentUserId;
  final List<HouseholdMember> members;
  final bool isLeavingHousehold;
  final Function(String? newOwnerId) onLeaveHousehold;

  const HouseholdActionsSection({
    super.key,
    required this.currentUserId,
    required this.members,
    required this.isLeavingHousehold,
    required this.onLeaveHousehold,
  });

  @override
  Widget build(BuildContext context) {
    final currentMember = members.cast<HouseholdMember?>().firstWhere(
      (m) => m?.userId == currentUserId,
      orElse: () => null,
    );

    if (currentMember == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: CupertinoColors.destructiveRed,
            onPressed: isLeavingHousehold ? null : () => _showLeaveHouseholdModal(context, currentMember),
            child: isLeavingHousehold
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Text('Leave Household'),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Leaving will remove your access to shared recipes and data.',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showLeaveHouseholdModal(BuildContext context, HouseholdMember currentMember) {
    if (currentMember.isOwner) {
      // Show ownership transfer modal
      final otherMembers = members.where((m) => m.userId != currentUserId).toList();
      
      if (otherMembers.isEmpty) {
        // Can't leave if no other members
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Cannot Leave'),
            content: const Text('You cannot leave the household as the owner unless there are other members to transfer ownership to.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
        return;
      }

      showCupertinoModalPopup<void>(
        context: context,
        builder: (context) => LeaveHouseholdModal(
          isOwner: true,
          otherMembers: otherMembers,
          onLeaveHousehold: onLeaveHousehold,
        ),
      );
    } else {
      // Regular member leave confirmation
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Leave Household'),
          content: const Text('Are you sure you want to leave this household? You will lose access to all shared recipes and data.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                onLeaveHousehold(null);
              },
              child: const Text('Leave'),
            ),
          ],
        ),
      );
    }
  }
}