import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../clients/recipe_api_client.dart';
import '../features/clippings/models/extracted_recipe.dart';
import '../features/clippings/models/extracted_shopping_item.dart';
import 'logging/app_logger.dart';

/// Exception thrown when clipping extraction fails
class ClippingExtractionException implements Exception {
  final String message;
  final int? statusCode;

  ClippingExtractionException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Service for extracting structured data from clipping text using AI.
///
/// This service uses the RecipeApiClient which handles HMAC request signing.
class ClippingExtractionService {
  final RecipeApiClient _apiClient;

  ClippingExtractionService(this._apiClient);

  /// Extracts recipe data from clipping text.
  ///
  /// Returns the extracted recipe or null if no recipe was found in the text.
  /// Throws [ClippingExtractionException] on API errors.
  Future<ExtractedRecipe?> extractRecipe({
    required String title,
    required String body,
  }) async {
    try {
      final response = await _apiClient.post(
        '/v1/clippings/extract-recipe',
        {'title': title, 'body': body},
      );

      if (response.statusCode == 429) {
        throw ClippingExtractionException(
          'Rate limit exceeded. Please try again later.',
          statusCode: 429,
        );
      }

      if (response.statusCode != 200) {
        throw ClippingExtractionException(
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
      if (e is ClippingExtractionException) rethrow;
      AppLogger.error('Recipe extraction failed', e);
      throw ClippingExtractionException('Failed to process. Please try again.');
    }
  }

  /// Extracts shopping list items from clipping text.
  ///
  /// Returns the extracted items (already canonicalized with terms and categories).
  /// Returns an empty list if no items were found.
  /// Throws [ClippingExtractionException] on API errors.
  Future<List<ExtractedShoppingItem>> extractShoppingList({
    required String title,
    required String body,
  }) async {
    try {
      final response = await _apiClient.post(
        '/v1/clippings/extract-shopping-list',
        {'title': title, 'body': body},
      );

      if (response.statusCode == 429) {
        throw ClippingExtractionException(
          'Rate limit exceeded. Please try again later.',
          statusCode: 429,
        );
      }

      if (response.statusCode != 200) {
        throw ClippingExtractionException(
          'Failed to extract shopping list: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] != true || data['items'] == null) {
        // No items found - return empty list
        return [];
      }

      final itemsList = data['items'] as List<dynamic>;
      return itemsList
          .map((item) => ExtractedShoppingItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ClippingExtractionException) rethrow;
      AppLogger.error('Shopping list extraction failed', e);
      throw ClippingExtractionException('Failed to process. Please try again.');
    }
  }
}

/// Provider for the ClippingExtractionService.
///
/// Uses RecipeApiClient for automatic HMAC request signing.
final clippingExtractionServiceProvider = Provider<ClippingExtractionService>((ref) {
  final apiClient = ref.watch(recipeApiClientProvider);
  return ClippingExtractionService(apiClient);
});
