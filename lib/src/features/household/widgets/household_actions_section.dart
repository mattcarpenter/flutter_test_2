import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/household_member.dart';
import '../../../../database/database.dart';
import 'leave_household_modal.dart';
import '../../../providers/household_provider.dart';
import '../../../widgets/error_dialog.dart';
import '../utils/error_messages.dart';

class HouseholdActionsSection extends ConsumerWidget {
  final HouseholdEntry household;
  final String currentUserId;
  final List<HouseholdMember> members;
  final bool isLeavingHousehold;
  final Function(String? newOwnerId) onLeaveHousehold;

  const HouseholdActionsSection({
    super.key,
    required this.household,
    required this.currentUserId,
    required this.members,
    required this.isLeavingHousehold,
    required this.onLeaveHousehold,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onPressed: isLeavingHousehold ? null : () => _showLeaveHouseholdModal(context, currentMember, ref),
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

  void _showLeaveHouseholdModal(BuildContext context, HouseholdMember currentMember, WidgetRef ref) {
    if (currentMember.isOwner) {
      final otherMembers = members.where((m) => m.userId != currentUserId).toList();
      
      if (otherMembers.isEmpty) {
        // Show delete household modal instead of blocking
        _showDeleteHouseholdModal(context, ref);
        return;
      }

      showLeaveHouseholdModal(
        context,
        true,
        otherMembers,
        onLeaveHousehold,
      );
    } else {
      // Regular member - showLeaveHouseholdModal handles non-owner case
      showLeaveHouseholdModal(
        context,
        false,
        [],
        onLeaveHousehold,
      );
    }
  }
  
  void _showDeleteHouseholdModal(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Household'),
        content: const Text(
          'Since you are the only member, this will delete the household. '
          'Your shared data will become personal data. This cannot be undone.'
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete Household'),
            onPressed: () async {
              Navigator.pop(context);
              
              final notifier = ref.read(householdNotifierProvider.notifier);
              
              try {
                // Call delete endpoint (which will deactivate membership)
                await notifier.deleteHousehold(household.id);
                
                // Navigate back to household list
                if (context.mounted) {
                  context.go('/households');
                }
              } catch (e) {
                if (context.mounted) {
                  await ErrorDialog.show(
                    context,
                    message: HouseholdErrorMessages.getDisplayMessage(e.toString()),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}