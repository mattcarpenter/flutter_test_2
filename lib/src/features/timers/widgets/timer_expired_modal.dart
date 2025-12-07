import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../database/database.dart';
import '../../../../database/models/timers.dart';
import '../../../providers/timer_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';

/// Shows a modal when a timer expires, offering options to extend or dismiss.
///
/// Parameters:
/// - [context]: The build context
/// - [timer]: The expired timer entry
Future<void> showTimerExpiredModal(
  BuildContext context, {
  required TimerEntry timer,
}) {
  return WoltModalSheet.show<void>(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      _TimerExpiredModalPage.build(
        context: bottomSheetContext,
        timer: timer,
      ),
    ],
  );
}

class _TimerExpiredModalPage {
  _TimerExpiredModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required TimerEntry timer,
  }) {
    return WoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: false,
      isTopBarLayerAlwaysVisible: false,
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          size: 32,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: _TimerExpiredContent(timer: timer),
      ),
    );
  }
}

class _TimerExpiredContent extends ConsumerWidget {
  final TimerEntry timer;

  const _TimerExpiredContent({required this.timer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final timerNotifier = ref.read(timerNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timer icon
        Icon(
          Icons.timer_off,
          size: 48,
          color: colors.primary,
        ),
        SizedBox(height: AppSpacing.md),

        // Title
        Text(
          'Timer Done!',
          style: AppTypography.h3.copyWith(
            color: colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.sm),

        // Timer details
        Text(
          timer.detectedText,
          style: AppTypography.h4.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          '${timer.recipeName}\nStep ${timer.stepDisplay}',
          style: AppTypography.body.copyWith(
            color: colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xl),

        // Extend buttons row
        Row(
          children: [
            Expanded(
              child: AppButtonVariants.primaryOutline(
                text: 'Extend 1 min',
                size: AppButtonSize.large,
                shape: AppButtonShape.square,
                fullWidth: true,
                onPressed: () async {
                  await timerNotifier.extendTimer(
                    timer.id,
                    const Duration(minutes: 1),
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButtonVariants.primaryOutline(
                text: 'Extend 5 min',
                size: AppButtonSize.large,
                shape: AppButtonShape.square,
                fullWidth: true,
                onPressed: () async {
                  await timerNotifier.extendTimer(
                    timer.id,
                    const Duration(minutes: 5),
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),

        // OK button
        AppButtonVariants.primaryFilled(
          text: 'OK',
          size: AppButtonSize.large,
          shape: AppButtonShape.square,
          fullWidth: true,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
