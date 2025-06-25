import 'package:flutter/cupertino.dart';
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
          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...invites.map((invite) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
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