/// A single help topic with its title and markdown content.
class HelpTopic {
  /// The title of the help topic (extracted from H1 in markdown).
  final String title;

  /// The markdown content (everything after the H1 title).
  final String content;

  /// The original file path (for debugging).
  final String filePath;

  const HelpTopic({
    required this.title,
    required this.content,
    required this.filePath,
  });

  /// Plain text content for search indexing (strips markdown formatting).
  String get searchText {
    // Simple markdown stripping for search
    return content
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1') // Bold
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1') // Italic
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1') // Code
        .replaceAll(RegExp(r'#{1,6}\s+'), '') // Headers
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1') // Links
        .replaceAll(RegExp(r'[-*+]\s+'), '') // List items
        .replaceAll(RegExp(r'\d+\.\s+'), ''); // Numbered lists
  }

  /// Check if this topic matches a search query.
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowerQuery) ||
        searchText.toLowerCase().contains(lowerQuery);
  }
}

/// A section of help topics (e.g., "Quick Questions", "Learn More").
class HelpSection {
  /// Display name for the section.
  final String name;

  /// The folder key in assets/docs/ (e.g., "quick-questions").
  final String folderKey;

  /// The topics in this section.
  final List<HelpTopic> topics;

  const HelpSection({
    required this.name,
    required this.folderKey,
    required this.topics,
  });
}
