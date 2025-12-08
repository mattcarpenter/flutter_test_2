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
/// Plays an alarm sound on loop while the modal is displayed.
/// The sound stops when the modal is dismissed by any means.
Future<void> showTimerExpiredModal(
  BuildContext context, {
  required List<TimerEntry> timers,
}) {
  // Start alarm audio (fire and forget - don't block modal display)
  AlarmAudioService.instance.playLooping();

  // Show modal and stop audio when it closes (for any reason)
  return WoltModalSheet.show<void>(
    useRootNavigator: true,
    context: context,
    modalTypeBuilder: (_) => WoltModalType.alertDialog(),
    pageListBuilder: (modalContext) => [
      _buildPage(context: modalContext, timers: timers),
    ],
  ).then((_) {
    AlarmAudioService.instance.stop();
  });
}

WoltModalSheetPage _buildPage({
  required BuildContext context,
  required List<TimerEntry> timers,
}) {
  return WoltModalSheetPage(
    navBarHeight: 0,
    backgroundColor: AppColors.of(context).background,
    surfaceTintColor: Colors.transparent,
    hasTopBarLayer: false,
    isTopBarLayerAlwaysVisible: false,
    child: _TimerExpiredContent(timers: timers),
  );
}

class _TimerExpiredContent extends ConsumerStatefulWidget {
  final List<TimerEntry> timers;

  const _TimerExpiredContent({required this.timers});

  @override
  ConsumerState<_TimerExpiredContent> createState() =>
      _TimerExpiredContentState();
}

class _TimerExpiredContentState extends ConsumerState<_TimerExpiredContent> {
  late List<TimerEntry> _timers;

  @override
  void initState() {
    super.initState();
    _timers = List.from(widget.timers);
  }

  void _removeTimer(String timerId) {
    setState(() {
      _timers.removeWhere((t) => t.id == timerId);
    });
    // If no timers left, close the modal
    if (_timers.isEmpty && mounted) {
      _dismissModal();
    }
  }

  void _dismissModal() {
    AlarmAudioService.instance.stop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final timerNotifier = ref.read(timerNotifierProvider.notifier);
    final isSingle = _timers.length == 1;

    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            isSingle ? 'Timer Complete' : '${_timers.length} Timers Complete',
            style: AppTypography.h4.copyWith(
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.lg),

          // Timer cards
          ..._timers.map((timer) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: _TimerCard(
                  timer: timer,
                  showDismissButton: !isSingle,
                  onExtend: (duration) async {
                    await timerNotifier.extendTimer(timer.id, duration);
                    _removeTimer(timer.id);
                  },
                  onDismiss: () => _removeTimer(timer.id),
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
          Row(
            children: [
              _ExtendButton(
                label: '+1 min',
                onPressed: () => onExtend(const Duration(minutes: 1)),
              ),
              SizedBox(width: AppSpacing.sm),
              _ExtendButton(
                label: '+5 min',
                onPressed: () => onExtend(const Duration(minutes: 5)),
              ),
              if (showDismissButton) ...[
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  onPressed: onDismiss,
                  child: Text(
                    'Dismiss',
                    style: AppTypography.body.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
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
