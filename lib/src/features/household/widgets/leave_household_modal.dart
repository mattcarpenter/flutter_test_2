import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../models/household_member.dart';
import '../../../theme/colors.dart';
import '../../../widgets/error_dialog.dart';
import '../../../widgets/success_dialog.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../../../widgets/wolt/button/wolt_elevated_button.dart';
import '../utils/error_messages.dart';

void showLeaveHouseholdModal(
  BuildContext context,
  bool isOwner,
  List<HouseholdMember> otherMembers,
  Function(String? newOwnerId) onLeaveHousehold,
) {
  if (!isOwner) {
    // For non-owners, show a simple confirmation dialog
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Leave Household'),
        content: const Text('Are you sure you want to leave this household?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await onLeaveHousehold(null);
                if (context.mounted) {
                  await SuccessDialog.show(
                    context,
                    message: 'You have successfully left the household.',
                  );
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
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  } else {
    // For owners, show transfer ownership modal
    WoltModalSheet.show(
      useRootNavigator: true,
      context: context,
      pageListBuilder: (bottomSheetContext) => [
        LeaveHouseholdModalPage.build(
          context: bottomSheetContext,
          otherMembers: otherMembers,
          onLeaveHousehold: onLeaveHousehold,
        ),
      ],
    );
  }
}

class LeaveHouseholdModalPage {
  LeaveHouseholdModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required List<HouseholdMember> otherMembers,
    required Function(String? newOwnerId) onLeaveHousehold,
  }) {
    return WoltModalSheetPage(
      backgroundColor: AppColors.of(context).background,
      leadingNavBarWidget: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Cancel'),
      ),
      pageTitle: const ModalSheetTitle('Transfer Ownership'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: LeaveHouseholdForm(
          otherMembers: otherMembers,
          onLeaveHousehold: onLeaveHousehold,
        ),
      ),
    );
  }
}

class LeaveHouseholdForm extends ConsumerStatefulWidget {
  final List<HouseholdMember> otherMembers;
  final Function(String? newOwnerId) onLeaveHousehold;

  const LeaveHouseholdForm({
    super.key,
    required this.otherMembers,
    required this.onLeaveHousehold,
  });

  @override
  ConsumerState<LeaveHouseholdForm> createState() => _LeaveHouseholdFormState();
}

class _LeaveHouseholdFormState extends ConsumerState<LeaveHouseholdForm> {
  HouseholdMember? _selectedNewOwner;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.otherMembers.isNotEmpty) {
      _selectedNewOwner = widget.otherMembers.first;
    }
  }

  void _leaveHousehold() async {
    if (_selectedNewOwner == null) return;

    setState(() {
      _isLeaving = true;
    });

    try {
      await widget.onLeaveHousehold(_selectedNewOwner!.userId);
      if (mounted) {
        Navigator.of(context).pop();
        await SuccessDialog.show(
          context,
          message: 'You have successfully left the household and transferred ownership.',
        );
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          message: HouseholdErrorMessages.getDisplayMessage(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLeaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'As the owner, you must transfer ownership to another member before leaving.',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Select new owner:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: CupertinoColors.separator,
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            height: 120,
            child: CupertinoPicker(
              itemExtent: 44,
              onSelectedItemChanged: _isLeaving ? null : (index) {
                setState(() {
                  _selectedNewOwner = widget.otherMembers[index];
                });
              },
              children: widget.otherMembers.map((member) => Center(
                child: Text(
                  member.userName ?? member.userId,
                  style: const TextStyle(fontSize: 16),
                ),
              )).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: _isLeaving
              ? const CupertinoButton(
                  onPressed: null,
                  child: CupertinoActivityIndicator(color: CupertinoColors.white),
                )
              : WoltElevatedButton(
                  onPressed: _leaveHousehold,
                  child: const Text('Transfer & Leave'),
                ),
        ),
      ],
    );
  }
}