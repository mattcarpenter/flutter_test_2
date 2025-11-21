import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/household_provider.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/error_dialog.dart';
import '../../../widgets/success_dialog.dart';
import '../widgets/create_household_modal.dart';
import '../widgets/join_with_code_modal.dart';
import '../widgets/household_members_section.dart';
import '../widgets/household_invites_section.dart';
import '../widgets/household_invite_tile.dart';
import '../widgets/leave_household_modal.dart';
import '../models/household_member.dart';
import '../utils/error_messages.dart';

class HouseholdSharingPage extends ConsumerWidget {
  final VoidCallback? onMenuPressed;

  const HouseholdSharingPage({super.key, this.onMenuPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check authentication before accessing the provider
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      return _buildUnauthenticatedPage(context);
    }

    final householdState = ref.watch(householdNotifierProvider);

    final menuButton = onMenuPressed != null
        ? GestureDetector(
            onTap: onMenuPressed,
            child: const Icon(CupertinoIcons.bars),
          )
        : null;

    // Build trailing menu only if user has a household
    Widget? trailingMenu;
    if (householdState.hasHousehold) {
      final currentUserId = currentUser.id;
      final List<HouseholdMember> members = householdState.members;
      final currentMember = members.where((m) => m.userId == currentUserId).firstOrNull;

      trailingMenu = AdaptivePullDownButton(
        items: [
          AdaptiveMenuItem(
            title: 'Leave Household',
            icon: Icon(CupertinoIcons.arrow_right_square, color: AppColors.of(context).error),
            isDestructive: true,
            onTap: () => _showLeaveHouseholdDialog(context, ref, householdState, currentMember, members),
          ),
        ],
        child: const AppCircleButton(
          icon: AppCircleButtonIcon.ellipsis,
        ),
      );
    }

    return AdaptiveSliverPage(
      title: 'Household',
      leading: menuButton,
      automaticallyImplyLeading: onMenuPressed == null,
      trailing: trailingMenu,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: _buildContent(context, ref, householdState),
          ),
        ),
      ],
    );
  }

  void _showLeaveHouseholdDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic householdState,
    HouseholdMember? currentMember,
    List<HouseholdMember> members,
  ) {
    if (currentMember == null) return;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    if (currentMember.isOwner) {
      final otherMembers = members.where((m) => m.userId != currentUserId).toList();

      if (otherMembers.isEmpty) {
        // Only member - show delete confirmation
        _showDeleteHouseholdModal(context, ref, householdState.currentHousehold!.id);
        return;
      }

      // Owner with other members - show transfer ownership modal
      showLeaveHouseholdModal(
        context,
        true,
        otherMembers,
        (newOwnerId) => ref.read(householdNotifierProvider.notifier).leaveHousehold(newOwnerId: newOwnerId),
      );
    } else {
      // Regular member - simple leave confirmation
      showLeaveHouseholdModal(
        context,
        false,
        [],
        (newOwnerId) => ref.read(householdNotifierProvider.notifier).leaveHousehold(newOwnerId: newOwnerId),
      );
    }
  }

  void _showDeleteHouseholdModal(BuildContext context, WidgetRef ref, String householdId) {
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

              try {
                await ref.read(householdNotifierProvider.notifier).deleteHousehold(householdId);
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

  Widget _buildUnauthenticatedPage(BuildContext context) {
    final menuButton = onMenuPressed != null
        ? GestureDetector(
            onTap: onMenuPressed,
            child: const Icon(CupertinoIcons.bars),
          )
        : null;

    return AdaptiveSliverPage(
      title: 'Household',
      leading: menuButton,
      automaticallyImplyLeading: onMenuPressed == null,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.person_badge_minus,
                    size: 64,
                    color: AppColors.of(context).textTertiary,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Authentication Required',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.of(context).textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Please sign in to access household sharing features',
                    style: AppTypography.body.copyWith(
                      color: AppColors.of(context).textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, householdState) {
    // Progressive disclosure based on state
    if (householdState.hasHousehold) {
      return _buildHouseholdManagementSection(context, ref, householdState);
    } else {
      // Show both pending invites and create/join options when no household
      return _buildNoHouseholdSection(context, ref, householdState);
    }
  }

  Widget _buildHouseholdManagementSection(BuildContext context, WidgetRef ref, householdState) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      return const Text('Authentication required');
    }
    final canManageMembers = householdState.canManageMembers(currentUserId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Household name header (no icon)
        Text(
          householdState.currentHousehold!.name,
          style: AppTypography.h3.copyWith(
            color: AppColors.of(context).textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.xl),

        // Members section
        HouseholdMembersSection(
          members: householdState.members,
          currentUserId: currentUserId,
          canManageMembers: canManageMembers,
          onRemoveMember: (memberId) async {
            try {
              await ref.read(householdNotifierProvider.notifier).removeMember(memberId);
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
        SizedBox(height: AppSpacing.xl),

        // Invites section (owners only)
        if (canManageMembers) ...[
          HouseholdInvitesSection(
            invites: householdState.outgoingInvites,
            isCreatingInvite: householdState.isCreatingInvite,
            onCreateEmailInvite: (email) => ref.read(householdNotifierProvider.notifier)
                .createEmailInvite(email),
            onCreateCodeInvite: (displayName) => ref.read(householdNotifierProvider.notifier)
                .createCodeInvite(displayName),
            onResendInvite: (inviteId) async {
              try {
                await ref.read(householdNotifierProvider.notifier).resendInvite(inviteId);
                if (context.mounted) {
                  await SuccessDialog.show(
                    context,
                    message: 'Invitation has been resent successfully.',
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
            onRevokeInvite: (inviteId) async {
              try {
                await ref.read(householdNotifierProvider.notifier).revokeInvite(inviteId);
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
      ],
    );
  }

  Widget _buildNoHouseholdSection(BuildContext context, WidgetRef ref, householdState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show pending invites first if any
        if (householdState.hasPendingInvites) ...[
          Text(
            'Pending Invites',
            style: AppTypography.h5.copyWith(
              color: AppColors.of(context).textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          ...householdState.incomingInvites.map((invite) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: HouseholdInviteTile(
              invite: invite,
              showActions: true,
              onAccept: () async {
                try {
                  await ref.read(householdNotifierProvider.notifier)
                      .acceptInvite(invite.inviteCode);
                  if (context.mounted) {
                    await SuccessDialog.show(
                      context,
                      message: 'You have successfully joined the household!',
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
              onDecline: () async {
                try {
                  await ref.read(householdNotifierProvider.notifier)
                      .declineInvite(invite.inviteCode);
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
          )),
          SizedBox(height: AppSpacing.lg),
          Container(
            height: 0.5,
            color: AppColors.of(context).border,
          ),
          SizedBox(height: AppSpacing.xl),
        ],

        // Always show create/join options
        Center(
          child: Column(
            children: [
              Icon(
                CupertinoIcons.house,
                size: 48,
                color: AppColors.of(context).textTertiary,
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                'Share recipes and collaborate with your household',
                style: AppTypography.body.copyWith(
                  color: AppColors.of(context).textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xxl),
              AppButtonVariants.primaryFilled(
                text: 'Create Household',
                size: AppButtonSize.large,
                shape: AppButtonShape.square,
                fullWidth: true,
                onPressed: () => _showCreateHouseholdModal(context, ref),
              ),
              SizedBox(height: AppSpacing.md),
              AppButtonVariants.mutedOutline(
                text: 'Join with Code',
                size: AppButtonSize.large,
                shape: AppButtonShape.square,
                fullWidth: true,
                onPressed: () => _showJoinWithCodeModal(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Modal methods
  void _showCreateHouseholdModal(BuildContext context, WidgetRef ref) {
    showCreateHouseholdModal(
      context,
      (name) => ref.read(householdNotifierProvider.notifier).createHousehold(name),
    );
  }

  void _showJoinWithCodeModal(BuildContext context, WidgetRef ref) {
    showJoinWithCodeModal(
      context,
      (inviteCode) => ref.read(householdNotifierProvider.notifier).acceptInvite(inviteCode),
    );
  }
}
