import 'package:flutter/cupertino.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../models/household_invite.dart';
import 'household_invite_tile.dart';

class PendingInvitesSection extends StatelessWidget {
  final List<HouseholdInvite> invites;
  final Function(String inviteCode) onAccept;
  final Function(String inviteCode) onDecline;

  const PendingInvitesSection({
    super.key,
    required this.invites,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    if (invites.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Invitations',
          style: AppTypography.h5.copyWith(
            color: AppColors.of(context).textPrimary,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        ...invites.map((invite) => Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
          child: HouseholdInviteTile(
            invite: invite,
            showActions: true,
            onAccept: () => onAccept(invite.inviteCode),
            onDecline: () => onDecline(invite.inviteCode),
          ),
        )),
      ],
    );
  }
}
