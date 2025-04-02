bool containsJapanese(String input) {
  return input.runes.any((int rune) =>
  (rune >= 0x3040 && rune <= 0x309F) || // Hiragana
      (rune >= 0x30A0 && rune <= 0x30FF) || // Katakana
      (rune >= 0x4E00 && rune <= 0x9FBF));  // Kanji
}
