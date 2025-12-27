import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../clients/recipe_api_client.dart';
import '../features/clippings/models/extracted_recipe.dart';
import '../features/clippings/models/recipe_preview.dart';
import 'logging/app_logger.dart';

/// Exception thrown when web extraction fails.
class WebExtractionException implements Exception {
  final String message;
  final int? statusCode;

  WebExtractionException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Service for extracting recipes from generic websites using Readability + AI.
///
/// This service sends raw HTML to the backend which uses Mozilla's Readability
/// library to extract article content, then uses OpenAI to structure the recipe.
///
/// This is the fallback when:
/// 1. The site doesn't have JSON-LD structured data
/// 2. The site isn't a known platform (Instagram, TikTok, YouTube)
class WebExtractionService {
  final RecipeApiClient _apiClient;

  WebExtractionService(this._apiClient);

  /// Extracts recipe from HTML using Readability + OpenAI (requires Plus subscription).
  ///
  /// Returns the extracted recipe or null if no recipe was found in the content.
  /// Throws [WebExtractionException] on API errors (including 401/403 for auth).
  ///
  /// [html] - The raw HTML content of the web page
  /// [sourceUrl] - Optional URL for source attribution
  Future<ExtractedRecipe?> extractRecipe({
    required String html,
    String? sourceUrl,
  }) async {
    try {
      final body = <String, dynamic>{
        'html': html,
      };
      if (sourceUrl != null && sourceUrl.isNotEmpty) {
        body['sourceUrl'] = sourceUrl;
      }

      AppLogger.info(
        'Web extract-recipe request: '
        'htmlLength=${html.length}, '
        'hasSourceUrl=${sourceUrl != null && sourceUrl.isNotEmpty}',
      );

      final response = await _apiClient.post(
        '/v1/web/extract-recipe',
        body,
        requiresAuth: true,
      );

      AppLogger.info(
        'Web extract-recipe response: '
        'statusCode=${response.statusCode}, '
        'bodyLength=${response.body.length}',
      );

      if (response.statusCode == 429) {
        throw WebExtractionException(
          'Rate limit exceeded. Please try again later.',
          statusCode: 429,
        );
      }

      if (response.statusCode == 403) {
        throw WebExtractionException(
          'Plus subscription required.',
          statusCode: 403,
        );
      }

      if (response.statusCode != 200) {
        AppLogger.warning(
          'Web extract-recipe failed: '
          'statusCode=${response.statusCode}, '
          'body=${response.body}',
        );
        throw WebExtractionException(
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
      if (e is WebExtractionException) rethrow;
      AppLogger.error('Web recipe extraction failed', e);
      throw WebExtractionException('Failed to process. Please try again.');
    }
  }

  /// Extracts recipe preview from HTML (for non-subscribers).
  ///
  /// Returns null if no recipe found.
  /// Does not require authentication but is rate limited.
  ///
  /// [html] - The raw HTML content of the web page
  /// [sourceUrl] - Optional URL for context
  Future<RecipePreview?> previewRecipe({
    required String html,
    String? sourceUrl,
  }) async {
    try {
      final body = <String, dynamic>{
        'html': html,
      };
      if (sourceUrl != null && sourceUrl.isNotEmpty) {
        body['sourceUrl'] = sourceUrl;
      }

      AppLogger.info(
        'Web preview-recipe request: '
        'htmlLength=${html.length}, '
        'hasSourceUrl=${sourceUrl != null && sourceUrl.isNotEmpty}',
      );

      final response = await _apiClient.post(
        '/v1/web/preview-recipe',
        body,
        requiresAuth: false,
      );

      AppLogger.info(
        'Web preview-recipe response: '
        'statusCode=${response.statusCode}, '
        'bodyLength=${response.body.length}',
      );

      if (response.statusCode == 429) {
        throw WebExtractionException(
          'Daily preview limit reached. Subscribe to Plus for unlimited access.',
          statusCode: 429,
        );
      }

      if (response.statusCode != 200) {
        AppLogger.warning(
          'Web preview-recipe failed: '
          'statusCode=${response.statusCode}, '
          'body=${response.body}',
        );
        throw WebExtractionException(
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
      if (e is WebExtractionException) rethrow;
      AppLogger.error('Web recipe preview failed', e);
      throw WebExtractionException('Failed to process. Please try again.');
    }
  }
}

/// Provider for the WebExtractionService.
///
/// Uses RecipeApiClient for automatic HMAC request signing.
final webExtractionServiceProvider = Provider<WebExtractionService>((ref) {
  final apiClient = ref.watch(recipeApiClientProvider);
  return WebExtractionService(apiClient);
});
