import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/household_provider.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../widgets/create_household_modal.dart';
import '../widgets/join_with_code_modal.dart';
import '../widgets/household_info_section.dart';
import '../widgets/household_members_section.dart';
import '../widgets/household_invites_section.dart';
import '../widgets/household_actions_section.dart';
import '../widgets/pending_invites_section.dart';
import '../widgets/household_invite_tile.dart';

class HouseholdSharingPage extends ConsumerWidget {
  final VoidCallback? onMenuPressed;
  
  const HouseholdSharingPage({super.key, this.onMenuPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdState = ref.watch(householdNotifierProvider);
    
    final menuButton = onMenuPressed != null 
        ? GestureDetector(
            onTap: onMenuPressed,
            child: const Icon(CupertinoIcons.bars),
          )
        : null;

    return AdaptiveSliverPage(
      title: 'Household Sharing',
      leading: menuButton,
      automaticallyImplyLeading: onMenuPressed == null,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildContent(context, ref, householdState),
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

  Widget _buildPendingInvitesSection(BuildContext context, WidgetRef ref, householdState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Household Invitations',
          style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
        ),
        const SizedBox(height: 16),
        PendingInvitesSection(
          invites: householdState.incomingInvites,
          onAccept: (inviteCode) => ref.read(householdNotifierProvider.notifier)
              .acceptInvite(inviteCode),
          onDecline: (inviteCode) => ref.read(householdNotifierProvider.notifier)
              .declineInvite(inviteCode),
        ),
      ],
    );
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
        // Household info section
        HouseholdInfoSection(household: householdState.currentHousehold!),
        const SizedBox(height: 24),
        
        // Members section
        HouseholdMembersSection(
          members: householdState.members,
          currentUserId: currentUserId,
          canManageMembers: canManageMembers,
          onRemoveMember: (memberId) => ref.read(householdNotifierProvider.notifier)
              .removeMember(memberId),
        ),
        const SizedBox(height: 24),
        
        // Invites section (owners/admins only)
        if (canManageMembers) ...[
          HouseholdInvitesSection(
            invites: householdState.outgoingInvites,
            isCreatingInvite: householdState.isCreatingInvite,
            onCreateEmailInvite: (email) => ref.read(householdNotifierProvider.notifier)
                .createEmailInvite(email),
            onCreateCodeInvite: (displayName) => ref.read(householdNotifierProvider.notifier)
                .createCodeInvite(displayName),
            onResendInvite: (inviteId) => ref.read(householdNotifierProvider.notifier)
                .resendInvite(inviteId),
            onRevokeInvite: (inviteId) => ref.read(householdNotifierProvider.notifier)
                .revokeInvite(inviteId),
          ),
          const SizedBox(height: 24),
        ],
        
        // Actions section
        HouseholdActionsSection(
          currentUserId: currentUserId,
          members: householdState.members,
          isLeavingHousehold: householdState.isLeavingHousehold,
          onLeaveHousehold: (newOwnerId) => ref.read(householdNotifierProvider.notifier)
              .leaveHousehold(newOwnerId: newOwnerId),
        ),
      ],
    );
  }

  Widget _buildNoHouseholdSection(BuildContext context, WidgetRef ref, householdState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show pending invites first if any
        if (householdState.hasPendingInvites) ...[
          ...householdState.incomingInvites.map((invite) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HouseholdInviteTile(
              invite: invite,
              showActions: true,
              onAccept: () => ref.read(householdNotifierProvider.notifier)
                  .acceptInvite(invite.inviteCode),
              onDecline: () => ref.read(householdNotifierProvider.notifier)
                  .declineInvite(invite.inviteCode),
            ),
          )),
          const SizedBox(height: 24),
          Container(
            height: 0.5,
            color: CupertinoColors.separator,
          ),
          const SizedBox(height: 24),
        ],
        
        // Always show create/join options
        Center(
          child: Column(
            children: [
              const Text(
                'Share recipes and collaborate with your household',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CupertinoButton.filled(
                child: const Text('Create Household'),
                onPressed: () => _showCreateHouseholdModal(context, ref),
              ),
              const SizedBox(height: 16),
              CupertinoButton(
                child: const Text('Join with Code'),
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
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CreateHouseholdModal(
        onCreateHousehold: (name) => ref.read(householdNotifierProvider.notifier)
            .createHousehold(name),
      ),
    );
  }

  void _showJoinWithCodeModal(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => JoinWithCodeModal(
        onAcceptInvite: (inviteCode) => ref.read(householdNotifierProvider.notifier)
            .acceptInvite(inviteCode),
      ),
    );
  }
}