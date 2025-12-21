import 'dart:async';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../features/share/models/og_extracted_content.dart';
import '../../logging/app_logger.dart';
import 'site_extractor.dart';

/// Extractor for sites that use standard Open Graph meta tags.
///
/// Uses a headless WebView to load the page and extract og:title,
/// og:description, og:image, and og:site_name via JavaScript.
///
/// This extractor works for sites like Instagram that serve OG tags
/// in the HTML that may require JavaScript to fully render.
class WebViewOGExtractor extends SiteExtractor {
  /// Timeout for page load and extraction
  static const _timeout = Duration(seconds: 8);

  /// User agent to mimic mobile browser
  static const _userAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';

  /// JavaScript to extract OG meta tags
  static const _extractionScript = '''
    (function() {
      const getMeta = (property) => {
        const el = document.querySelector('meta[property="' + property + '"]');
        return el ? el.getAttribute('content') : null;
      };
      return JSON.stringify({
        title: getMeta('og:title'),
        description: getMeta('og:description'),
        image: getMeta('og:image'),
        siteName: getMeta('og:site_name')
      });
    })();
  ''';

  /// Domain to display name mapping
  static const _displayNames = {
    'instagram.com': 'Instagram',
  };

  @override
  List<String> get supportedDomains => ['instagram.com'];

  @override
  String? getDisplayName(Uri uri) {
    final host = uri.host.toLowerCase();
    for (final entry in _displayNames.entries) {
      if (host.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  Future<OGExtractedContent?> extract(Uri uri) async {
    AppLogger.info('WebViewOGExtractor: Starting extraction for $uri');
    final stopwatch = Stopwatch()..start();

    HeadlessInAppWebView? headlessWebView;
    final completer = Completer<OGExtractedContent?>();

    try {
      // Create headless WebView with optimized settings
      headlessWebView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri.uri(uri)),
        initialSettings: InAppWebViewSettings(
          // Block images for faster loading
          blockNetworkImage: true,
          // Disable JavaScript popups
          javaScriptCanOpenWindowsAutomatically: false,
          // Disable media autoplay
          mediaPlaybackRequiresUserGesture: true,
          // Disable cache for fresh content
          cacheEnabled: false,
          // Use mobile user agent
          userAgent: _userAgent,
          // Disable unnecessary features
          allowsInlineMediaPlayback: false,
          allowsPictureInPictureMediaPlayback: false,
          isFraudulentWebsiteWarningEnabled: false,
        ),
        onLoadStop: (controller, url) async {
          if (completer.isCompleted) return;

          AppLogger.debug(
            'WebViewOGExtractor: onLoadStop fired for URL: $url',
          );

          try {
            // Small delay to let any dynamic content render
            await Future.delayed(const Duration(milliseconds: 500));
            if (completer.isCompleted) return;

            AppLogger.debug('WebViewOGExtractor: Executing JS extraction');

            // Execute JavaScript to extract OG tags
            final result = await controller.evaluateJavascript(
              source: _extractionScript,
            );

            if (result != null &&
                result is String &&
                result.isNotEmpty &&
                result != 'null') {
              final content = OGExtractedContent.fromJsonString(result);
              AppLogger.info(
                'WebViewOGExtractor: Extracted - title: ${content.title?.substring(0, (content.title?.length ?? 0).clamp(0, 50))}...',
              );
              if (!completer.isCompleted) {
                completer.complete(content);
              }
            } else {
              AppLogger.warning('WebViewOGExtractor: No OG content found');
              if (!completer.isCompleted) {
                completer.complete(const OGExtractedContent());
              }
            }
          } catch (e, stack) {
            AppLogger.error(
              'WebViewOGExtractor: JS evaluation failed',
              e,
              stack,
            );
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          }
        },
        onReceivedError: (controller, request, error) {
          AppLogger.error(
            'WebViewOGExtractor: Load error - ${error.type}: ${error.description}',
          );
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
        onReceivedHttpError: (controller, request, response) {
          AppLogger.error(
            'WebViewOGExtractor: HTTP error - ${response.statusCode}: ${response.reasonPhrase}',
          );
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      );

      // Start loading
      await headlessWebView.run();

      // Wait for result with timeout
      final result = await completer.future.timeout(
        _timeout,
        onTimeout: () {
          AppLogger.warning('WebViewOGExtractor: Timeout after $_timeout');
          return null;
        },
      );

      stopwatch.stop();
      AppLogger.info(
        'WebViewOGExtractor: Completed in ${stopwatch.elapsedMilliseconds}ms',
      );

      return result;
    } catch (e, stack) {
      AppLogger.error('WebViewOGExtractor: Extraction failed', e, stack);
      return null;
    } finally {
      // Clean up
      try {
        await headlessWebView?.dispose();
      } catch (_) {
        // Ignore disposal errors
      }
    }
  }
}
