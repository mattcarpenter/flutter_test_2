import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:mecab_dart/mecab_dart.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';

class MecabWrapper {
  static final MecabWrapper _instance = MecabWrapper._internal();

  factory MecabWrapper() => _instance;

  MecabWrapper._internal();

  final Mecab _tagger = Mecab();
  bool _isInitialized = false;
  String? _dictPath;

  /// Ensure mecab is initialized with the dictionary.
  Future<void> initialize() async {
    if (_isInitialized) return;

    final appDir = await getApplicationSupportDirectory();
    final dictDir = Directory(p.join(appDir.path, 'ipadic'));
    _dictPath = dictDir.path;

    // If the dict is not yet unpacked, do it
    if (!dictDir.existsSync()) {
      await _decompressAssetTarXz('ipadic.tar.xz', appDir.path);
    }

    _tagger.initWithIpadicDir(_dictPath!, false);
    _isInitialized = true;
  }

  /// Public sync segmentation method for SQLite UDF usage
  /// (ensure initialize() is awaited before using this!)
  String segment(String text) {
    if (!_isInitialized) {
      return text;
    }

    final tokens = _tagger.parse(text);
    return tokens.map((t) => t.surface).toList().join(" ");
  }

  /// Decompress the .tar.xz asset to the given directory
  Future<void> _decompressAssetTarXz(String assetPath, String outputDir) async {
    // Load asset into memory
    final byteData = await rootBundle.load("assets/$assetPath");
    final xzBytes = byteData.buffer.asUint8List();

    // Decode .xz to get the .tar file bytes
    final tarBytes = XZDecoder().decodeBytes(xzBytes);

    // Decode the .tar contents
    final archive = TarDecoder().decodeBytes(tarBytes);


    for (final file in archive) {
      final filePath = p.join(outputDir, file.name);
      if (file.isFile) {
        final outFile = File(filePath)..createSync(recursive: true);
        outFile.writeAsBytesSync(file.content as List<int>);
      } else {
        Directory(filePath).createSync(recursive: true);
      }
    }
  }

  String tokenizeJapaneseText(String input) {
    input = input.trim();
    if (input.isEmpty) return '';

    bool containsJapanese = input.runes.any((int rune) {
      return (rune >= 0x3040 && rune <= 0x309F) || // Hiragana
          (rune >= 0x30A0 && rune <= 0x30FF) || // Katakana
          (rune >= 0x4E00 && rune <= 0x9FBF);   // Kanji
    });

    if (containsJapanese) {
      return segment(input);
    } else {
      return input.trim();
    }
  }
}
