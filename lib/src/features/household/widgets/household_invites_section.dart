import 'package:flutter/cupertino.dart';
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
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: isCreatingInvite ? null : () => _showCreateInviteModal(context),
              child: isCreatingInvite
                  ? const CupertinoActivityIndicator()
                  : const Icon(CupertinoIcons.add_circled_solid),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (invites.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoTheme.of(context).barBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.separator,
                width: 0.5,
              ),
            ),
            child: const Center(
              child: Text(
                'No pending invitations',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...invites.map((invite) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: HouseholdInviteTile(
              invite: invite,
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
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CreateInviteModal(
        onCreateEmailInvite: onCreateEmailInvite,
        onCreateCodeInvite: onCreateCodeInvite,
      ),
    );
  }
}