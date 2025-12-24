import '../../features/share/models/og_extracted_content.dart';
import '../logging/app_logger.dart';
import 'extractors/instagram_extractor.dart';
import 'extractors/site_extractor.dart';
import 'extractors/tiktok_extractor.dart';
import 'extractors/webview_og_extractor.dart';
import 'extractors/youtube_extractor.dart';

/// Main service for extracting content from shared URLs.
///
/// Orchestrates multiple site-specific extractors, dispatching to the
/// appropriate one based on the URL's domain. If an extractor returns null,
/// the next matching extractor is tried (fallback behavior).
///
/// Currently supports:
/// - TikTok (via HTTP fetch + HTML parsing)
/// - Instagram (via HTTP fetch, with WebView fallback)
///
/// Usage:
/// ```dart
/// final extractor = ContentExtractor();
/// final content = await extractor.extract(Uri.parse('https://...'));
/// ```
class ContentExtractor {
  /// Ordered list of extractors to try.
  /// More specific/faster extractors should come first.
  /// If an extractor returns null, the next matching one is tried.
  final List<SiteExtractor> _extractors = [
    YouTubeExtractor(),
    TikTokExtractor(),
    InstagramExtractor(), // Try HTTP first
    WebViewOGExtractor(), // Fallback for Instagram if HTTP fails
  ];

  /// Check if a URI is from a supported domain.
  bool isSupported(Uri uri) {
    return _extractors.any((extractor) => extractor.canHandle(uri));
  }

  /// Extract content from a URL.
  ///
  /// Tries each matching extractor in order. If an extractor returns null
  /// (extraction failed), the next matching extractor is tried.
  ///
  /// Returns [OGExtractedContent] on success, or null if all extractors fail.
  Future<OGExtractedContent?> extract(Uri uri) async {
    for (final extractor in _extractors) {
      if (extractor.canHandle(uri)) {
        AppLogger.debug(
          'ContentExtractor: Trying ${extractor.runtimeType} for $uri',
        );
        final result = await extractor.extract(uri);

        if (result != null && result.hasContent) {
          return result;
        }

        // Extractor returned null or empty content, try next one
        AppLogger.debug(
          'ContentExtractor: ${extractor.runtimeType} returned no content, trying next',
        );
      }
    }

    AppLogger.debug('ContentExtractor: All extractors failed for $uri');
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
