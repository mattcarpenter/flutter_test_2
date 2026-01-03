import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/services.dart';
import '../../../localization/l10n_extension.dart';
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
                HugeIcon(
                  icon: invite.inviteType == HouseholdInviteType.email
                      ? HugeIcons.strokeRoundedMail01
                      : HugeIcons.strokeRoundedQrCode,
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

    final expiryText = Text(
      context.l10n.householdExpiresIn(_formatDate(context, invite.expiresAt)),
      style: AppTypography.caption.copyWith(
        color: AppColors.of(context).textTertiary,
      ),
    );

    if (hasCode) {
      // For code invites, stack vertically to avoid squishing
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(child: _buildCodeChip(context)),
              SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () => _copyToClipboard(context),
                child: Icon(
                  CupertinoIcons.doc_on_clipboard,
                  size: 16,
                  color: AppColors.of(context).textTertiary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          expiryText,
        ],
      );
    }

    return expiryText;
  }

  Widget _buildCodeChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceVariant,
        borderRadius: BorderRadius.circular(6),
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
    final colors = AppColors.of(context);
    final l10n = context.l10n;
    Color backgroundColor;
    Color textColor;
    String text;

    if (invite.isAccepting) {
      backgroundColor = colors.warningBackground;
      textColor = colors.warning;
      text = l10n.householdStatusAccepting;
    } else if (invite.isRevoking) {
      backgroundColor = colors.errorBackground;
      textColor = colors.error;
      text = l10n.householdStatusRevoking;
    } else {
      switch (invite.status) {
        case HouseholdInviteStatus.pending:
          backgroundColor = colors.infoBackground;
          textColor = colors.info;
          text = l10n.householdStatusPending;
          break;
        case HouseholdInviteStatus.accepted:
          backgroundColor = colors.successBackground;
          textColor = colors.success;
          text = l10n.householdStatusAccepted;
          break;
        case HouseholdInviteStatus.declined:
          backgroundColor = colors.errorBackground;
          textColor = colors.error;
          text = l10n.householdStatusDeclined;
          break;
        case HouseholdInviteStatus.revoked:
          backgroundColor = colors.surfaceVariant;
          textColor = colors.textTertiary;
          text = l10n.householdStatusRevoked;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isDisabled = invite.isAccepting || invite.isRevoking;
    final l10n = context.l10n;

    return Row(
      children: [
        if (onAccept != null)
          Expanded(
            child: AppButtonVariants.primaryFilled(
              text: invite.isAccepting ? l10n.householdAcceptingButton : l10n.householdAcceptButton,
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
              text: l10n.householdDeclineButton,
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
              l10n.householdResendButton,
              style: AppTypography.caption.copyWith(
                color: isDisabled
                    ? AppColors.of(context).textDisabled
                    : AppColors.of(context).primary,
              ),
            ),
          ),
        if (onRevoke != null)
          CupertinoButton(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            onPressed: invite.isRevoking ? null : onRevoke,
            child: invite.isRevoking
                ? CupertinoActivityIndicator(color: AppColors.of(context).error)
                : Text(
                    l10n.householdRevokeButton,
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

  String _formatDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    final l10n = context.l10n;

    if (difference.inDays > 1) {
      return l10n.householdExpiresDays(difference.inDays);
    } else if (difference.inHours > 1) {
      return l10n.householdExpiresHours(difference.inHours);
    } else if (difference.inMinutes > 1) {
      return l10n.householdExpiresMinutes(difference.inMinutes);
    } else {
      return l10n.householdExpiresSoon;
    }
  }
}
