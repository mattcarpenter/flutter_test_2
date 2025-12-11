/// Extracts plain text from Quill Delta JSON content.
///
/// Quill stores content as JSON like: `[{"insert":"Hello world\n"}]`
/// This function extracts just the text portions for display and search.
String extractPlainTextFromQuillJson(String? content) {
  if (content == null || content.isEmpty) return '';

  try {
    // Check if it's JSON format
    if (content.startsWith('[') || content.startsWith('{')) {
      // Extract text from "insert" fields using regex
      final RegExp textPattern = RegExp(r'"insert"\s*:\s*"([^"]*)"');
      final matches = textPattern.allMatches(content);
      final buffer = StringBuffer();
      for (final match in matches) {
        buffer.write(match.group(1));
      }
      return buffer.toString().replaceAll('\\n', '\n').trim();
    }
    // Not JSON, return as-is
    return content;
  } catch (_) {
    // If parsing fails, return original content
    return content;
  }
}
