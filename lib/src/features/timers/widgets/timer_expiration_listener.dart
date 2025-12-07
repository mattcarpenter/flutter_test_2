import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/database.dart';
import '../../../../database/models/timers.dart';
import '../../../providers/timer_provider.dart';
import '../../../services/logging/app_logger.dart';
import '../../../mobile/adaptive_app.dart' show globalRootNavigatorKey;
import 'timer_expired_modal.dart';

/// A widget that listens for timer expirations and shows the expired modal.
///
/// Place this widget high in the widget tree (e.g., in the app wrapper)
/// to detect timer expirations globally.
class TimerExpirationListener extends ConsumerStatefulWidget {
  final Widget child;

  const TimerExpirationListener({super.key, required this.child});

  @override
  ConsumerState<TimerExpirationListener> createState() =>
      _TimerExpirationListenerState();
}

class _TimerExpirationListenerState
    extends ConsumerState<TimerExpirationListener> {
  /// Track timers we've already shown the modal for
  final Set<String> _notifiedTimerIds = {};

  /// Track previous active timer IDs to detect transitions
  Set<String> _previousActiveIds = {};

  @override
  Widget build(BuildContext context) {
    // Listen for changes and detect expirations
    ref.listen(
      timerNotifierProvider,
      (previous, current) {
        _checkForExpirations(current);
      },
    );

    return widget.child;
  }

  void _checkForExpirations(AsyncValue<List<TimerEntry>> timersAsync) {
    final timers = timersAsync.valueOrNull;
    if (timers == null) return;

    // Get currently active timer IDs
    final currentActiveIds =
        timers.where((t) => t.isActive).map((t) => t.id).toSet();

    // Find timers that became active again (extended) - clear from notified set
    // so they can trigger the modal again when they expire
    final reactivatedIds = currentActiveIds.difference(_previousActiveIds);
    _notifiedTimerIds.removeAll(reactivatedIds);

    // Find timers that were active but are now expired
    final expiredIds = _previousActiveIds.difference(currentActiveIds);

    // Get the expired timers that we haven't notified about yet
    final timersToNotify = timers.where(
        (t) => expiredIds.contains(t.id) && !_notifiedTimerIds.contains(t.id));

    // Show modal for each newly expired timer
    for (final timer in timersToNotify) {
      _notifiedTimerIds.add(timer.id);
      _showExpirationModal(timer);
    }

    // Update previous active IDs for next comparison
    _previousActiveIds = currentActiveIds;

    // Clean up old notified IDs (remove IDs that are no longer in the timer list)
    final allTimerIds = timers.map((t) => t.id).toSet();
    _notifiedTimerIds.removeWhere((id) => !allTimerIds.contains(id));
  }

  void _showExpirationModal(TimerEntry timer) {
    // Get the global navigator context
    final navigatorContext = globalRootNavigatorKey.currentContext;
    if (navigatorContext == null) {
      AppLogger.warning(
        'Cannot show timer expiration modal: no navigator context',
      );
      return;
    }

    AppLogger.info(
      'Timer expired: "${timer.recipeName}" step ${timer.stepNumber}',
    );

    // Show the modal
    showTimerExpiredModal(
      navigatorContext,
      timer: timer,
    );
  }
}
