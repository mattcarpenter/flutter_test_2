import 'dart:convert';

import '../../features/clippings/models/extracted_recipe.dart';
import '../../features/clippings/models/recipe_preview.dart';
import '../logging/app_logger.dart';

/// Parses Recipe schema.org structured data (JSON-LD) from HTML.
///
/// This parser extracts recipe data from `<script type="application/ld+json">`
/// tags in HTML. Many recipe websites use structured data for SEO, which
/// provides a reliable way to extract recipe information without AI.
///
/// Supports multiple schema formats:
/// - Direct Recipe type: `{"@type": "Recipe", ...}`
/// - @graph array: `{"@graph": [{"@type": "Recipe", ...}]}`
/// - Top-level array: `[{"@type": "Recipe", ...}]`
class JsonLdRecipeParser {
  /// Parses HTML and extracts Recipe schema.org data.
  ///
  /// Returns [ExtractedRecipe] if a Recipe schema is found and parsed,
  /// or null if no recipe schema is present.
  ExtractedRecipe? parse(String html) {
    try {
      final recipeData = _findRecipeSchema(html);
      if (recipeData == null) {
        return null;
      }

      return _parseRecipeData(recipeData);
    } catch (e, stack) {
      AppLogger.debug('JSON-LD parsing failed: $e');
      AppLogger.trace('Stack trace: $stack');
      return null;
    }
  }

  /// Parses HTML and extracts just enough for a recipe preview.
  ///
  /// Returns [RecipePreview] with title, description, and first 4 ingredients,
  /// or null if no recipe schema is present.
  RecipePreview? parsePreview(String html) {
    try {
      final recipeData = _findRecipeSchema(html);
      if (recipeData == null) {
        return null;
      }

      return _parseRecipePreview(recipeData);
    } catch (e, stack) {
      AppLogger.debug('JSON-LD preview parsing failed: $e');
      AppLogger.trace('Stack trace: $stack');
      return null;
    }
  }

  /// Finds and parses all ld+json scripts, returning the first Recipe found.
  Map<String, dynamic>? _findRecipeSchema(String html) {
    // Find all <script type="application/ld+json"> tags
    // Pattern matches both single and double quotes around the type value
    final scriptPattern = RegExp(
      '<script[^>]*type=["\']application/ld\\+json["\'][^>]*>([\\s\\S]*?)</script>',
      caseSensitive: false,
    );

    final matches = scriptPattern.allMatches(html);

    for (final match in matches) {
      final jsonContent = match.group(1);
      if (jsonContent == null || jsonContent.trim().isEmpty) {
        continue;
      }

      try {
        final decoded = jsonDecode(jsonContent.trim());
        final recipe = _extractRecipeFromSchema(decoded);
        if (recipe != null) {
          AppLogger.debug('Found Recipe schema in JSON-LD');
          return recipe;
        }
      } catch (e) {
        // Invalid JSON, try next script
        continue;
      }
    }

    return null;
  }

  /// Extracts Recipe data from a JSON-LD structure.
  ///
  /// Handles multiple formats:
  /// - Direct Recipe object
  /// - @graph array containing Recipe
  /// - Top-level array containing Recipe
  Map<String, dynamic>? _extractRecipeFromSchema(dynamic data) {
    if (data is Map<String, dynamic>) {
      // Check if this is directly a Recipe
      if (_isRecipeType(data)) {
        return data;
      }

      // Check for @graph array
      if (data.containsKey('@graph') && data['@graph'] is List) {
        final graph = data['@graph'] as List;
        for (final item in graph) {
          if (item is Map<String, dynamic> && _isRecipeType(item)) {
            return item;
          }
        }
      }
    } else if (data is List) {
      // Top-level array of schemas
      for (final item in data) {
        if (item is Map<String, dynamic> && _isRecipeType(item)) {
          return item;
        }
      }
    }

    return null;
  }

  /// Checks if a JSON object represents a Recipe type.
  bool _isRecipeType(Map<String, dynamic> data) {
    final type = data['@type'];
    if (type is String) {
      return type == 'Recipe' || type.endsWith('/Recipe');
    } else if (type is List) {
      return type.any((t) => t == 'Recipe' || t.toString().endsWith('/Recipe'));
    }
    return false;
  }

  /// Parses Recipe schema data into ExtractedRecipe.
  ExtractedRecipe _parseRecipeData(Map<String, dynamic> data) {
    final title = _extractString(data['name']) ?? 'Untitled Recipe';
    final description = _extractString(data['description']);
    final servings = _extractServings(data['recipeYield']);
    final prepTime = _parseDuration(data['prepTime']);
    final cookTime = _parseDuration(data['cookTime']);
    final ingredients = _parseIngredients(data['recipeIngredient']);
    final steps = _parseInstructions(data['recipeInstructions']);
    final source = _extractString(data['url']) ?? _extractString(data['mainEntityOfPage']);
    final imageUrl = _extractImageUrl(data['image']);

    AppLogger.debug(
      'Parsed Recipe from JSON-LD: '
      'title=$title, '
      'ingredients=${ingredients.length}, '
      'steps=${steps.length}, '
      'hasImage=${imageUrl != null}',
    );

    return ExtractedRecipe(
      title: title,
      description: description,
      servings: servings,
      prepTime: prepTime,
      cookTime: cookTime,
      ingredients: ingredients,
      steps: steps,
      source: source,
      imageUrl: imageUrl,
    );
  }

  /// Extracts image URL from JSON-LD image property.
  ///
  /// Handles multiple formats:
  /// - Simple URL string: "https://example.com/image.jpg"
  /// - Array of URLs: ["https://...", "https://..."]
  /// - ImageObject: {"@type": "ImageObject", "url": "https://..."}
  /// - Array of ImageObjects: [{"@type": "ImageObject", "url": "..."}]
  String? _extractImageUrl(dynamic value) {
    if (value == null) return null;

    // Simple string URL
    if (value is String) {
      return value.trim().isNotEmpty ? value.trim() : null;
    }

    // Array - take the first valid URL
    if (value is List && value.isNotEmpty) {
      for (final item in value) {
        final url = _extractImageUrl(item);
        if (url != null) return url;
      }
      return null;
    }

    // ImageObject or similar object with url property
    if (value is Map<String, dynamic>) {
      // Try common URL properties
      final url = value['url'] ?? value['contentUrl'] ?? value['@id'];
      if (url is String && url.trim().isNotEmpty) {
        return url.trim();
      }
    }

    return null;
  }

  /// Parses Recipe schema data into RecipePreview.
  RecipePreview _parseRecipePreview(Map<String, dynamic> data) {
    final title = _extractString(data['name']) ?? 'Untitled Recipe';
    final description = _extractString(data['description']) ?? '';
    final allIngredients = _parseIngredientStrings(data['recipeIngredient']);
    final previewIngredients = allIngredients.take(4).toList();

    return RecipePreview(
      title: title,
      description: description.length > 100
          ? '${description.substring(0, 97)}...'
          : description,
      previewIngredients: previewIngredients,
    );
  }

  /// Extracts a string from a value that might be a string, object, or null.
  /// Decodes HTML entities that may be present in JSON-LD content.
  String? _extractString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final decoded = _decodeHtmlEntities(value.trim());
      return decoded.isEmpty ? null : decoded;
    }
    if (value is Map) {
      // Some schemas use {"@id": "url"} or {"@value": "text"}
      return _extractString(value['@value'] ?? value['@id'] ?? value['name']);
    }
    return _decodeHtmlEntities(value.toString());
  }

  /// Decodes HTML entities in a string.
  ///
  /// Handles:
  /// - Common named entities (&nbsp;, &amp;, &lt;, &gt;, &quot;, &apos;, etc.)
  /// - Decimal numeric entities (&#160;, &#8217;, etc.)
  /// - Hexadecimal numeric entities (&#x00A0;, &#xA0;, etc.)
  String _decodeHtmlEntities(String input) {
    if (!input.contains('&')) return input;

    // Common named entities
    const namedEntities = {
      '&nbsp;': '\u00A0', // Non-breaking space
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&apos;': "'",
      '&#39;': "'", // Alternative apostrophe
      '&mdash;': '—',
      '&ndash;': '–',
      '&ldquo;': '"',
      '&rdquo;': '"',
      '&lsquo;': ''',
      '&rsquo;': ''',
      '&hellip;': '…',
      '&deg;': '°',
      '&frac12;': '½',
      '&frac14;': '¼',
      '&frac34;': '¾',
      '&times;': '×',
      '&divide;': '÷',
      '&copy;': '©',
      '&reg;': '®',
      '&trade;': '™',
    };

    var result = input;

    // Replace named entities
    namedEntities.forEach((entity, char) {
      result = result.replaceAll(entity, char);
    });

    // Replace decimal numeric entities (&#123;)
    result = result.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (match) {
        final code = int.tryParse(match.group(1)!);
        if (code != null && code > 0 && code <= 0x10FFFF) {
          return String.fromCharCode(code);
        }
        return match.group(0)!;
      },
    );

    // Replace hexadecimal numeric entities (&#x7B; or &#X7B;)
    result = result.replaceAllMapped(
      RegExp(r'&#[xX]([0-9a-fA-F]+);'),
      (match) {
        final code = int.tryParse(match.group(1)!, radix: 16);
        if (code != null && code > 0 && code <= 0x10FFFF) {
          return String.fromCharCode(code);
        }
        return match.group(0)!;
      },
    );

    // Normalize non-breaking spaces to regular spaces for readability
    result = result.replaceAll('\u00A0', ' ');

    return result;
  }

  /// Extracts servings from recipeYield which can be various formats.
  int? _extractServings(dynamic value) {
    if (value == null) return null;

    String text;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      text = value;
    } else if (value is List && value.isNotEmpty) {
      text = value.first.toString();
    } else {
      text = value.toString();
    }

    // Try to extract number from text like "4 servings" or "Makes 12"
    final match = RegExp(r'(\d+)').firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }

    return null;
  }

  /// Parses ISO 8601 duration (e.g., "PT1H30M") to minutes.
  int? _parseDuration(dynamic value) {
    if (value == null) return null;

    final text = value.toString();
    if (!text.startsWith('P')) return null;

    // Match patterns like PT1H30M, PT45M, PT2H
    final match = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?').firstMatch(text);
    if (match == null) return null;

    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;

    final total = hours * 60 + minutes;
    return total > 0 ? total : null;
  }

  /// Parses recipeIngredient array into list of ExtractedIngredient.
  List<ExtractedIngredient> _parseIngredients(dynamic value) {
    final strings = _parseIngredientStrings(value);
    return strings
        .map((s) => ExtractedIngredient(name: s, type: 'ingredient'))
        .toList();
  }

  /// Parses recipeIngredient array into list of strings.
  List<String> _parseIngredientStrings(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value
          .map((e) => _extractString(e))
          .where((s) => s != null && s.isNotEmpty)
          .cast<String>()
          .toList();
    }

    // Single ingredient as string
    final single = _extractString(value);
    return single != null ? [single] : [];
  }

  /// Parses recipeInstructions which can be:
  /// - Array of strings
  /// - Array of HowToStep objects
  /// - Array of HowToSection objects containing HowToStep items
  /// - Single string
  List<ExtractedStep> _parseInstructions(dynamic value) {
    if (value == null) return [];

    final steps = <ExtractedStep>[];

    if (value is String) {
      // Single string - split by newlines or periods
      final parts = value.split(RegExp(r'[\n\r]+|\.\s+'));
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty) {
          steps.add(ExtractedStep(text: trimmed, type: 'step'));
        }
      }
      return steps;
    }

    if (value is List) {
      for (final item in value) {
        if (item is String) {
          // Simple string step
          final trimmed = item.trim();
          if (trimmed.isNotEmpty) {
            steps.add(ExtractedStep(text: trimmed, type: 'step'));
          }
        } else if (item is Map<String, dynamic>) {
          _parseInstructionItem(item, steps);
        }
      }
    }

    return steps;
  }

  /// Parses a single instruction item (HowToStep, HowToSection, etc).
  void _parseInstructionItem(Map<String, dynamic> item, List<ExtractedStep> steps) {
    final type = item['@type']?.toString() ?? '';

    if (type == 'HowToSection' || type.endsWith('/HowToSection')) {
      // Section with nested steps
      final sectionName = _extractString(item['name']);
      if (sectionName != null && sectionName.isNotEmpty) {
        steps.add(ExtractedStep(text: sectionName, type: 'section'));
      }

      // Parse nested items
      final nestedItems = item['itemListElement'] ?? item['steps'];
      if (nestedItems is List) {
        for (final nested in nestedItems) {
          if (nested is Map<String, dynamic>) {
            _parseInstructionItem(nested, steps);
          } else if (nested is String) {
            final trimmed = nested.trim();
            if (trimmed.isNotEmpty) {
              steps.add(ExtractedStep(text: trimmed, type: 'step'));
            }
          }
        }
      }
    } else if (type == 'HowToStep' || type.endsWith('/HowToStep')) {
      // Single step
      final text = _extractString(item['text']) ?? _extractString(item['name']);
      if (text != null && text.isNotEmpty) {
        steps.add(ExtractedStep(text: text, type: 'step'));
      }
    } else {
      // Unknown type - try to extract text anyway
      final text = _extractString(item['text']) ?? _extractString(item['name']);
      if (text != null && text.isNotEmpty) {
        steps.add(ExtractedStep(text: text, type: 'step'));
      }
    }
  }
}
