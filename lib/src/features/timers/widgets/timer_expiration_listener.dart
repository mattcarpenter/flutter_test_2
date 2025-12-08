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
    extends ConsumerState<TimerExpirationListener> {
  /// Track previous active timer IDs to detect transitions
  Set<String> _previousActiveIds = {};

  /// Whether a modal is currently being shown
  bool _isModalShowing = false;

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
