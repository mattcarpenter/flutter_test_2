import 'dart:convert';

/// Content extracted from Open Graph meta tags on a web page.
///
/// Used when extracting recipe information from social media URLs
/// (Instagram, TikTok, etc.) via a hidden WebView.
class OGExtractedContent {
  /// The og:title meta tag content
  final String? title;

  /// The og:description meta tag content
  final String? description;

  /// The og:image meta tag content (URL)
  final String? imageUrl;

  /// The og:site_name meta tag content
  final String? siteName;

  const OGExtractedContent({
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
  });

  /// Creates an instance from JSON string returned by JavaScript evaluation
  factory OGExtractedContent.fromJsonString(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return OGExtractedContent.fromJson(json);
    } catch (_) {
      return const OGExtractedContent();
    }
  }

  factory OGExtractedContent.fromJson(Map<String, dynamic> json) {
    return OGExtractedContent(
      title: json['title'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image'] as String?,
      siteName: json['siteName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image': imageUrl,
      if (siteName != null) 'siteName': siteName,
    };
  }

  /// Returns true if any content was successfully extracted
  bool get hasContent =>
      (title != null && title!.isNotEmpty) ||
      (description != null && description!.isNotEmpty);

  /// Returns a preview string suitable for display, truncated if needed
  String? getPreview({int maxLength = 200}) {
    // Prefer title, fall back to description
    final text = title ?? description;
    if (text == null || text.isEmpty) return null;

    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  String toString() {
    return 'OGExtractedContent(title: $title, description: $description, siteName: $siteName)';
  }
}
