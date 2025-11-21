import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
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
    return AnimatedOpacity(
      opacity: invite.isAccepting || invite.isRevoking ? 0.7 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.of(context).groupedListBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.of(context).groupedListBorder,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon, name, status badge
            Row(
              children: [
                Icon(
                  invite.inviteType == HouseholdInviteType.email
                      ? CupertinoIcons.mail
                      : CupertinoIcons.qrcode,
                  color: AppColors.of(context).primary,
                  size: 20,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    invite.displayName,
                    style: AppTypography.label.copyWith(
                      color: AppColors.of(context).textPrimary,
                    ),
                  ),
                ),
                _buildStatusBadge(context),
              ],
            ),
            // Email (if present)
            if (invite.email != null) ...[
              SizedBox(height: AppSpacing.xs),
              Text(
                invite.email!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.of(context).textSecondary,
                ),
              ),
            ],
            SizedBox(height: AppSpacing.sm),
            // Info row: code (if code invite) + expiry
            _buildInfoRow(context),
            // Action buttons
            if (showActions) ...[
              SizedBox(height: AppSpacing.sm),
              _buildActionButtons(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context) {
    final hasCode = invite.inviteType == HouseholdInviteType.code;

    return Row(
      children: [
        if (hasCode) ...[
          _buildCodeChip(context),
          SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () => _copyToClipboard(context),
            child: Icon(
              CupertinoIcons.doc_on_clipboard,
              size: 16,
              color: AppColors.of(context).textTertiary,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Text(
            '•',
            style: AppTypography.caption.copyWith(
              color: AppColors.of(context).textTertiary,
            ),
          ),
          SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Text(
            'Expires: ${_formatDate(invite.expiresAt)}',
            style: AppTypography.caption.copyWith(
              color: AppColors.of(context).textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        invite.inviteCode,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.of(context).textPrimary,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;

    if (invite.isAccepting) {
      backgroundColor = AppColorSwatches.warning[100]!;
      textColor = AppColorSwatches.warning[700]!;
      text = 'Accepting...';
    } else if (invite.isRevoking) {
      backgroundColor = AppColorSwatches.error[100]!;
      textColor = AppColorSwatches.error[700]!;
      text = 'Revoking...';
    } else {
      switch (invite.status) {
        case HouseholdInviteStatus.pending:
          backgroundColor = AppColorSwatches.info[50]!;
          textColor = AppColorSwatches.info[800]!;
          text = 'Pending';
          break;
        case HouseholdInviteStatus.accepted:
          backgroundColor = AppColorSwatches.success[100]!;
          textColor = AppColorSwatches.success[700]!;
          text = 'Accepted';
          break;
        case HouseholdInviteStatus.declined:
          backgroundColor = AppColorSwatches.error[100]!;
          textColor = AppColorSwatches.error[700]!;
          text = 'Declined';
          break;
        case HouseholdInviteStatus.revoked:
          backgroundColor = AppColorSwatches.neutral[200]!;
          textColor = AppColorSwatches.neutral[600]!;
          text = 'Revoked';
          break;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isDisabled = invite.isAccepting || invite.isRevoking;

    return Row(
      children: [
        if (onAccept != null)
          Expanded(
            child: AppButtonVariants.primaryFilled(
              text: invite.isAccepting ? 'Accepting...' : 'Accept',
              size: AppButtonSize.small,
              shape: AppButtonShape.square,
              loading: invite.isAccepting,
              onPressed: isDisabled ? null : onAccept,
            ),
          ),
        if (onAccept != null && onDecline != null) SizedBox(width: AppSpacing.sm),
        if (onDecline != null)
          Expanded(
            child: AppButtonVariants.mutedOutline(
              text: 'Decline',
              size: AppButtonSize.small,
              shape: AppButtonShape.square,
              onPressed: isDisabled ? null : onDecline,
            ),
          ),
        if (onResend != null)
          CupertinoButton(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            onPressed: isDisabled ? null : onResend,
            child: Text(
              'Resend',
              style: AppTypography.caption.copyWith(
                color: isDisabled
                    ? AppColors.of(context).textDisabled
                    : AppColors.of(context).primary,
              ),
            ),
          ),
        if (onRevoke != null)
          CupertinoButton(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            onPressed: invite.isRevoking ? null : onRevoke,
            child: invite.isRevoking
                ? CupertinoActivityIndicator(color: AppColors.of(context).error)
                : Text(
                    'Revoke',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.of(context).error,
                    ),
                  ),
          ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: invite.inviteCode));
    // Could show a toast here
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
