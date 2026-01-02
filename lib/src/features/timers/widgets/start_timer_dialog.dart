import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../localization/l10n_extension.dart';
import '../../../providers/timer_provider.dart';
import '../../../services/logging/app_logger.dart';

/// Shows a dialog asking the user to confirm starting a timer.
///
/// Parameters:
/// - [context]: The build context
/// - [recipeId]: ID of the recipe
/// - [recipeName]: Display name of the recipe
/// - [stepId]: ID of the step containing the duration
/// - [stepNumber]: 1-indexed step number
/// - [totalSteps]: Total number of steps in the recipe
/// - [duration]: The duration for the timer
/// - [detectedText]: The original text that was detected (e.g., "25 minutes")
Future<void> showStartTimerDialog(
  BuildContext context, {
  required String recipeId,
  required String recipeName,
  required String stepId,
  required int stepNumber,
  required int totalSteps,
  required Duration duration,
  required String detectedText,
}) async {
  final container = ProviderScope.containerOf(context);

  await showCupertinoDialog<void>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(context.l10n.timerStartTitle),
      content: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          context.l10n.timerStartMessage(
            detectedText,
            recipeName,
            stepNumber,
            totalSteps,
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          child: Text(context.l10n.commonCancel),
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          child: Text(context.l10n.timerStart),
          onPressed: () async {
            Navigator.of(dialogContext).pop();

            // Check/request notification permission
            await _ensureNotificationPermission(context, container);

            // Start the timer
            try {
              await container.read(timerNotifierProvider.notifier).startTimer(
                    recipeId: recipeId,
                    recipeName: recipeName,
                    stepId: stepId,
                    stepNumber: stepNumber,
                    totalSteps: totalSteps,
                    detectedText: detectedText,
                    duration: duration,
                  );

              AppLogger.info(
                'Timer started: $detectedText for "$recipeName" step $stepNumber',
              );
            } catch (e, stack) {
              AppLogger.error('Failed to start timer', e, stack);
              // Timer start failed - show error if context is still mounted
              if (context.mounted) {
                _showErrorDialog(context);
              }
            }
          },
        ),
      ],
    ),
  );
}

/// Ensures notification permissions are granted before starting a timer.
/// Shows a pre-permission dialog if permissions aren't yet granted.
Future<void> _ensureNotificationPermission(
  BuildContext context,
  ProviderContainer container,
) async {
  final notificationService = container.read(notificationServiceProvider);

  try {
    // Initialize if needed
    await notificationService.initialize();

    // Check if already enabled
    final enabled = await notificationService.areNotificationsEnabled();
    if (enabled) return;

    // Show pre-permission explanation dialog
    if (!context.mounted) return;

    final shouldRequest = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(context.l10n.timerNotificationsTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(context.l10n.timerNotificationsMessage),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(context.l10n.timerNotificationsNotNow),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(context.l10n.timerNotificationsEnable),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (shouldRequest == true) {
      final granted = await notificationService.requestPermissions();
      AppLogger.info('Notification permission request result: $granted');
    }
  } catch (e, stack) {
    AppLogger.error('Error handling notification permissions', e, stack);
    // Continue without notifications - timer will still work in-app
  }
}

/// Shows an error dialog for timer start failures.
void _showErrorDialog(BuildContext context) {
  showCupertinoDialog<void>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(context.l10n.commonError),
      content: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(context.l10n.timerStartFailed),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          child: Text(context.l10n.commonOk),
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    ),
  );
}
