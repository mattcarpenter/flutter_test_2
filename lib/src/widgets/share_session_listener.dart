import 'dart:async';
import 'dart:io' show Platform;
import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/share/views/share_session_modal.dart';
import '../mobile/adaptive_app.dart' show globalRootNavigatorKey;
import '../services/logging/app_logger.dart';

/// A widget that listens for share session deep links and shows the share modal.
///
/// This handles the URL scheme: `app.stockpot.app://share?sessionId=UUID`
/// When detected, it shows the share session modal to display the shared content.
class ShareSessionListener extends ConsumerStatefulWidget {
  final Widget child;

  const ShareSessionListener({super.key, required this.child});

  @override
  ConsumerState<ShareSessionListener> createState() =>
      _ShareSessionListenerState();
}

class _ShareSessionListenerState extends ConsumerState<ShareSessionListener> {
  StreamSubscription<Uri>? _linkSubscription;
  final _appLinks = AppLinks();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
    _checkInitialLink();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinkListener() {
    // Only listen on iOS for share extension links
    if (!Platform.isIOS) return;

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleUri(uri);
      },
      onError: (err) {
        AppLogger.error('Share link stream error', err);
      },
    );
  }

  Future<void> _checkInitialLink() async {
    // Only check on iOS for share extension links
    if (!Platform.isIOS) return;

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e, stack) {
      AppLogger.error('Failed to get initial share link', e, stack);
    }
  }

  void _handleUri(Uri uri) {
    // Check if this is a share session URL
    if (uri.scheme != 'app.stockpot.app') return;
    if (uri.host != 'share') return;

    final sessionId = uri.queryParameters['sessionId'];
    if (sessionId == null || sessionId.isEmpty) {
      AppLogger.warning('Share URL missing sessionId: $uri');
      return;
    }

    AppLogger.info('Received share session: $sessionId');
    _showShareModal(sessionId);
  }

  Future<void> _showShareModal(String sessionId) async {
    // Prevent duplicate processing
    if (_isProcessing) return;
    _isProcessing = true;

    // Wait a short delay for the app UI to stabilize after deep link opens
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final navigatorContext = globalRootNavigatorKey.currentContext;
      if (navigatorContext == null) {
        AppLogger.warning('Navigator context not available for share modal');
        _isProcessing = false;
        return;
      }

      // Show the share session modal
      // ignore: use_build_context_synchronously - intentional delay for UI stability
      await showShareSessionModal(navigatorContext, ref, sessionId);
    } catch (e, stack) {
      AppLogger.error('Failed to show share session modal', e, stack);
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
