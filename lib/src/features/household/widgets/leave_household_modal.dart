import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../models/household_member.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_radio_button.dart';
import '../../../widgets/utils/grouped_list_styling.dart';
import '../../../widgets/error_dialog.dart';
import '../../../widgets/success_dialog.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
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
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Cancel'),
      ),
      pageTitle: const ModalSheetTitle('Transfer Ownership'),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
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
        Text(
          'As the owner, you must transfer ownership to another member before leaving.',
          style: AppTypography.body.copyWith(
            color: AppColors.of(context).textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        Text(
          'Select new owner',
          style: AppTypography.h5.copyWith(
            color: AppColors.of(context).textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        // Grouped list of members to select from
        ...widget.otherMembers.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          final isFirst = index == 0;
          final isLast = index == widget.otherMembers.length - 1;
          final isSelected = _selectedNewOwner?.userId == member.userId;

          return _buildMemberTile(
            context,
            member: member,
            isSelected: isSelected,
            isFirst: isFirst,
            isLast: isLast,
            onTap: _isLeaving ? null : () {
              setState(() {
                _selectedNewOwner = member;
              });
            },
          );
        }),
        SizedBox(height: AppSpacing.xl),
        AppButtonVariants.primaryFilled(
          text: _isLeaving ? 'Transferring...' : 'Transfer & Leave',
          size: AppButtonSize.large,
          shape: AppButtonShape.square,
          fullWidth: true,
          loading: _isLeaving,
          onPressed: _isLeaving || _selectedNewOwner == null ? null : _leaveHousehold,
        ),
      ],
    );
  }

  Widget _buildMemberTile(
    BuildContext context, {
    required HouseholdMember member,
    required bool isSelected,
    required bool isFirst,
    required bool isLast,
    VoidCallback? onTap,
  }) {
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

    // Display name: prefer userName, then userEmail, finally fallback to truncated userId
    final displayName = member.userName ?? member.userEmail ?? member.userId;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
              AppRadioButton(
                selected: isSelected,
                onTap: onTap,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  displayName,
                  style: AppTypography.body.copyWith(
                    color: AppColors.of(context).textPrimary,
                    fontWeight: FontWeight.w500,
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
