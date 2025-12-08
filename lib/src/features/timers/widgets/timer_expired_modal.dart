import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../database/database.dart';
import '../../../../database/models/timers.dart';
import '../../../providers/timer_provider.dart';
import '../../../services/alarm_audio_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';

/// Shows a modal when timer(s) expire, offering options to extend or dismiss.
///
/// The modal watches the timer provider directly and automatically updates
/// when new timers expire while the modal is open.
///
/// Plays an alarm sound on loop while the modal is displayed.
/// The sound stops when the modal is dismissed by any means.
Future<void> showTimerExpiredModal(BuildContext context) {
  // Start alarm audio (fire and forget - don't block modal display)
  AlarmAudioService.instance.playLooping();

  // Show modal and stop audio when it closes (for any reason)
  return WoltModalSheet.show<void>(
    useRootNavigator: true,
    context: context,
    modalTypeBuilder: (_) => WoltModalType.alertDialog(),
    pageListBuilder: (modalContext) => [
      _buildPage(context: modalContext),
    ],
  ).then((_) {
    AlarmAudioService.instance.stop();
  });
}

WoltModalSheetPage _buildPage({required BuildContext context}) {
  return WoltModalSheetPage(
    navBarHeight: 0,
    backgroundColor: AppColors.of(context).background,
    surfaceTintColor: Colors.transparent,
    hasTopBarLayer: false,
    isTopBarLayerAlwaysVisible: false,
    child: const _TimerExpiredContent(),
  );
}

/// Content widget that watches timer provider directly.
/// Automatically updates when new timers expire.
class _TimerExpiredContent extends ConsumerStatefulWidget {
  const _TimerExpiredContent();

  @override
  ConsumerState<_TimerExpiredContent> createState() =>
      _TimerExpiredContentState();
}

class _TimerExpiredContentState extends ConsumerState<_TimerExpiredContent> {
  /// Track timer IDs that user has explicitly dismissed.
  /// Used for immediate UI feedback while deletion happens async.
  final Set<String> _dismissedIds = {};

  /// Track IDs of timers currently shown, for deletion on dismiss all.
  List<String> _currentExpiredIds = [];

  /// Prevent double-pop when dismissing triggers provider update
  bool _isClosing = false;

  void _dismissTimer(String timerId) {
    // Update UI immediately
    setState(() {
      _dismissedIds.add(timerId);
    });
    // Delete from database
    ref.read(timerNotifierProvider.notifier).cancelTimer(timerId);
  }

  void _dismissModal() {
    if (_isClosing) return;
    _isClosing = true;

    // Delete all currently shown expired timers
    final timerNotifier = ref.read(timerNotifierProvider.notifier);
    for (final id in _currentExpiredIds) {
      if (!_dismissedIds.contains(id)) {
        timerNotifier.cancelTimer(id);
      }
    }
    AlarmAudioService.instance.stop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final timerNotifier = ref.read(timerNotifierProvider.notifier);

    // Watch all timers and filter for expired ones not dismissed by user
    final allTimers = ref.watch(timerNotifierProvider).valueOrNull ?? [];
    final expiredTimers = allTimers
        .where((t) => t.isExpired && !_dismissedIds.contains(t.id))
        .toList();

    // Track current expired IDs for dismiss all
    _currentExpiredIds = expiredTimers.map((t) => t.id).toList();

    // If no expired timers to show, close the modal
    if (expiredTimers.isEmpty) {
      // Use post-frame callback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _dismissModal();
        }
      });
      // Return empty container while closing
      return const SizedBox.shrink();
    }

    final isSingle = expiredTimers.length == 1;

    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            isSingle ? 'Timer Complete' : '${expiredTimers.length} Timers Complete',
            style: AppTypography.h4.copyWith(
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.lg),

          // Timer cards
          ...expiredTimers.map((timer) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: _TimerCard(
                  timer: timer,
                  showDismissButton: !isSingle,
                  onExtend: (duration) async {
                    // Extending makes timer active again, it will disappear from list
                    await timerNotifier.extendTimer(timer.id, duration);
                  },
                  onDismiss: () => _dismissTimer(timer.id),
                ),
              )),

          SizedBox(height: AppSpacing.sm),

          // Bottom action
          AppButtonVariants.primaryFilled(
            text: isSingle ? 'Dismiss' : 'Dismiss All',
            size: AppButtonSize.large,
            shape: AppButtonShape.square,
            fullWidth: true,
            onPressed: _dismissModal,
          ),
        ],
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  final TimerEntry timer;
  final bool showDismissButton;
  final Future<void> Function(Duration duration) onExtend;
  final VoidCallback onDismiss;

  const _TimerCard({
    required this.timer,
    required this.showDismissButton,
    required this.onExtend,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipe name
          Text(
            timer.recipeName,
            style: AppTypography.bodyLarge.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.xs),

          // Step and duration
          Text(
            'Step ${timer.stepDisplay} · ${timer.detectedText}',
            style: AppTypography.body.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // Action buttons
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ExtendButton(
                label: '+1 min',
                onPressed: () => onExtend(const Duration(minutes: 1)),
              ),
              _ExtendButton(
                label: '+5 min',
                onPressed: () => onExtend(const Duration(minutes: 5)),
              ),
              if (showDismissButton)
                CupertinoButton(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  minimumSize: Size.zero,
                  onPressed: onDismiss,
                  child: Text(
                    'Dismiss',
                    style: AppTypography.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExtendButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ExtendButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTypography.body.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
