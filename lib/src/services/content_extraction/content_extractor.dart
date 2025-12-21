import '../../features/share/models/og_extracted_content.dart';
import '../logging/app_logger.dart';
import 'extractors/site_extractor.dart';
import 'extractors/tiktok_extractor.dart';
import 'extractors/webview_og_extractor.dart';

/// Main service for extracting content from shared URLs.
///
/// Orchestrates multiple site-specific extractors, dispatching to the
/// appropriate one based on the URL's domain.
///
/// Currently supports:
/// - TikTok (via HTTP fetch + HTML parsing)
/// - Instagram (via WebView + OG meta tags)
///
/// Usage:
/// ```dart
/// final extractor = ContentExtractor();
/// final content = await extractor.extract(Uri.parse('https://...'));
/// ```
class ContentExtractor {
  /// Ordered list of extractors to try.
  /// More specific extractors should come first.
  final List<SiteExtractor> _extractors = [
    TikTokExtractor(),
    WebViewOGExtractor(),
  ];

  /// Check if a URI is from a supported domain.
  bool isSupported(Uri uri) {
    return _extractors.any((extractor) => extractor.canHandle(uri));
  }

  /// Extract content from a URL.
  ///
  /// Returns [OGExtractedContent] on success, or null if no extractor
  /// can handle the URL or extraction fails.
  Future<OGExtractedContent?> extract(Uri uri) async {
    for (final extractor in _extractors) {
      if (extractor.canHandle(uri)) {
        AppLogger.debug(
          'ContentExtractor: Using ${extractor.runtimeType} for $uri',
        );
        return extractor.extract(uri);
      }
    }

    AppLogger.debug('ContentExtractor: No extractor found for $uri');
    return null;
  }

  /// Get a user-friendly display name for the domain.
  ///
  /// Returns null if the URL is not supported.
  String? getDisplayName(Uri uri) {
    for (final extractor in _extractors) {
      if (extractor.canHandle(uri)) {
        return extractor.getDisplayName(uri);
      }
    }
    return null;
  }

  /// Static convenience method to check if a URI is supported.
  ///
  /// Useful when you don't have an instance of ContentExtractor.
  static bool isSupportedUrl(Uri uri) {
    return ContentExtractor().isSupported(uri);
  }

  /// Static convenience method to get display name.
  ///
  /// Useful when you don't have an instance of ContentExtractor.
  static String? getDisplayNameForUrl(Uri uri) {
    return ContentExtractor().getDisplayName(uri);
  }
}
