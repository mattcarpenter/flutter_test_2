import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/help_topic.dart';

/// Section definitions in display order.
/// Maps folder key to localization key suffix.
const _sectionFolderKeys = [
  'adding-recipes',
  'quick-questions',
  'learn-more',
  'troubleshooting',
];

/// Provider that loads and parses all help topics from asset markdown files.
/// Takes a locale code (e.g., 'en', 'ja') as a family parameter.
final helpTopicsProvider = FutureProvider.family<List<HelpSection>, String>((ref, localeCode) async {
  final sections = <HelpSection>[];

  // Load asset manifest using modern API (supports both JSON and binary formats)
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

  for (final folderKey in _sectionFolderKeys) {
    final prefix = 'assets/docs/$localeCode/$folderKey/';
    final fallbackPrefix = 'assets/docs/en/$folderKey/';
    final topics = <HelpTopic>[];

    // Find all markdown files in this section's folder
    final allAssets = manifest.listAssets();
    var sectionFiles = allAssets
        .where((path) => path.startsWith(prefix) && path.endsWith('.md'))
        .toList();

    // If no files found for this locale, fall back to English
    if (sectionFiles.isEmpty && localeCode != 'en') {
      sectionFiles = allAssets
          .where((path) => path.startsWith(fallbackPrefix) && path.endsWith('.md'))
          .toList();
    }

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
      name: '', // Name will be set by the UI using localized strings
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
