import 'package:porter_2_stemmer/porter_2_stemmer.dart';
import 'package:recipe_app/database/powersync.dart';
import '../utils/mecab_wrapper.dart';
import '../utils/tiny_segmenter.dart'; // for accessing "db"

final Porter2Stemmer _stemmer = Porter2Stemmer();
final TinySegmenter _segmenter = TinySegmenter();

/// Preprocess the search term based on language.
/// For English, it stems each word; for Japanese, it segments the text.
/// Preprocesses the input text for FTS indexing or search queries.
/// If [languageHint] is provided and equals 'ja', Japanese segmentation is used.
/// Otherwise, if not provided, the function detects Japanese characters in [input]
/// and applies TinySegmenter if needed; else it applies the Porter2 stemmer.
String preprocessText(String input) {
  input = input.trim();
  if (input.isEmpty) return '';

  bool containsJapanese = input.runes.any((int rune) {
    return (rune >= 0x3040 && rune <= 0x309F) || // Hiragana
        (rune >= 0x30A0 && rune <= 0x30FF) || // Katakana
        (rune >= 0x4E00 && rune <= 0x9FBF);   // Kanji
  });

  if (containsJapanese) {
    return MecabWrapper().segment(input);
  } else {
    return input
        .split(RegExp(r'\s+'))
        .map((word) => _stemmer.stem(word))
        .join(' ')
        .trim();
  }
}

/// Create a search term with trailing wildcard(s) for FTS queries.
/// This ensures that a partial word search (e.g. "onions" → "onion")
/// can match tokens in the FTS index.
String _createSearchTermWithOptions(String searchTerm) {
  String processed = preprocessText(searchTerm);
  return '$processed*';
}

/// Search the FTS table for the given search term.
/// [language] can be set to 'ja' for Japanese processing; defaults to 'en'.
Future<List> search(String searchTerm, String tableName) async {
  String searchTermWithOptions = _createSearchTermWithOptions(searchTerm);
  return await db.getAll(
    'SELECT * FROM fts_$tableName WHERE fts_$tableName MATCH ? ORDER BY rank',
    [searchTermWithOptions],
  );
}
