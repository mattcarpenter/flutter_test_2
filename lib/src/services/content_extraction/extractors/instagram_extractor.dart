import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../../../features/share/models/og_extracted_content.dart';
import '../../logging/app_logger.dart';
import 'site_extractor.dart';

/// Extractor for Instagram posts.
///
/// Uses direct HTTP fetch + HTML parsing to extract OG meta tags.
/// This is faster than WebView and works if Instagram serves OG tags in static HTML.
class InstagramExtractor extends SiteExtractor {
  /// Timeout for HTTP requests
  static const _timeout = Duration(seconds: 8);

  /// User agent to mimic mobile browser
  static const _userAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';

  @override
  List<String> get supportedDomains => ['instagram.com'];

  @override
  String? getDisplayName(Uri uri) => 'Instagram';

  @override
  Future<OGExtractedContent?> extract(Uri uri) async {
    AppLogger.info('InstagramExtractor: Starting extraction for $uri');
    final stopwatch = Stopwatch()..start();

    try {
      // Make HTTP GET request
      final response = await http.get(
        uri,
        headers: {'User-Agent': _userAgent},
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        AppLogger.warning(
          'InstagramExtractor: HTTP ${response.statusCode} for $uri',
        );
        return null;
      }

      AppLogger.debug(
        'InstagramExtractor: Received ${response.body.length} bytes, parsing HTML',
      );

      // Parse HTML
      final document = html_parser.parse(response.body);

      // Extract OG meta tags
      String? getMetaContent(String property) {
        final element = document.querySelector('meta[property="$property"]');
        return element?.attributes['content'];
      }

      final title = getMetaContent('og:title');
      final description = getMetaContent('og:description');
      final image = getMetaContent('og:image');
      final siteName = getMetaContent('og:site_name');

      stopwatch.stop();
      AppLogger.info(
        'InstagramExtractor: Completed in ${stopwatch.elapsedMilliseconds}ms',
      );

      // Check if we got any useful content
      if ((title == null || title.isEmpty) &&
          (description == null || description.isEmpty)) {
        AppLogger.warning('InstagramExtractor: No OG content found in HTML');
        return null; // Return null to trigger fallback to WebView
      }

      AppLogger.info(
        'InstagramExtractor: Extracted - ${title?.substring(0, (title.length).clamp(0, 50))}...',
      );

      return OGExtractedContent(
        title: title,
        description: description,
        imageUrl: image,
        siteName: siteName ?? 'Instagram',
      );
    } on http.ClientException catch (e) {
      AppLogger.error('InstagramExtractor: HTTP error', e);
      return null;
    } catch (e, stack) {
      AppLogger.error('InstagramExtractor: Extraction failed', e, stack);
      return null;
    }
  }
}
