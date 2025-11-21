import 'package:flutter/cupertino.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_circle_button.dart';
import '../models/household_invite.dart';
import 'household_invite_tile.dart';
import 'create_invite_modal.dart';

class HouseholdInvitesSection extends StatelessWidget {
  final List<HouseholdInvite> invites;
  final bool isCreatingInvite;
  final Future<String?> Function(String email) onCreateEmailInvite;
  final Future<String?> Function(String displayName) onCreateCodeInvite;
  final Function(String inviteId) onResendInvite;
  final Function(String inviteId) onRevokeInvite;

  const HouseholdInvitesSection({
    super.key,
    required this.invites,
    required this.isCreatingInvite,
    required this.onCreateEmailInvite,
    required this.onCreateCodeInvite,
    required this.onResendInvite,
    required this.onRevokeInvite,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Pending Invites (${invites.length})',
                style: AppTypography.h5.copyWith(
                  color: AppColors.of(context).textPrimary,
                ),
              ),
            ),
            if (isCreatingInvite)
              const CupertinoActivityIndicator()
            else
              AppCircleButton(
                icon: AppCircleButtonIcon.plus,
                onPressed: () => _showCreateInviteModal(context),
              ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        if (invites.isEmpty)
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.of(context).groupedListBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.of(context).groupedListBorder,
                width: 0.5,
              ),
            ),
            child: Center(
              child: Text(
                'No pending invitations',
                style: AppTypography.body.copyWith(
                  color: AppColors.of(context).textSecondary,
                ),
              ),
            ),
          )
        else
          ...invites.map((invite) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: HouseholdInviteTile(
              invite: invite,
              showActions: true,
              onResend: invite.inviteType == HouseholdInviteType.email
                  ? () => onResendInvite(invite.id)
                  : null,
              onRevoke: () => onRevokeInvite(invite.id),
            ),
          )),
      ],
    );
  }

  void _showCreateInviteModal(BuildContext context) {
    showCreateInviteModal(
      context,
      onCreateEmailInvite,
      onCreateCodeInvite,
    );
  }
}
