import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../features/clippings/models/extracted_recipe.dart';
import '../../features/clippings/models/recipe_preview.dart';
import '../logging/app_logger.dart';
import '../web_extraction_service.dart';
import 'json_ld_parser.dart';

/// How the recipe was extracted.
enum WebExtractionSource {
  /// Parsed from JSON-LD schema.org data (free, local, no API call)
  jsonLdSchema,

  /// Extracted via backend Readability + OpenAI (requires Plus)
  backendReadability,
}

/// Result of a web extraction attempt.
class WebExtractionResult {
  /// The full extracted recipe (available if extraction succeeded with Plus)
  final ExtractedRecipe? recipe;

  /// The preview recipe (available for non-Plus users)
  final RecipePreview? preview;

  /// How the recipe was extracted
  final WebExtractionSource? source;

  /// Error message if extraction failed
  final String? error;

  /// The HTML content (for potential retry or backend fallback)
  final String? html;

  /// The source URL
  final String? sourceUrl;

  /// The recipe image URL (from JSON-LD or og:image fallback)
  final String? imageUrl;

  const WebExtractionResult({
    this.recipe,
    this.preview,
    this.source,
    this.error,
    this.html,
    this.sourceUrl,
    this.imageUrl,
  });

  /// Whether extraction produced a usable result
  bool get success => recipe != null || preview != null;

  /// Whether we have HTML that can be sent to the backend
  bool get hasHtml => html != null && html!.isNotEmpty;

  /// Whether this was extracted from JSON-LD (free, local)
  bool get isFromJsonLd => source == WebExtractionSource.jsonLdSchema;

  /// Whether this was extracted from the backend (requires Plus)
  bool get isFromBackend => source == WebExtractionSource.backendReadability;
}

/// Extracts recipes from generic websites using a two-tier strategy:
///
/// 1. **JSON-LD Schema** (client-side, free): Many recipe sites have structured
///    data that can be parsed locally without any API call.
///
/// 2. **Backend Readability + OpenAI** (server-side, Plus required): For sites
///    without structured data, we send the HTML to the backend which uses
///    Mozilla's Readability to extract content and OpenAI to structure the recipe.
///
/// This class supports two input modes:
/// - **URL-based**: Fetches HTML from a URL (for share flow)
/// - **HTML-based**: Processes provided HTML directly (for embedded browser)
class GenericWebExtractor {
  /// Timeout for fetching HTML from URL
  static const Duration fetchTimeout = Duration(seconds: 10);

  /// User agent for HTTP requests
  static const String userAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) '
      'Version/17.0 Mobile/15E148 Safari/604.1';

  final JsonLdRecipeParser _jsonLdParser = JsonLdRecipeParser();

  /// Fetches HTML from [url] and attempts to extract a recipe.
  ///
  /// The extraction process:
  /// 1. Fetch HTML from URL (10 second timeout)
  /// 2. Try to parse JSON-LD schema (free, instant)
  /// 3. If no schema, return result with HTML for backend fallback
  ///
  /// Returns [WebExtractionResult] with either:
  /// - A recipe from JSON-LD (success, no backend needed)
  /// - HTML content for backend extraction (needs Plus)
  /// - An error if fetching failed
  Future<WebExtractionResult> extractFromUrl(Uri url) async {
    AppLogger.info('GenericWebExtractor: Fetching HTML from URL');

    String? html;
    try {
      html = await _fetchHtml(url);
    } catch (e) {
      AppLogger.warning('GenericWebExtractor: Failed to fetch HTML: $e');
      return WebExtractionResult(
        error: 'Could not load the page. Please try again.',
        sourceUrl: url.toString(),
      );
    }

    if (html == null || html.isEmpty) {
      return WebExtractionResult(
        error: 'The page returned no content.',
        sourceUrl: url.toString(),
      );
    }

    return extractFromHtml(html, sourceUrl: url.toString());
  }

  /// Attempts to extract a recipe from provided HTML.
  ///
  /// This method is useful when HTML is already available, such as from
  /// an embedded browser.
  ///
  /// The extraction process:
  /// 1. Try to parse JSON-LD schema (free, instant)
  /// 2. If found, return the recipe immediately
  /// 3. If not found, return result with HTML for backend fallback
  /// 4. Always try to extract image (JSON-LD first, then og:image fallback)
  Future<WebExtractionResult> extractFromHtml(
    String html, {
    String? sourceUrl,
  }) async {
    AppLogger.info(
      'GenericWebExtractor: Processing HTML '
      '(length=${html.length}, hasUrl=${sourceUrl != null})',
    );

    // Step 1: Try JSON-LD schema parsing (free, local)
    final recipe = _jsonLdParser.parse(html);

    // Step 2: Extract image URL (JSON-LD image takes priority, fallback to og:image)
    String? imageUrl = recipe?.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = _extractOgImage(html);
    }

    if (recipe != null) {
      AppLogger.info(
        'GenericWebExtractor: Found recipe in JSON-LD schema '
        '(title=${recipe.title}, ingredients=${recipe.ingredients.length}, '
        'hasImage=${imageUrl != null})',
      );

      return WebExtractionResult(
        recipe: recipe,
        source: WebExtractionSource.jsonLdSchema,
        html: html,
        sourceUrl: sourceUrl,
        imageUrl: imageUrl,
      );
    }

    // Step 3: No JSON-LD found - return HTML for backend extraction
    AppLogger.info(
      'GenericWebExtractor: No JSON-LD schema found, '
      'HTML available for backend extraction '
      '(hasImage=${imageUrl != null})',
    );

    return WebExtractionResult(
      html: html,
      sourceUrl: sourceUrl,
      imageUrl: imageUrl, // og:image for use after backend extraction
      // No recipe yet - caller should use WebExtractionService for backend
    );
  }

  /// Extracts og:image URL from HTML meta tags.
  ///
  /// Checks for:
  /// 1. og:image meta tag
  /// 2. twitter:image meta tag (fallback)
  String? _extractOgImage(String html) {
    // Try og:image first
    final ogPattern = RegExp(
      '<meta[^>]*property=["\']og:image["\'][^>]*content=["\']([^"\']+)["\']',
      caseSensitive: false,
    );
    var match = ogPattern.firstMatch(html);
    if (match != null) {
      final url = match.group(1)?.trim();
      if (url != null && url.isNotEmpty) {
        AppLogger.debug('GenericWebExtractor: Found og:image');
        return url;
      }
    }

    // Also try content before property (some sites have reversed order)
    final ogPatternReversed = RegExp(
      '<meta[^>]*content=["\']([^"\']+)["\'][^>]*property=["\']og:image["\']',
      caseSensitive: false,
    );
    match = ogPatternReversed.firstMatch(html);
    if (match != null) {
      final url = match.group(1)?.trim();
      if (url != null && url.isNotEmpty) {
        AppLogger.debug('GenericWebExtractor: Found og:image (reversed)');
        return url;
      }
    }

    // Fallback to twitter:image
    final twitterPattern = RegExp(
      '<meta[^>]*name=["\']twitter:image["\'][^>]*content=["\']([^"\']+)["\']',
      caseSensitive: false,
    );
    match = twitterPattern.firstMatch(html);
    if (match != null) {
      final url = match.group(1)?.trim();
      if (url != null && url.isNotEmpty) {
        AppLogger.debug('GenericWebExtractor: Found twitter:image');
        return url;
      }
    }

    // Also try reversed for twitter
    final twitterPatternReversed = RegExp(
      '<meta[^>]*content=["\']([^"\']+)["\'][^>]*name=["\']twitter:image["\']',
      caseSensitive: false,
    );
    match = twitterPatternReversed.firstMatch(html);
    if (match != null) {
      final url = match.group(1)?.trim();
      if (url != null && url.isNotEmpty) {
        AppLogger.debug('GenericWebExtractor: Found twitter:image (reversed)');
        return url;
      }
    }

    return null;
  }

  /// Extracts just a preview from the HTML using JSON-LD.
  ///
  /// This is useful for showing a preview without making any API calls.
  /// Returns null if no JSON-LD recipe schema is found.
  RecipePreview? extractPreviewFromHtml(String html) {
    return _jsonLdParser.parsePreview(html);
  }

  /// Checks if a URL is likely a recipe page based on URL patterns.
  ///
  /// This is a heuristic check that can be used to show UI hints
  /// or prioritize extraction attempts.
  bool isLikelyRecipePage(Uri url) {
    final path = url.path.toLowerCase();
    final host = url.host.toLowerCase();

    // Check path for recipe-related keywords
    final recipeKeywords = [
      '/recipe',
      '/recipes',
      '/rezept',
      '/recette',
      '/ricetta',
    ];

    for (final keyword in recipeKeywords) {
      if (path.contains(keyword)) {
        return true;
      }
    }

    // Check for known recipe sites
    final recipeSites = [
      'allrecipes.com',
      'foodnetwork.com',
      'epicurious.com',
      'bonappetit.com',
      'seriouseats.com',
      'food52.com',
      'tasty.co',
      'delish.com',
      'simplyrecipes.com',
      'cookinglight.com',
      'food.com',
      'yummly.com',
      'cooking.nytimes.com',
    ];

    for (final site in recipeSites) {
      if (host.contains(site)) {
        return true;
      }
    }

    return false;
  }

  /// Fetches HTML content from a URL.
  Future<String?> _fetchHtml(Uri url) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', url);
      request.headers['User-Agent'] = userAgent;
      request.headers['Accept'] =
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';
      request.headers['Accept-Language'] = 'en-US,en;q=0.9';

      final streamedResponse = await client.send(request).timeout(fetchTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        AppLogger.warning(
          'GenericWebExtractor: HTTP ${response.statusCode} for $url',
        );
        return null;
      }

      AppLogger.debug(
        'GenericWebExtractor: Fetched ${response.body.length} bytes from $url',
      );

      return response.body;
    } on TimeoutException {
      AppLogger.warning('GenericWebExtractor: Timeout fetching $url');
      return null;
    } finally {
      client.close();
    }
  }
}

/// Provider for the GenericWebExtractor.
final genericWebExtractorProvider = Provider<GenericWebExtractor>((ref) {
  return GenericWebExtractor();
});

/// Helper class to combine GenericWebExtractor with WebExtractionService.
///
/// This provides a convenient API for the share flow that handles both
/// JSON-LD and backend extraction transparently.
class WebRecipeExtractor {
  final GenericWebExtractor _genericExtractor;
  final WebExtractionService _webExtractionService;

  WebRecipeExtractor(this._genericExtractor, this._webExtractionService);

  /// Extracts a recipe from a URL, using JSON-LD if available or backend fallback.
  ///
  /// [requiresPlus] - Whether the user has Plus subscription
  ///
  /// For Plus users:
  /// 1. Try JSON-LD (free)
  /// 2. If no JSON-LD, send HTML to backend
  ///
  /// For non-Plus users:
  /// 1. Try JSON-LD (free) - if found, return full recipe
  /// 2. If no JSON-LD, return null (backend requires Plus)
  Future<WebExtractionResult> extractRecipe({
    required Uri url,
    required bool hasPlus,
  }) async {
    // Step 1: Fetch and try JSON-LD
    final result = await _genericExtractor.extractFromUrl(url);

    // If we got an error or a JSON-LD recipe, return it
    if (result.error != null || result.recipe != null) {
      return result;
    }

    // Step 2: No JSON-LD - try backend (requires Plus)
    if (!hasPlus) {
      // Non-Plus users can't use backend extraction
      return WebExtractionResult(
        error: 'This site requires Plus subscription for recipe extraction.',
        html: result.html,
        sourceUrl: result.sourceUrl,
      );
    }

    if (!result.hasHtml) {
      return WebExtractionResult(
        error: 'No content available to extract.',
        sourceUrl: result.sourceUrl,
      );
    }

    try {
      final recipe = await _webExtractionService.extractRecipe(
        html: result.html!,
        sourceUrl: result.sourceUrl,
      );

      if (recipe != null) {
        return WebExtractionResult(
          recipe: recipe,
          source: WebExtractionSource.backendReadability,
          sourceUrl: result.sourceUrl,
        );
      } else {
        return WebExtractionResult(
          error: 'No recipe found on this page.',
          sourceUrl: result.sourceUrl,
        );
      }
    } on WebExtractionException catch (e) {
      return WebExtractionResult(
        error: e.message,
        sourceUrl: result.sourceUrl,
      );
    }
  }

  /// Extracts a recipe preview (for non-Plus users trying backend extraction).
  Future<WebExtractionResult> previewRecipe({
    required Uri url,
  }) async {
    // Step 1: Fetch and try JSON-LD
    final result = await _genericExtractor.extractFromUrl(url);

    // If we got a JSON-LD recipe, convert to preview
    if (result.recipe != null) {
      final recipe = result.recipe!;
      return WebExtractionResult(
        preview: RecipePreview(
          title: recipe.title,
          description: recipe.description ?? '',
          previewIngredients: recipe.ingredients
              .where((i) => i.type == 'ingredient')
              .take(4)
              .map((i) => i.name)
              .toList(),
        ),
        source: WebExtractionSource.jsonLdSchema,
        sourceUrl: result.sourceUrl,
      );
    }

    // Step 2: Try backend preview
    if (!result.hasHtml) {
      return WebExtractionResult(
        error: result.error ?? 'No content available.',
        sourceUrl: result.sourceUrl,
      );
    }

    try {
      final preview = await _webExtractionService.previewRecipe(
        html: result.html!,
        sourceUrl: result.sourceUrl,
      );

      if (preview != null) {
        return WebExtractionResult(
          preview: preview,
          source: WebExtractionSource.backendReadability,
          html: result.html,
          sourceUrl: result.sourceUrl,
        );
      } else {
        return WebExtractionResult(
          error: 'No recipe found on this page.',
          sourceUrl: result.sourceUrl,
        );
      }
    } on WebExtractionException catch (e) {
      return WebExtractionResult(
        error: e.message,
        sourceUrl: result.sourceUrl,
      );
    }
  }
}

/// Provider for the WebRecipeExtractor.
final webRecipeExtractorProvider = Provider<WebRecipeExtractor>((ref) {
  final genericExtractor = ref.watch(genericWebExtractorProvider);
  final webExtractionService = ref.watch(webExtractionServiceProvider);
  return WebRecipeExtractor(genericExtractor, webExtractionService);
});
