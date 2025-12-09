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
///
/// This listener only detects when timers transition from active to expired.
/// The modal itself watches the timer provider directly and handles:
/// - Displaying all currently expired timers
/// - Updating when new timers expire while the modal is open
/// - Tracking which timers the user has dismissed
class TimerExpirationListener extends ConsumerStatefulWidget {
  final Widget child;

  const TimerExpirationListener({super.key, required this.child});

  @override
  ConsumerState<TimerExpirationListener> createState() =>
      _TimerExpirationListenerState();
}

class _TimerExpirationListenerState
    extends ConsumerState<TimerExpirationListener> with WidgetsBindingObserver {
  /// Track previous active timer IDs to detect transitions
  Set<String> _previousActiveIds = {};

  /// Whether a modal is currently being shown
  bool _isModalShowing = false;

  /// Track app lifecycle state to avoid playing audio when backgrounded
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasBackgrounded = _lifecycleState != AppLifecycleState.resumed;
    _lifecycleState = state;

    // When app returns to foreground, check for any expired timers
    // that fired while we were backgrounded
    if (wasBackgrounded && state == AppLifecycleState.resumed) {
      _checkForExpiredTimersOnResume();
    }
  }

  /// Check for expired timers when app returns to foreground.
  /// Shows the modal if there are expired timers that weren't shown while backgrounded.
  void _checkForExpiredTimersOnResume() {
    final timers = ref.read(timerNotifierProvider).valueOrNull;
    if (timers == null) return;

    final hasExpiredTimers = timers.any((t) => t.isExpired);
    if (hasExpiredTimers && !_isModalShowing) {
      _showExpirationModal();
    }
  }

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

    // Find timer IDs that were active but are no longer active
    final noLongerActiveIds = _previousActiveIds.difference(currentActiveIds);

    // Update previous active IDs for next comparison
    _previousActiveIds = currentActiveIds;

    // Check if any of those timers actually expired (vs being cancelled/deleted)
    // A cancelled timer is removed from the list entirely
    // An expired timer still exists but with isExpired = true
    final actuallyExpired = noLongerActiveIds.any((id) {
      final timer = timers.where((t) => t.id == id).firstOrNull;
      return timer != null && timer.isExpired;
    });

    // Only show modal if at least one timer actually expired
    if (actuallyExpired && !_isModalShowing) {
      _showExpirationModal();
    }
  }

  void _showExpirationModal() {
    // Don't show modal or play in-app audio when app is backgrounded.
    // The system notification handles alerting the user in that case.
    if (_lifecycleState != AppLifecycleState.resumed) {
      AppLogger.debug(
        'Timer expired but app is backgrounded - relying on system notification',
      );
      return;
    }

    final navigatorContext = globalRootNavigatorKey.currentContext;
    if (navigatorContext == null) {
      AppLogger.warning(
        'Cannot show timer expiration modal: no navigator context',
      );
      return;
    }

    AppLogger.info('Timer expired, showing expiration modal');

    _isModalShowing = true;

    // Show the modal - it watches the provider directly for all expired timers
    showTimerExpiredModal(navigatorContext).then((_) {
      _isModalShowing = false;
    });
  }
}
