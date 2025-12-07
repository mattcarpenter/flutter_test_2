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
  }

  @override
  void dispose() {
    _subscription.cancel();
    _tickTimer?.cancel();
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
      // Create timer in database
      final timerId = await _repository.createTimer(
        recipeId: recipeId,
        recipeName: recipeName,
        stepId: stepId,
        stepNumber: stepNumber,
        totalSteps: totalSteps,
        detectedText: detectedText,
        durationSeconds: duration.inSeconds,
      );

      // Schedule notification
      try {
        final enabled = await _notificationService.areNotificationsEnabled();
        if (enabled) {
          final notificationId =
              await _notificationService.scheduleTimerNotification(
            recipeName: recipeName,
            stepNumber: stepNumber,
            duration: duration,
          );

          // Update timer with notification ID
          await _repository.updateNotificationId(timerId, notificationId);
        }
      } catch (e, stack) {
        AppLogger.error('Failed to schedule notification', e, stack);
        // Continue without notification - timer will still work in-app
      }

      AppLogger.info(
        'Timer started: "$recipeName" step $stepNumber, ${duration.inSeconds}s',
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
  Future<void> extendTimer(String timerId, Duration extension) async {
    try {
      final timer = await _repository.getTimer(timerId);
      if (timer == null) {
        AppLogger.warning('Cannot extend timer $timerId: not found');
        return;
      }

      // Cancel existing notification
      if (timer.notificationId != null) {
        await _notificationService.cancelNotification(timer.notificationId!);
      }

      // Extend the timer in database
      await _repository.extendTimer(timerId, extension.inSeconds);

      // Schedule new notification with extended time
      try {
        final enabled = await _notificationService.areNotificationsEnabled();
        if (enabled) {
          final newRemaining = timer.remaining + extension;
          final newNotificationId =
              await _notificationService.scheduleTimerNotification(
            recipeName: timer.recipeName,
            stepNumber: timer.stepNumber,
            duration: newRemaining,
          );

          await _repository.updateNotificationId(timerId, newNotificationId);
        }
      } catch (e, stack) {
        AppLogger.error('Failed to reschedule notification', e, stack);
      }

      AppLogger.debug('Extended timer by ${extension.inSeconds}s');
    } catch (e, stack) {
      AppLogger.error('Failed to extend timer', e, stack);
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Cancel an active timer and its notification.
  Future<void> cancelTimer(String timerId) async {
    try {
      final timer = await _repository.getTimer(timerId);
      if (timer == null) {
        AppLogger.warning('Cannot cancel timer $timerId: not found');
        return;
      }

      // Cancel notification if it exists
      if (timer.notificationId != null) {
        await _notificationService.cancelNotification(timer.notificationId!);
      }

      // Delete timer from database
      await _repository.cancelTimer(timerId);
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
