import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/help_topic.dart';

/// Section definitions in display order.
const _sectionDefinitions = [
  ('Adding Recipes', 'adding-recipes'),
  ('Quick Questions', 'quick-questions'),
  ('Learn More', 'learn-more'),
  ('Troubleshooting', 'troubleshooting'),
];

/// Provider that loads and parses all help topics from asset markdown files.
final helpTopicsProvider = FutureProvider<List<HelpSection>>((ref) async {
  final sections = <HelpSection>[];

  // Load asset manifest using modern API (supports both JSON and binary formats)
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

  for (final (sectionName, folderKey) in _sectionDefinitions) {
    final prefix = 'assets/docs/$folderKey/';
    final topics = <HelpTopic>[];

    // Find all markdown files in this section's folder
    final allAssets = manifest.listAssets();
    final sectionFiles = allAssets
        .where((path) => path.startsWith(prefix) && path.endsWith('.md'))
        .toList();

    // Sort alphabetically for consistent ordering
    sectionFiles.sort();

    for (final filePath in sectionFiles) {
      try {
        final content = await rootBundle.loadString(filePath);
        final topic = _parseMarkdownFile(content, filePath);
        if (topic != null) {
          topics.add(topic);
        }
      } catch (e) {
        // Skip files that fail to load
        continue;
      }
    }

    sections.add(HelpSection(
      name: sectionName,
      folderKey: folderKey,
      topics: topics,
    ));
  }

  return sections;
});

/// Parse a markdown file into a HelpTopic.
/// Extracts the H1 title and returns the rest as content.
HelpTopic? _parseMarkdownFile(String content, String filePath) {
  // Match the first H1 heading
  final h1Pattern = RegExp(r'^#\s+(.+)$', multiLine: true);
  final match = h1Pattern.firstMatch(content);

  if (match == null) {
    // No H1 found, skip this file
    return null;
  }

  final title = match.group(1)?.trim() ?? '';
  if (title.isEmpty) {
    return null;
  }

  // Get content after the H1 line
  final h1End = match.end;
  final body = content.substring(h1End).trim();

  return HelpTopic(
    title: title,
    content: body,
    filePath: filePath,
  );
}
