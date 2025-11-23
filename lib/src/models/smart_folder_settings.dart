import 'dart:convert';

/// Represents the settings for a smart folder
class SmartFolderSettings {
  final List<String> tags;    // Tag names for tag-based folders
  final List<String> terms;   // Ingredient terms for ingredient-based folders
  final bool matchAll;        // true = AND logic, false = OR logic

  const SmartFolderSettings({
    this.tags = const [],
    this.terms = const [],
    this.matchAll = false,
  });

  /// Create from folder entry data
  factory SmartFolderSettings.fromFolderEntry({
    String? smartFilterTags,
    String? smartFilterTerms,
    int filterLogic = 0,
  }) {
    List<String> parseTags = [];
    List<String> parseTerms = [];

    if (smartFilterTags != null && smartFilterTags.isNotEmpty) {
      parseTags = (jsonDecode(smartFilterTags) as List).cast<String>();
    }
    if (smartFilterTerms != null && smartFilterTerms.isNotEmpty) {
      parseTerms = (jsonDecode(smartFilterTerms) as List).cast<String>();
    }

    return SmartFolderSettings(
      tags: parseTags,
      terms: parseTerms,
      matchAll: filterLogic == 1,
    );
  }

  String get tagsJson => jsonEncode(tags);
  String get termsJson => jsonEncode(terms);
  int get filterLogicValue => matchAll ? 1 : 0;
}
