import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../features/share/models/og_extracted_content.dart';
import '../../logging/app_logger.dart';
import 'site_extractor.dart';

/// Extractor for YouTube videos.
///
/// Uses direct HTTP fetch + HTML parsing to extract video metadata from
/// the embedded `ytInitialPlayerResponse` JavaScript object.
class YouTubeExtractor extends SiteExtractor {
  /// Timeout for HTTP requests
  static const _timeout = Duration(seconds: 10);

  /// User agent to mimic mobile browser
  static const _userAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';

  /// Marker for the player response JSON in HTML
  static const _playerResponseMarker = 'var ytInitialPlayerResponse = ';

  @override
  List<String> get supportedDomains => ['youtube.com', 'youtu.be'];

  @override
  String? getDisplayName(Uri uri) => 'YouTube';

  @override
  Future<OGExtractedContent?> extract(Uri uri) async {
    AppLogger.info('YouTubeExtractor: Starting extraction for $uri');
    final stopwatch = Stopwatch()..start();

    try {
      // Make HTTP GET request
      final response = await http.get(
        uri,
        headers: {'User-Agent': _userAgent},
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        AppLogger.warning(
          'YouTubeExtractor: HTTP ${response.statusCode} for $uri',
        );
        return null;
      }

      AppLogger.debug(
        'YouTubeExtractor: Received ${response.body.length} bytes, parsing HTML',
      );

      // Find and extract the ytInitialPlayerResponse JSON
      final jsonString = _extractJsonObject(response.body, _playerResponseMarker);
      if (jsonString == null) {
        AppLogger.warning(
          'YouTubeExtractor: Could not find ytInitialPlayerResponse in HTML',
        );
        return null;
      }

      // Parse JSON
      final Map<String, dynamic> playerResponse;
      try {
        playerResponse = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        AppLogger.warning('YouTubeExtractor: Failed to parse JSON: $e');
        return null;
      }

      // Extract videoDetails
      final videoDetails = playerResponse['videoDetails'] as Map<String, dynamic>?;
      if (videoDetails == null) {
        AppLogger.warning('YouTubeExtractor: No videoDetails in player response');
        return null;
      }

      final title = videoDetails['title'] as String?;
      final description = videoDetails['shortDescription'] as String?;

      // Extract thumbnail - find the largest one
      String? thumbnailUrl;
      final thumbnail = videoDetails['thumbnail'] as Map<String, dynamic>?;
      if (thumbnail != null) {
        final thumbnails = thumbnail['thumbnails'] as List<dynamic>?;
        if (thumbnails != null && thumbnails.isNotEmpty) {
          final largest = _getLargestThumbnail(thumbnails);
          thumbnailUrl = largest?['url'] as String?;
        }
      }

      stopwatch.stop();
      AppLogger.info(
        'YouTubeExtractor: Completed in ${stopwatch.elapsedMilliseconds}ms',
      );

      // Check if we got any useful content
      if ((title == null || title.isEmpty) &&
          (description == null || description.isEmpty)) {
        AppLogger.warning('YouTubeExtractor: No content found in videoDetails');
        return null;
      }

      AppLogger.info(
        'YouTubeExtractor: Extracted - ${title?.substring(0, (title.length).clamp(0, 50))}...',
      );

      return OGExtractedContent(
        title: title,
        description: description,
        imageUrl: thumbnailUrl,
        siteName: 'YouTube',
      );
    } on http.ClientException catch (e) {
      AppLogger.error('YouTubeExtractor: HTTP error', e);
      return null;
    } catch (e, stack) {
      AppLogger.error('YouTubeExtractor: Extraction failed', e, stack);
      return null;
    }
  }

  /// Extract a JSON object from HTML starting at the given marker.
  ///
  /// Uses brace-counting with string awareness to correctly handle
  /// nested objects and braces within string values.
  String? _extractJsonObject(String html, String marker) {
    final startIndex = html.indexOf(marker);
    if (startIndex == -1) return null;

    final jsonStart = html.indexOf('{', startIndex + marker.length);
    if (jsonStart == -1) return null;

    var depth = 0;
    var inString = false;
    var escaped = false;

    for (var i = jsonStart; i < html.length; i++) {
      final char = html[i];

      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == '\\' && inString) {
        escaped = true;
        continue;
      }
      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (!inString) {
        if (char == '{') depth++;
        if (char == '}') {
          depth--;
          if (depth == 0) {
            return html.substring(jsonStart, i + 1);
          }
        }
      }
    }
    return null;
  }

  /// Find the largest thumbnail by width from the thumbnails array.
  Map<String, dynamic>? _getLargestThumbnail(List<dynamic> thumbnails) {
    if (thumbnails.isEmpty) return null;

    return thumbnails.reduce((a, b) {
      final aWidth = (a['width'] as num?)?.toInt() ?? 0;
      final bWidth = (b['width'] as num?)?.toInt() ?? 0;
      return aWidth > bWidth ? a : b;
    }) as Map<String, dynamic>;
  }
}
