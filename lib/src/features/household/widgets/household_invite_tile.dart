import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../models/household_invite.dart';

class HouseholdInviteTile extends StatelessWidget {
  final HouseholdInvite invite;
  final bool showActions;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onResend;
  final VoidCallback? onRevoke;

  const HouseholdInviteTile({
    super.key,
    required this.invite,
    this.showActions = false,
    this.onAccept,
    this.onDecline,
    this.onResend,
    this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).barBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                invite.inviteType == HouseholdInviteType.email
                    ? CupertinoIcons.mail
                    : CupertinoIcons.qrcode,
                color: CupertinoTheme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  invite.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          if (invite.email != null) ...[
            const SizedBox(height: 4),
            Text(
              invite.email!,
              style: const TextStyle(
                color: CupertinoColors.secondaryLabel,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Expires: ${_formatDate(invite.expiresAt)}',
            style: const TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: 12,
            ),
          ),
          if (invite.inviteType == HouseholdInviteType.code) ...[
            const SizedBox(height: 12),
            _buildCodeSection(context),
          ],
          if (showActions) ...[
            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;
    
    switch (invite.status) {
      case HouseholdInviteStatus.pending:
        color = CupertinoColors.systemBlue;
        text = 'Pending';
        break;
      case HouseholdInviteStatus.accepted:
        color = CupertinoColors.systemGreen;
        text = 'Accepted';
        break;
      case HouseholdInviteStatus.declined:
        color = CupertinoColors.systemRed;
        text = 'Declined';
        break;
      case HouseholdInviteStatus.revoked:
        color = CupertinoColors.systemGrey;
        text = 'Revoked';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCodeSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              invite.inviteCode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 32,
            onPressed: () => _copyToClipboard(context),
            child: const Icon(
              CupertinoIcons.doc_on_clipboard,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (onAccept != null)
          Expanded(
            child: CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(vertical: 8),
              onPressed: onAccept,
              child: const Text('Accept'),
            ),
          ),
        if (onAccept != null && onDecline != null) const SizedBox(width: 8),
        if (onDecline != null)
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 8),
              onPressed: onDecline,
              child: const Text('Decline'),
            ),
          ),
        if (onResend != null)
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            onPressed: onResend,
            child: const Text('Resend'),
          ),
        if (onRevoke != null)
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            onPressed: onRevoke,
            child: const Text('Revoke', style: TextStyle(color: CupertinoColors.destructiveRed)),
          ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: invite.inviteCode));
    // Show a toast or snackbar
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays > 1) {
      return '${difference.inDays} days';
    } else if (difference.inHours > 1) {
      return '${difference.inHours} hours';
    } else if (difference.inMinutes > 1) {
      return '${difference.inMinutes} minutes';
    } else {
      return 'Soon';
    }
  }
}