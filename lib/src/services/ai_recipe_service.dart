import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../clients/recipe_api_client.dart';
import '../features/clippings/models/extracted_recipe.dart';
import '../features/clippings/models/recipe_preview.dart';
import '../features/recipes/models/recipe_idea.dart';
import 'logging/app_logger.dart';

/// Exception thrown when AI recipe operations fail
class AiRecipeException implements Exception {
  final String message;
  final int? statusCode;
  final bool isRateLimitError;

  AiRecipeException(
    this.message, {
    this.statusCode,
    this.isRateLimitError = false,
  });

  @override
  String toString() => message;
}

/// Result of a brainstorming request
class BrainstormResult {
  final bool success;
  final List<RecipeIdea> ideas;
  final String? errorMessage;

  const BrainstormResult({
    required this.success,
    this.ideas = const [],
    this.errorMessage,
  });
}

/// Result of a recipe generation request
class GenerateResult {
  final bool success;
  final ExtractedRecipe? recipe;
  final String? errorMessage;

  const GenerateResult({
    required this.success,
    this.recipe,
    this.errorMessage,
  });
}

/// Result of a preview generation request
class PreviewGenerateResult {
  final bool success;
  final RecipePreview? preview;
  final String? errorMessage;

  const PreviewGenerateResult({
    required this.success,
    this.preview,
    this.errorMessage,
  });
}

/// Service for AI-powered recipe generation.
///
/// This service provides:
/// - Brainstorming recipe ideas from user prompts
/// - Generating full recipes from selected ideas (Plus required)
/// - Generating recipe previews for non-Plus users
///
/// Uses the RecipeApiClient which handles HMAC request signing.
class AiRecipeService {
  final RecipeApiClient _apiClient;

  AiRecipeService(this._apiClient);

  /// Brainstorm recipe ideas based on user prompt.
  ///
  /// [prompt] - User's description of what they want to eat
  /// [pantryItems] - Optional list of available ingredients to incorporate
  ///
  /// Returns a [BrainstormResult] with success flag and list of ideas.
  /// Free users are limited to 10/day; Plus users have unlimited access.
  Future<BrainstormResult> brainstormRecipes({
    required String prompt,
    List<String>? pantryItems,
  }) async {
    try {
      final body = <String, dynamic>{
        'prompt': prompt,
        if (pantryItems != null && pantryItems.isNotEmpty)
          'pantryItems': pantryItems,
      };

      final response = await _apiClient.post(
        '/v1/ai-recipes/brainstorm',
        body,
        requiresAuth: true, // Optional auth for rate limit skip
      );

      if (response.statusCode == 429) {
        throw AiRecipeException(
          'Daily idea generation limit reached. Upgrade to Plus for unlimited access.',
          statusCode: 429,
          isRateLimitError: true,
        );
      }

      if (response.statusCode != 200) {
        throw AiRecipeException(
          'Failed to generate ideas: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] != true) {
        return BrainstormResult(
          success: false,
          errorMessage: data['message'] as String? ??
              "Couldn't generate recipe ideas. Try being more specific.",
        );
      }

      final ideasList = data['ideas'] as List<dynamic>? ?? [];
      final ideas = ideasList
          .map((e) => RecipeIdea.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.info('Brainstorm successful', {
        'ideaCount': ideas.length,
        'promptLength': prompt.length,
        'hasPantryItems': pantryItems?.isNotEmpty ?? false,
      });

      return BrainstormResult(
        success: true,
        ideas: ideas,
      );
    } on AiRecipeException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('Brainstorm failed', e, stack);
      throw AiRecipeException('Failed to generate ideas. Please try again.');
    }
  }

  /// Generate a full recipe from a selected idea (requires Plus subscription).
  ///
  /// [idea] - The selected recipe idea
  /// [originalPrompt] - Optional original user prompt for context
  /// [pantryItems] - Optional list of ingredients to prefer
  ///
  /// Returns a [GenerateResult] with the full recipe.
  /// Throws [AiRecipeException] with statusCode 403 if Plus is required.
  Future<GenerateResult> generateRecipe({
    required RecipeIdea idea,
    String? originalPrompt,
    List<String>? pantryItems,
  }) async {
    try {
      final body = <String, dynamic>{
        'ideaId': idea.id,
        'ideaTitle': idea.title,
        'ideaDescription': idea.description,
        if (originalPrompt != null) 'originalPrompt': originalPrompt,
        if (pantryItems != null && pantryItems.isNotEmpty)
          'pantryItems': pantryItems,
      };

      final response = await _apiClient.post(
        '/v1/ai-recipes/generate',
        body,
        requiresAuth: true,
      );

      if (response.statusCode == 403) {
        throw AiRecipeException(
          'Plus subscription required',
          statusCode: 403,
        );
      }

      if (response.statusCode == 429) {
        throw AiRecipeException(
          'Too many requests. Please wait a moment.',
          statusCode: 429,
          isRateLimitError: true,
        );
      }

      if (response.statusCode != 200) {
        throw AiRecipeException(
          'Failed to generate recipe: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] != true) {
        return GenerateResult(
          success: false,
          errorMessage: data['message'] as String? ??
              'Unable to generate recipe. Please try another idea.',
        );
      }

      final recipeJson = data['recipe'] as Map<String, dynamic>;
      final recipe = ExtractedRecipe.fromJson(recipeJson);

      AppLogger.info('Recipe generation successful', {
        'ideaId': idea.id,
        'ingredientCount': recipe.ingredients.length,
        'stepCount': recipe.steps.length,
      });

      return GenerateResult(
        success: true,
        recipe: recipe,
      );
    } on AiRecipeException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('Recipe generation failed', e, stack);
      throw AiRecipeException('Failed to generate recipe. Please try again.');
    }
  }

  /// Generate a recipe preview from a selected idea (for non-Plus users).
  ///
  /// [idea] - The selected recipe idea
  ///
  /// Returns a [PreviewGenerateResult] with title, description, and first 4 ingredients.
  /// Does not require authentication.
  Future<PreviewGenerateResult> generatePreview({
    required RecipeIdea idea,
  }) async {
    try {
      final body = <String, dynamic>{
        'ideaTitle': idea.title,
        'ideaDescription': idea.description,
      };

      final response = await _apiClient.post(
        '/v1/ai-recipes/preview-generate',
        body,
        requiresAuth: false,
      );

      if (response.statusCode == 429) {
        throw AiRecipeException(
          'Daily preview limit reached. Subscribe to Plus for unlimited access.',
          statusCode: 429,
          isRateLimitError: true,
        );
      }

      if (response.statusCode != 200) {
        throw AiRecipeException(
          'Failed to generate preview: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] != true) {
        return PreviewGenerateResult(
          success: false,
          errorMessage: data['message'] as String? ??
              'Unable to generate preview.',
        );
      }

      final previewJson = data['preview'] as Map<String, dynamic>;
      final preview = RecipePreview.fromJson(previewJson);

      AppLogger.info('Preview generation successful');

      return PreviewGenerateResult(
        success: true,
        preview: preview,
      );
    } on AiRecipeException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('Preview generation failed', e, stack);
      throw AiRecipeException('Failed to generate preview. Please try again.');
    }
  }
}

/// Provider for the AiRecipeService.
///
/// Uses RecipeApiClient for automatic HMAC request signing.
final aiRecipeServiceProvider = Provider<AiRecipeService>((ref) {
  final apiClient = ref.watch(recipeApiClientProvider);
  return AiRecipeService(apiClient);
});
