import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../../../features/share/models/og_extracted_content.dart';
import '../../logging/app_logger.dart';
import 'site_extractor.dart';

/// Extractor for TikTok videos.
///
/// Uses direct HTTP fetch + HTML parsing instead of WebView for performance.
/// TikTok embeds video data in a script tag with id "__UNIVERSAL_DATA_FOR_REHYDRATION__".
class TikTokExtractor extends SiteExtractor {
  /// Timeout for HTTP requests
  static const _timeout = Duration(seconds: 8);

  /// User agent to mimic mobile browser
  static const _userAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';

  @override
  List<String> get supportedDomains => ['tiktok.com'];

  @override
  String? getDisplayName(Uri uri) => 'TikTok';

  @override
  Future<OGExtractedContent?> extract(Uri uri) async {
    AppLogger.info('TikTokExtractor: Starting extraction for $uri');
    final stopwatch = Stopwatch()..start();

    try {
      // Make HTTP GET request (follows redirects automatically)
      final response = await http.get(
        uri,
        headers: {'User-Agent': _userAgent},
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        AppLogger.warning(
          'TikTokExtractor: HTTP ${response.statusCode} for $uri',
        );
        return null;
      }

      AppLogger.debug(
        'TikTokExtractor: Received ${response.body.length} bytes, parsing HTML',
      );

      // Parse HTML
      final document = html_parser.parse(response.body);

      // Find the data script tag
      final scriptElement = document.getElementById(
        '__UNIVERSAL_DATA_FOR_REHYDRATION__',
      );

      if (scriptElement == null) {
        AppLogger.warning(
          'TikTokExtractor: Could not find __UNIVERSAL_DATA_FOR_REHYDRATION__ script',
        );
        return null;
      }

      // Parse JSON from script content
      final jsonContent = scriptElement.text;
      if (jsonContent.isEmpty) {
        AppLogger.warning('TikTokExtractor: Script tag is empty');
        return null;
      }

      final data = jsonDecode(jsonContent) as Map<String, dynamic>;

      // Navigate to video details
      // Path: __DEFAULT_SCOPE__ -> webapp.video-detail -> itemInfo -> itemStruct
      final defaultScope = data['__DEFAULT_SCOPE__'] as Map<String, dynamic>?;
      if (defaultScope == null) {
        AppLogger.warning('TikTokExtractor: __DEFAULT_SCOPE__ not found');
        return null;
      }

      final videoDetail =
          defaultScope['webapp.video-detail'] as Map<String, dynamic>?;
      if (videoDetail == null) {
        AppLogger.warning('TikTokExtractor: webapp.video-detail not found');
        return null;
      }

      final itemInfo = videoDetail['itemInfo'] as Map<String, dynamic>?;
      final itemStruct = itemInfo?['itemStruct'] as Map<String, dynamic>?;

      if (itemStruct == null) {
        AppLogger.warning('TikTokExtractor: itemStruct not found');
        return null;
      }

      // Extract the data we need
      final desc = itemStruct['desc'] as String?;
      final video = itemStruct['video'] as Map<String, dynamic>?;
      final cover = video?['cover'] as String?;

      stopwatch.stop();
      AppLogger.info(
        'TikTokExtractor: Completed in ${stopwatch.elapsedMilliseconds}ms',
      );

      if (desc == null || desc.isEmpty) {
        AppLogger.warning('TikTokExtractor: No description found');
        return const OGExtractedContent();
      }

      AppLogger.info(
        'TikTokExtractor: Extracted - ${desc.substring(0, desc.length.clamp(0, 50))}...',
      );

      return OGExtractedContent(
        title: desc,
        description: desc,
        imageUrl: cover,
        siteName: 'TikTok',
      );
    } on http.ClientException catch (e) {
      AppLogger.error('TikTokExtractor: HTTP error', e);
      return null;
    } on FormatException catch (e) {
      AppLogger.error('TikTokExtractor: JSON parse error', e);
      return null;
    } catch (e, stack) {
      AppLogger.error('TikTokExtractor: Extraction failed', e, stack);
      return null;
    }
  }
}
