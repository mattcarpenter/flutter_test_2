import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../database/database.dart';
import '../../database/models/timers.dart';
import '../../database/powersync.dart';
import '../repositories/timer_repository.dart';
import '../services/notification_service.dart';
import '../services/logging/app_logger.dart';

/// [TimerNotifier] manages a list of [TimerEntry] records and handles
/// timer lifecycle operations including creation, extension, and cancellation.
class TimerNotifier extends StateNotifier<AsyncValue<List<TimerEntry>>> {
  final TimerRepository _repository;
  final NotificationService _notificationService;
  late final StreamSubscription<List<TimerEntry>> _subscription;
  Timer? _tickTimer;

  TimerNotifier(this._repository, this._notificationService)
      : super(const AsyncValue.loading()) {
    _init();
  }

  /// Initialize timer notifier by subscribing to active timers stream
  /// and starting the tick timer for UI updates.
  void _init() {
    // Subscribe to active timers from database
    _subscription = _repository.watchActiveTimers().listen(
      (timers) {
        state = AsyncValue.data(timers);
      },
      onError: (error, stack) {
        AppLogger.error('Error watching active timers', error, stack);
        state = AsyncValue.error(error, stack);
      },
    );

    // Start tick timer to update UI every second for countdown display
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Trigger state rebuild by creating a new list reference
      state.whenData((timers) {
        state = AsyncValue.data([...timers]);
      });
    });

    AppLogger.debug('TimerNotifier initialized');
  }

  @override
  void dispose() {
    _subscription.cancel();
    _tickTimer?.cancel();
    AppLogger.debug('TimerNotifier disposed');
    super.dispose();
  }

  /// Start a new timer and schedule its notification.
  ///
  /// Returns the timer ID on success.
  ///
  /// Parameters:
  /// - [recipeId]: ID of the recipe being cooked
  /// - [recipeName]: Display name of the recipe
  /// - [stepId]: ID of the recipe step
  /// - [stepNumber]: 1-indexed step number for display
  /// - [totalSteps]: Total number of steps in the recipe
  /// - [detectedText]: Original time text from the step (e.g., "25 minutes")
  /// - [duration]: How long the timer should run
  Future<String> startTimer({
    required String recipeId,
    required String recipeName,
    required String stepId,
    required int stepNumber,
    required int totalSteps,
    required String detectedText,
    required Duration duration,
  }) async {
    try {
      AppLogger.debug(
        'Starting timer for recipe "$recipeName" step $stepNumber/$totalSteps, '
        'duration: ${duration.inSeconds}s',
      );

      // Schedule notification first to get the notification ID
      String? notificationId;
      try {
        final enabled = await _notificationService.areNotificationsEnabled();
        if (enabled) {
          notificationId = await _notificationService.scheduleTimerNotification(
            recipeName: recipeName,
            stepNumber: stepNumber,
            duration: duration,
          );
          AppLogger.debug(
            'Scheduled notification for timer: id=$notificationId',
          );
        } else {
          AppLogger.warning(
            'Notifications not enabled, timer will run without notification',
          );
        }
      } catch (e, stack) {
        AppLogger.error(
          'Failed to schedule notification for timer, continuing without it',
          e,
          stack,
        );
        // Continue without notification - timer will still work in-app
      }

      // Create timer in database
      final timerId = await _repository.createTimer(
        recipeId: recipeId,
        recipeName: recipeName,
        stepId: stepId,
        stepNumber: stepNumber,
        totalSteps: totalSteps,
        detectedText: detectedText,
        durationSeconds: duration.inSeconds,
        notificationId: notificationId,
      );

      AppLogger.info(
        'Started timer: id=$timerId, recipe="$recipeName", '
        'step=$stepNumber/$totalSteps, duration=${duration.inSeconds}s',
      );

      return timerId;
    } catch (e, stack) {
      AppLogger.error('Failed to start timer', e, stack);
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Extend an active timer by adding additional time.
  ///
  /// The timer's end timestamp will be extended by [extension] duration.
  /// The notification will be cancelled and rescheduled with the new time.
  ///
  /// Parameters:
  /// - [timerId]: ID of the timer to extend
  /// - [extension]: How much time to add to the timer
  Future<void> extendTimer(String timerId, Duration extension) async {
    try {
      AppLogger.debug(
        'Extending timer $timerId by ${extension.inSeconds}s',
      );

      // Get the timer to access its details
      final timer = await _repository.getTimer(timerId);
      if (timer == null) {
        AppLogger.warning('Cannot extend timer $timerId: not found');
        return;
      }

      // Cancel existing notification
      if (timer.notificationId != null) {
        try {
          await _notificationService.cancelNotification(timer.notificationId!);
          AppLogger.debug(
            'Cancelled old notification: id=${timer.notificationId}',
          );
        } catch (e, stack) {
          AppLogger.error(
            'Failed to cancel old notification, continuing',
            e,
            stack,
          );
        }
      }

      // Extend the timer in database
      await _repository.extendTimer(timerId, extension.inSeconds);

      // Schedule new notification with extended time
      String? newNotificationId;
      try {
        final enabled = await _notificationService.areNotificationsEnabled();
        if (enabled) {
          final newRemaining = timer.remaining + extension;
          newNotificationId = await _notificationService.scheduleTimerNotification(
            recipeName: timer.recipeName,
            stepNumber: timer.stepNumber,
            duration: newRemaining,
          );

          // Update timer with new notification ID
          await _repository.updateNotificationId(timerId, newNotificationId);

          AppLogger.debug(
            'Scheduled new notification for extended timer: id=$newNotificationId',
          );
        }
      } catch (e, stack) {
        AppLogger.error(
          'Failed to reschedule notification for extended timer',
          e,
          stack,
        );
        // Continue - timer is extended even without notification
      }

      AppLogger.info(
        'Extended timer $timerId by ${extension.inSeconds}s',
      );
    } catch (e, stack) {
      AppLogger.error('Failed to extend timer', e, stack);
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Cancel an active timer and its notification.
  ///
  /// Removes the timer from the database and cancels its scheduled notification.
  ///
  /// Parameters:
  /// - [timerId]: ID of the timer to cancel
  Future<void> cancelTimer(String timerId) async {
    try {
      AppLogger.debug('Cancelling timer $timerId');

      // Get timer to access notification ID
      final timer = await _repository.getTimer(timerId);
      if (timer == null) {
        AppLogger.warning('Cannot cancel timer $timerId: not found');
        return;
      }

      // Cancel notification if it exists
      if (timer.notificationId != null) {
        try {
          await _notificationService.cancelNotification(timer.notificationId!);
          AppLogger.debug(
            'Cancelled notification: id=${timer.notificationId}',
          );
        } catch (e, stack) {
          AppLogger.error(
            'Failed to cancel notification, continuing with timer cancellation',
            e,
            stack,
          );
        }
      }

      // Delete timer from database
      await _repository.cancelTimer(timerId);

      AppLogger.info('Cancelled timer $timerId');
    } catch (e, stack) {
      AppLogger.error('Failed to cancel timer', e, stack);
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Clean up expired timers (expired more than 1 hour ago).
  ///
  /// This should be called periodically to prevent database bloat.
  Future<void> cleanupExpiredTimers() async {
    try {
      await _repository.cleanupExpiredTimers();
    } catch (e, stack) {
      AppLogger.error('Failed to cleanup expired timers', e, stack);
      // Don't rethrow - cleanup failures shouldn't block the app
    }
  }
}

/// Provider to expose the [TimerRepository].
final timerRepositoryProvider = Provider<TimerRepository>((ref) {
  return TimerRepository(appDb);
});

/// Provider to expose the [NotificationService].
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

/// Provider to expose the [TimerNotifier].
final timerNotifierProvider =
    StateNotifierProvider<TimerNotifier, AsyncValue<List<TimerEntry>>>(
  (ref) {
    final repository = ref.watch(timerRepositoryProvider);
    final notificationService = ref.watch(notificationServiceProvider);
    return TimerNotifier(repository, notificationService);
  },
);

/// Returns all active timers (not expired), ordered by end timestamp.
final activeTimersProvider = Provider<List<TimerEntry>>((ref) {
  final allTimers = ref.watch(timerNotifierProvider).value ?? [];
  // Filter for active timers only (though repository already filters these)
  return allTimers.where((timer) => timer.isActive).toList();
});

/// Returns true if there are any active timers.
final hasActiveTimersProvider = Provider<bool>((ref) {
  final activeTimers = ref.watch(activeTimersProvider);
  return activeTimers.isNotEmpty;
});

/// Returns all active timers for a specific recipe.
///
/// Useful for showing recipe-specific timer status in the UI.
final timersForRecipeProvider = Provider.family<List<TimerEntry>, String>(
  (ref, recipeId) {
    final activeTimers = ref.watch(activeTimersProvider);
    return activeTimers.where((timer) => timer.recipeId == recipeId).toList();
  },
);

/// Returns the next timer to expire (earliest end timestamp).
///
/// Useful for showing a countdown in the global status bar.
final nextTimerProvider = Provider<TimerEntry?>((ref) {
  final activeTimers = ref.watch(activeTimersProvider);
  // Timers are already sorted by end timestamp from repository
  return activeTimers.firstOrNull;
});

/// Returns the count of active timers.
final activeTimerCountProvider = Provider<int>((ref) {
  final activeTimers = ref.watch(activeTimersProvider);
  return activeTimers.length;
});
