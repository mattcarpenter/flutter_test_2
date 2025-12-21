import '../../../features/share/models/og_extracted_content.dart';

/// Base class for site-specific content extractors.
///
/// Each extractor handles specific domains and knows how to extract
/// content (title, description, image) from those sites.
abstract class SiteExtractor {
  /// List of domains this extractor supports.
  /// Used for matching URLs to extractors.
  List<String> get supportedDomains;

  /// Check if this extractor can handle the given URI.
  ///
  /// Default implementation checks if the host contains any of the supported domains.
  bool canHandle(Uri uri) {
    final host = uri.host.toLowerCase();
    return supportedDomains.any((domain) => host.contains(domain));
  }

  /// Extract content from the given URI.
  ///
  /// Returns [OGExtractedContent] on success, or null if extraction fails.
  Future<OGExtractedContent?> extract(Uri uri);

  /// Get a user-friendly display name for the domain.
  ///
  /// Used for UI purposes like "Fetching from Instagram..."
  /// Returns null if no display name is available.
  String? getDisplayName(Uri uri);
}
