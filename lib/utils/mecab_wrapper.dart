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
  String? dictPath;

  void syncInitialize(String? path) {
    if (path == null) return;
    if (_isInitialized) return;

    final charBin = File(p.join(path, 'char.bin'));
    if (!charBin.existsSync()) {
      throw Exception('ipadic not found at $path — did you call initialize()?');
    }

    _tagger.initWithIpadicDir(path, false);
    _isInitialized = true;
  }

  /// Ensure mecab is initialized with the dictionary.
  Future<void> initialize() async {
    if (_isInitialized) return;

    final appDir = await getApplicationSupportDirectory();
    final dictDir = Directory(p.join(appDir.path, 'ipadic'));
    dictPath = dictDir.path;

    // If the dict is not yet unpacked, do it
    if (!dictDir.existsSync()) {
      await _decompressAssetTarXz('ipadic.tar.xz', appDir.path);
    }

    _tagger.initWithIpadicDir(dictPath!, false);
    _isInitialized = true;
  }

  /// Public sync segmentation method for SQLite UDF usage
  /// (ensure initialize() is awaited before using this!)
  String segment(String text) {
    if (!_isInitialized) {
      return "";
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
}
