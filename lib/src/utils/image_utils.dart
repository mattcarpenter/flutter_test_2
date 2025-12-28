import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../services/logging/app_logger.dart';

/// Utility functions for processing images for recipe extraction.
///
/// Used by the photo recipe import feature to prepare images for upload.
class ImageUtils {
  /// Maximum dimension for images sent to the API.
  /// OpenAI Vision API works well with 1024-2048px.
  static const int maxDimension = 1536;

  /// JPEG quality for compressed images.
  static const int compressionQuality = 85;

  /// Compresses and prepares a single image for upload.
  ///
  /// Returns the compressed image as bytes, or null if compression failed.
  static Future<Uint8List?> prepareImageForUpload(File imageFile) async {
    try {
      // Get a temporary path for the compressed image
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = '${directory.path}/upload_$timestamp.jpg';

      final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: compressionQuality,
        minWidth: maxDimension,
        minHeight: maxDimension,
        format: CompressFormat.jpeg,
      );

      if (compressed == null) {
        AppLogger.warning('Image compression returned null, using original');
        return await imageFile.readAsBytes();
      }

      final bytes = await File(compressed.path).readAsBytes();

      // Clean up temp file
      try {
        await File(compressed.path).delete();
      } catch (e) {
        // Ignore cleanup errors
      }

      AppLogger.debug(
        'Image prepared for upload: '
        'originalSize=${await imageFile.length()}, '
        'compressedSize=${bytes.length}',
      );

      return bytes;
    } catch (e) {
      AppLogger.error('Failed to prepare image for upload', e);
      // Fallback to original bytes
      try {
        return await imageFile.readAsBytes();
      } catch (e2) {
        AppLogger.error('Failed to read original image', e2);
        return null;
      }
    }
  }

  /// Prepares multiple images for upload.
  ///
  /// Takes at most [maxImages] (default 2) and compresses each.
  /// Returns list of compressed image bytes.
  static Future<List<Uint8List>> prepareImagesForUpload(
    List<File> images, {
    int maxImages = 2,
  }) async {
    final result = <Uint8List>[];

    // Take only first N images
    final imagesToProcess = images.take(maxImages).toList();

    for (final image in imagesToProcess) {
      final bytes = await prepareImageForUpload(image);
      if (bytes != null) {
        result.add(bytes);
      }
    }

    return result;
  }

  /// Reads image bytes directly from a file path.
  ///
  /// Used for share session images that are already saved.
  static Future<Uint8List?> readImageBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        AppLogger.warning('Image file does not exist: $filePath');
        return null;
      }
      return await file.readAsBytes();
    } catch (e) {
      AppLogger.error('Failed to read image bytes', e);
      return null;
    }
  }

  /// Prepares images from file paths (used for share session).
  ///
  /// Reads and compresses images from the given paths.
  static Future<List<Uint8List>> prepareImagesFromPaths(
    List<String> filePaths, {
    int maxImages = 2,
  }) async {
    final files = filePaths.take(maxImages).map((p) => File(p)).toList();
    return prepareImagesForUpload(files, maxImages: maxImages);
  }
}
