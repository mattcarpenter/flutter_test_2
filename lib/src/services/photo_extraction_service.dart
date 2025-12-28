import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app_config.dart';
import '../features/clippings/models/extracted_recipe.dart';
import '../features/clippings/models/recipe_preview.dart';
import 'api_signer.dart';
import 'logging/app_logger.dart';

/// Exception thrown when photo extraction fails
class PhotoExtractionException implements Exception {
  final String message;
  final int? statusCode;

  PhotoExtractionException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Service for extracting recipes from photos using AI vision.
///
/// This service handles multipart image uploads to the /v1/photo endpoints.
/// Uses a different signing approach (MULTIPART placeholder) since the body
/// is streamed rather than hashed.
class PhotoExtractionService {
  final String _baseUrl;

  PhotoExtractionService(this._baseUrl);

  /// Extracts recipe data from photo(s) (requires Plus subscription).
  ///
  /// [images] - List of image bytes (max 2 images for multi-page recipes)
  /// [hint] - Optional hint: 'recipe' or 'dish' (usually null to let AI decide)
  ///
  /// Returns the extracted recipe or null if no recipe was found.
  /// Throws [PhotoExtractionException] on API errors (including 403 for auth).
  Future<ExtractedRecipe?> extractRecipe({
    required List<Uint8List> images,
    String? hint,
  }) async {
    const path = '/v1/photo/extract-recipe';

    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'));

      // Add images as multipart files
      for (var i = 0; i < images.length; i++) {
        request.files.add(http.MultipartFile.fromBytes(
          'images',
          images[i],
          filename: 'image_$i.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      // Add hint if provided
      if (hint != null) {
        request.fields['hint'] = hint;
      }

      // Add HMAC signature headers for multipart
      final signatureHeaders = ApiSigner.signMultipart('POST', path);
      request.headers.addAll(signatureHeaders);

      // Add auth header (required for full extraction)
      final token = _getAuthToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      AppLogger.info(
        'Photo extract-recipe request: '
        'imageCount=${images.length}, '
        'totalSize=${images.fold<int>(0, (sum, img) => sum + img.length)}',
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      AppLogger.info(
        'Photo extract-recipe response: '
        'statusCode=${response.statusCode}, '
        'bodyLength=${response.body.length}',
      );

      if (response.statusCode == 429) {
        throw PhotoExtractionException(
          'Daily limit reached. Please try again tomorrow.',
          statusCode: 429,
        );
      }

      if (response.statusCode == 403) {
        throw PhotoExtractionException(
          'Plus subscription required',
          statusCode: 403,
        );
      }

      if (response.statusCode == 401) {
        throw PhotoExtractionException(
          'Authentication required',
          statusCode: 401,
        );
      }

      if (response.statusCode != 200) {
        AppLogger.warning(
          'Photo extract-recipe failed: '
          'statusCode=${response.statusCode}, '
          'body=${response.body}',
        );
        throw PhotoExtractionException(
          'Failed to process photo: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] != true) {
        // No recipe found - this is not an error, just empty result
        return null;
      }

      final recipeJson = data['recipe'] as Map<String, dynamic>;
      return ExtractedRecipe.fromJson(recipeJson);
    } catch (e) {
      if (e is PhotoExtractionException) rethrow;
      AppLogger.error('Photo recipe extraction failed', e);
      throw PhotoExtractionException('Failed to process photo. Please try again.');
    }
  }

  /// Extracts recipe preview from photo(s) (for non-subscribers).
  ///
  /// [images] - List of image bytes (max 2 images)
  /// [hint] - Optional hint: 'recipe' or 'dish'
  ///
  /// Returns null if no recipe found.
  /// Does not require authentication but is rate-limited (2/day).
  Future<RecipePreview?> previewRecipe({
    required List<Uint8List> images,
    String? hint,
  }) async {
    const path = '/v1/photo/preview-recipe';

    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'));

      // Add images as multipart files
      for (var i = 0; i < images.length; i++) {
        request.files.add(http.MultipartFile.fromBytes(
          'images',
          images[i],
          filename: 'image_$i.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      // Add hint if provided
      if (hint != null) {
        request.fields['hint'] = hint;
      }

      // Add HMAC signature headers for multipart
      final signatureHeaders = ApiSigner.signMultipart('POST', path);
      request.headers.addAll(signatureHeaders);

      AppLogger.info(
        'Photo preview-recipe request: '
        'imageCount=${images.length}, '
        'totalSize=${images.fold<int>(0, (sum, img) => sum + img.length)}',
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      AppLogger.info(
        'Photo preview-recipe response: '
        'statusCode=${response.statusCode}, '
        'bodyLength=${response.body.length}',
      );

      if (response.statusCode == 429) {
        throw PhotoExtractionException(
          'Daily photo import limit reached. Subscribe to Plus for unlimited access.',
          statusCode: 429,
        );
      }

      if (response.statusCode != 200) {
        AppLogger.warning(
          'Photo preview-recipe failed: '
          'statusCode=${response.statusCode}, '
          'body=${response.body}',
        );
        throw PhotoExtractionException(
          'Failed to preview photo: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] != true) {
        return null;
      }

      final previewJson = data['preview'] as Map<String, dynamic>;
      return RecipePreview.fromJson(previewJson);
    } catch (e) {
      if (e is PhotoExtractionException) rethrow;
      AppLogger.error('Photo recipe preview failed', e);
      throw PhotoExtractionException('Failed to process photo. Please try again.');
    }
  }

  /// Gets the current Supabase session token.
  String? _getAuthToken() {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.accessToken;
  }
}

/// Provider for the PhotoExtractionService.
final photoExtractionServiceProvider = Provider<PhotoExtractionService>((ref) {
  return PhotoExtractionService(AppConfig.ingredientApiUrl);
});
