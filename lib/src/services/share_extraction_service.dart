import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../clients/recipe_api_client.dart';
import '../features/clippings/models/extracted_recipe.dart';
import '../features/clippings/models/recipe_preview.dart';
import 'ingredient_canonicalization_service.dart' show getCurrentLocale;
import 'logging/app_logger.dart';

/// Exception thrown when share extraction fails
class ShareExtractionException implements Exception {
  final String message;
  final int? statusCode;

  ShareExtractionException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Service for extracting recipes from shared social media content using AI.
///
/// This service uses the RecipeApiClient which handles HMAC request signing.
/// It hits the /v1/share endpoints which are separate from clipping extraction.
class ShareExtractionService {
  final RecipeApiClient _apiClient;

  ShareExtractionService(this._apiClient);

  /// Extracts recipe data from shared content (requires Plus subscription).
  ///
  /// Returns the extracted recipe or null if no recipe was found in the content.
  /// Throws [ShareExtractionException] on API errors (including 401/403 for auth).
  Future<ExtractedRecipe?> extractRecipe({
    String? ogTitle,
    String? ogDescription,
    String? sourceUrl,
    String? sourcePlatform,
  }) async {
    try {
      final locale = getCurrentLocale();
      final body = <String, dynamic>{
        'locale': locale,
      };
      if (ogTitle != null && ogTitle.isNotEmpty) {
        body['ogTitle'] = ogTitle;
      }
      if (ogDescription != null && ogDescription.isNotEmpty) {
        body['ogDescription'] = ogDescription;
      }
      if (sourceUrl != null && sourceUrl.isNotEmpty) {
        body['sourceUrl'] = sourceUrl;
      }
      if (sourcePlatform != null && sourcePlatform.isNotEmpty) {
        body['sourcePlatform'] = sourcePlatform;
      }

      AppLogger.info(
        'Share extract-recipe request: '
        'ogTitleLength=${ogTitle?.length ?? 0}, '
        'ogDescriptionLength=${ogDescription?.length ?? 0}, '
        'hasSourceUrl=${sourceUrl != null && sourceUrl.isNotEmpty}, '
        'sourcePlatform=$sourcePlatform',
      );

      final response = await _apiClient.post(
        '/v1/share/extract-recipe',
        body,
        requiresAuth: true,
      );

      AppLogger.info(
        'Share extract-recipe response: '
        'statusCode=${response.statusCode}, '
        'bodyLength=${response.body.length}',
      );

      if (response.statusCode == 429) {
        throw ShareExtractionException(
          'Rate limit exceeded. Please try again later.',
          statusCode: 429,
        );
      }

      if (response.statusCode != 200) {
        AppLogger.warning(
          'Share extract-recipe failed: '
          'statusCode=${response.statusCode}, '
          'body=${response.body}',
        );
        throw ShareExtractionException(
          'Failed to extract recipe: ${response.statusCode}',
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
      if (e is ShareExtractionException) rethrow;
      AppLogger.error('Share recipe extraction failed', e);
      throw ShareExtractionException('Failed to process. Please try again.');
    }
  }

  /// Extracts recipe preview from shared content (for non-subscribers).
  ///
  /// Returns null if no recipe found.
  /// Does not require authentication.
  Future<RecipePreview?> previewRecipe({
    String? ogTitle,
    String? ogDescription,
    String? sourceUrl,
    String? sourcePlatform,
  }) async {
    try {
      final locale = getCurrentLocale();
      final body = <String, dynamic>{
        'locale': locale,
      };
      if (ogTitle != null && ogTitle.isNotEmpty) {
        body['ogTitle'] = ogTitle;
      }
      if (ogDescription != null && ogDescription.isNotEmpty) {
        body['ogDescription'] = ogDescription;
      }
      if (sourceUrl != null && sourceUrl.isNotEmpty) {
        body['sourceUrl'] = sourceUrl;
      }
      if (sourcePlatform != null && sourcePlatform.isNotEmpty) {
        body['sourcePlatform'] = sourcePlatform;
      }

      AppLogger.info(
        'Share preview-recipe request: '
        'ogTitleLength=${ogTitle?.length ?? 0}, '
        'ogDescriptionLength=${ogDescription?.length ?? 0}, '
        'hasSourceUrl=${sourceUrl != null && sourceUrl.isNotEmpty}, '
        'sourcePlatform=$sourcePlatform',
      );

      final response = await _apiClient.post(
        '/v1/share/preview-recipe',
        body,
        requiresAuth: false,
      );

      AppLogger.info(
        'Share preview-recipe response: '
        'statusCode=${response.statusCode}, '
        'bodyLength=${response.body.length}',
      );

      if (response.statusCode == 429) {
        throw ShareExtractionException(
          'Daily preview limit reached. Subscribe to Plus for unlimited access.',
          statusCode: 429,
        );
      }

      if (response.statusCode != 200) {
        AppLogger.warning(
          'Share preview-recipe failed: '
          'statusCode=${response.statusCode}, '
          'body=${response.body}',
        );
        throw ShareExtractionException(
          'Failed to preview recipe: ${response.statusCode}',
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
      if (e is ShareExtractionException) rethrow;
      AppLogger.error('Share recipe preview failed', e);
      throw ShareExtractionException('Failed to process. Please try again.');
    }
  }
}

/// Provider for the ShareExtractionService.
///
/// Uses RecipeApiClient for automatic HMAC request signing.
final shareExtractionServiceProvider = Provider<ShareExtractionService>((ref) {
  final apiClient = ref.watch(recipeApiClientProvider);
  return ShareExtractionService(apiClient);
});
