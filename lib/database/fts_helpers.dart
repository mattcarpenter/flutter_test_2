import 'package:porter_2_stemmer/porter_2_stemmer.dart';
import 'package:recipe_app/database/powersync.dart';
import '../utils/mecab_wrapper.dart';

/// Preprocess the search term based on language.
/// For English, it stems each word; for Japanese, it segments the text.
/// Preprocesses the input text for FTS indexing or search queries.
/// If [languageHint] is provided and equals 'ja', Japanese segmentation is used.
/// Otherwise, if not provided, the function detects Japanese characters in [input]
/// and applies TinySegmenter if needed; else it applies the Porter2 stemmer.
String tokenizeJapaneseText(String input) {
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
    return input;
  }
}
