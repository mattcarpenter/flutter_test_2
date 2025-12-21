import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../features/share/models/og_extracted_content.dart';
import 'logging/app_logger.dart';

/// Service for extracting Open Graph metadata from web URLs.
///
/// Uses a headless WebView to load the page and extract og:title,
/// og:description, and other OG tags via JavaScript.
///
/// Currently supports:
/// - instagram.com
/// - tiktok.com (future)
class OGContentExtractor {
  /// Timeout for page load and extraction
  static const _timeout = Duration(seconds: 8);

  /// Domains supported for OG extraction
  static const _supportedDomains = [
    'instagram.com',
    // 'tiktok.com', // Future
  ];

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

  /// Check if a URI is from a supported domain
  static bool isSupported(Uri uri) {
    final host = uri.host.toLowerCase();
    return _supportedDomains.any((domain) => host.contains(domain));
  }

  /// Extract OG content from a URL.
  ///
  /// Returns null if the URL is not supported or extraction fails.
  Future<OGExtractedContent?> extract(Uri uri) async {
    if (!isSupported(uri)) {
      AppLogger.debug('OGContentExtractor: URL not supported: $uri');
      return null;
    }

    AppLogger.info('OGContentExtractor: Starting extraction for $uri');
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
          userAgent:
              'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
          // Disable unnecessary features
          allowsInlineMediaPlayback: false,
          allowsPictureInPictureMediaPlayback: false,
          isFraudulentWebsiteWarningEnabled: false,
        ),
        onLoadStop: (controller, url) async {
          if (completer.isCompleted) return;

          try {
            AppLogger.debug('OGContentExtractor: Page loaded, executing JS');

            // Execute JavaScript to extract OG tags
            final result = await controller.evaluateJavascript(
              source: _extractionScript,
            );

            if (result != null && result is String && result.isNotEmpty) {
              final content = OGExtractedContent.fromJsonString(result);
              AppLogger.info(
                'OGContentExtractor: Extracted content - title: ${content.title?.substring(0, (content.title?.length ?? 0).clamp(0, 50))}...',
              );
              if (!completer.isCompleted) {
                completer.complete(content);
              }
            } else {
              AppLogger.warning('OGContentExtractor: No OG content found');
              if (!completer.isCompleted) {
                completer.complete(const OGExtractedContent());
              }
            }
          } catch (e, stack) {
            AppLogger.error('OGContentExtractor: JS evaluation failed', e, stack);
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          }
        },
        onReceivedError: (controller, request, error) {
          AppLogger.error(
            'OGContentExtractor: Load error - ${error.type}: ${error.description}',
          );
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
        onReceivedHttpError: (controller, request, response) {
          AppLogger.error(
            'OGContentExtractor: HTTP error - ${response.statusCode}: ${response.reasonPhrase}',
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
          AppLogger.warning('OGContentExtractor: Timeout after $_timeout');
          return null;
        },
      );

      stopwatch.stop();
      AppLogger.info(
        'OGContentExtractor: Completed in ${stopwatch.elapsedMilliseconds}ms',
      );

      return result;
    } catch (e, stack) {
      AppLogger.error('OGContentExtractor: Extraction failed', e, stack);
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

  /// Get a user-friendly domain name for display
  static String? getDomainDisplayName(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host.contains('instagram.com')) return 'Instagram';
    if (host.contains('tiktok.com')) return 'TikTok';
    return null;
  }
}
