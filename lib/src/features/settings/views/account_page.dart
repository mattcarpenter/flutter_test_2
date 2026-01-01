import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:go_router/go_router.dart';

import '../../../../database/powersync.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../repositories/upload_queue_repository.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../widgets/settings_group_condensed.dart';
import '../widgets/settings_row_condensed.dart';

/// Account settings page with user info and sign out
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final isEffectivelyAuthenticated = ref.watch(isAuthenticatedProvider); // Returns false for anonymous
    final isAnonymous = ref.watch(isAnonymousUserProvider);
    final hasPlus = ref.watch(effectiveHasPlusProvider);
    final user = ref.watch(currentUserProvider);

    return AdaptiveSliverPage(
      title: 'Account',
      automaticallyImplyLeading: true,
      previousPageTitle: 'Settings',
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xl),

              if (isEffectivelyAuthenticated && user != null) ...[
                // Fully authenticated user - show email and sign out
                SettingsGroupCondensed(
                  children: [
                    _UserInfoRow(
                      email: user.email ?? 'No email',
                    ),
                  ],
                ),

                SizedBox(height: AppSpacing.settingsGroupGap),

                // Sign out section
                SettingsGroupCondensed(
                  children: [
                    _SignOutRow(
                      onSignOut: () => _handleSignOut(context, ref),
                    ),
                  ],
                ),
              ] else ...[
                // Not fully authenticated (anonymous or logged out)

                // Show notice if anonymous user with subscription
                if (isAnonymous && hasPlus) ...[
                  _AnonymousUserNotice(),
                  SizedBox(height: AppSpacing.lg),
                ],

                // Sign in/sign up options
                SettingsGroupCondensed(
                  children: [
                    SettingsRowCondensed(
                      title: 'Sign In',
                      leading: HugeIcon(
                        icon: HugeIcons.strokeRoundedUserCircle,
                        size: 22,
                        color: colors.primary,
                      ),
                      onTap: () {
                        context.push('/auth');
                      },
                    ),
                  ],
                ),
              ],

              SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }

  /// Handle sign out with sync status checking
  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    try {
      final hasPendingSync = await _hasPendingSync(ref);

      if (hasPendingSync) {
        if (!context.mounted) return;
        final shouldSignOut = await _showSyncWarningDialog(context);
        if (!shouldSignOut) return; // User cancelled
      }

      // Proceed with sign out
      await ref.read(authNotifierProvider.notifier).signOut();
      // No navigation needed - the UI will update based on auth state change
    } catch (e) {
      // Show error dialog if sign out fails
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Sign Out Error'),
            content: Text('Failed to sign out: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Check if there's pending sync activity
  Future<bool> _hasPendingSync(WidgetRef ref) async {
    try {
      // Check PowerSync sync status
      final syncStatus = db.currentStatus;

      // Check if actively syncing
      if (syncStatus.uploading == true || syncStatus.downloading == true) {
        return true;
      }

      // If not connected and hasn't completed initial sync
      if (syncStatus.connected != true && syncStatus.hasSynced != true) {
        return true;
      }

      // Check custom upload queue for images
      final uploadRepo = ref.read(uploadQueueRepositoryProvider);
      final pendingUploads = await uploadRepo.getPendingEntries();
      if (pendingUploads.isNotEmpty) {
        return true;
      }

      return false;
    } catch (e) {
      // On error, show warning to be safe
      return true;
    }
  }

  /// Show warning dialog for pending sync
  Future<bool> _showSyncWarningDialog(BuildContext context) async {
    return await showCupertinoDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
              'Some data hasn\'t finished syncing. If you sign out now, '
              'your recent changes may be lost.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Sign Out Anyway'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false; // Return false if dialog is dismissed
  }
}

/// Row showing user email
class _UserInfoRow extends StatelessWidget {
  final String email;

  const _UserInfoRow({required this.email});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedUserCircle,
            size: 22,
            color: colors.primary,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              email,
              style: AppTypography.body.copyWith(
                color: colors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sign out row with destructive styling
class _SignOutRow extends StatefulWidget {
  final VoidCallback onSignOut;

  const _SignOutRow({required this.onSignOut});

  @override
  State<_SignOutRow> createState() => _SignOutRowState();
}

class _SignOutRowState extends State<_SignOutRow> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onSignOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 48,
        color: _isPressed ? colors.error.withValues(alpha: 0.1) : null,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.square_arrow_left,
              size: 22,
              color: colors.error,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Sign Out',
                style: AppTypography.body.copyWith(
                  color: colors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Notice shown to anonymous users with a subscription
class _AnonymousUserNotice extends StatelessWidget {
  const _AnonymousUserNotice();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: colors.warning,
                size: 20,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Account Not Linked',
                  style: AppTypography.body.copyWith(
                    color: colors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'You have Stockpot Plus but no account. Create an account to '
            'access your subscription on other devices and enable features '
            'like household sharing.',
            style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
