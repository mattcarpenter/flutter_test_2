import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../database/models/ingredients.dart';
import '../../../../localization/l10n_extension.dart';
import '../../../../models/ingredient_pantry_match.dart';
import '../../../../providers/recipe_provider.dart' show recipeIngredientMatchesProvider, recipeByIdStreamProvider;
import '../../../../providers/scale_convert_provider.dart';
import '../../../settings/providers/app_settings_provider.dart';
import '../../../../theme/typography.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../services/ingredient_parser_service.dart';
import '../../../../widgets/ingredient_stock_chip.dart';
import '../../models/scale_convert_state.dart';
import '../scale_convert/scale_convert_panel.dart';
import 'ingredient_matches_bottom_sheet.dart';

class RecipeIngredientsView extends ConsumerStatefulWidget {
  final List<Ingredient> ingredients;
  final String? recipeId;

  const RecipeIngredientsView({
    Key? key,
    required this.ingredients,
    this.recipeId,
  }) : super(key: key);

  @override
  ConsumerState<RecipeIngredientsView> createState() => _RecipeIngredientsViewState();
}

class _RecipeIngredientsViewState extends ConsumerState<RecipeIngredientsView>
    with SingleTickerProviderStateMixin {
  // Keep previous match data to prevent flashing
  RecipeIngredientMatches? _previousMatches;

  // Parser for ingredient text formatting
  final _parser = IngredientParserService();

  // Gesture recognizers for markdown links (need disposal)
  final List<TapGestureRecognizer> _linkRecognizers = [];

  // Accordion animation controller
  late AnimationController _accordionController;
  late Animation<double> _accordionAnimation;

  @override
  void initState() {
    super.initState();
    _accordionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _accordionAnimation = CurvedAnimation(
      parent: _accordionController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _accordionController.dispose();
    for (final recognizer in _linkRecognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  /// Clear old recognizers before rebuild
  void _clearRecognizers() {
    for (final recognizer in _linkRecognizers) {
      recognizer.dispose();
    }
    _linkRecognizers.clear();
  }

  void _toggleAccordion() {
    if (_accordionController.isCompleted) {
      _accordionController.reverse();
    } else {
      _accordionController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Clear old recognizers before rebuilding
    _clearRecognizers();

    // Only fetch matches if recipeId is provided
    final matchesAsync = widget.recipeId != null
      ? ref.watch(recipeIngredientMatchesProvider(widget.recipeId!))
      : null;

    // Get current matches, but keep previous data during loading to prevent flashing
    RecipeIngredientMatches? currentMatches;
    if (matchesAsync != null) {
      matchesAsync.whenData((matches) {
        _previousMatches = matches; // Store successful data
        currentMatches = matches;
      });

      // Use previous data if we're in loading state and have previous data
      if (matchesAsync.isLoading && _previousMatches != null) {
        currentMatches = _previousMatches;
      } else if (!matchesAsync.isLoading) {
        currentMatches = matchesAsync.valueOrNull;
      }
    }

    // Get font scale from settings - use AppTypography.body as the base for consistency
    final fontScale = ref.watch(recipeFontScaleProvider);
    final baseStyle = AppTypography.body;
    final scaledFontSize = (baseStyle.fontSize ?? 15.0) * fontScale;

    // Watch transformed ingredients for scale/convert
    final transformedIngredients = widget.recipeId != null
        ? ref.watch(transformedIngredientsByIdProvider(widget.recipeId!))
        : <String, TransformedIngredient>{};

    // Watch recipe to get servings for scale panel
    final recipeServings = widget.recipeId != null
        ? ref.watch(recipeByIdStreamProvider(widget.recipeId!)).valueOrNull?.servings
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with "Scale or Convert" button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.recipeViewIngredients,
              style: AppTypography.h3Serif.copyWith(
                color: AppColors.of(context).headingSecondary,
              ),
            ),
            TextButton(
              onPressed: _toggleAccordion,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: AnimatedBuilder(
                animation: _accordionController,
                builder: (context, child) {
                  // Check if any transform is active
                  final isTransformActive = widget.recipeId != null &&
                      ref.watch(scaleConvertProvider(widget.recipeId!)).isTransformActive;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isTransformActive) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.of(context).error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(context.l10n.recipeViewScaleConvert),
                      const SizedBox(width: 4),
                      Icon(
                        _accordionController.value > 0.5
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),

        // Animated accordion panel - expands vertically and fades in/out
        if (widget.recipeId != null)
          SizeTransition(
            sizeFactor: _accordionAnimation,
            axisAlignment: -1.0,
            child: FadeTransition(
              opacity: _accordionAnimation,
              child: Padding(
                padding: EdgeInsets.only(top: AppSpacing.md),
                child: ScaleConvertPanel(
                  recipeId: widget.recipeId!,
                  recipeServings: recipeServings,
                ),
              ),
            ),
          ),

        SizedBox(height: AppSpacing.md),

        if (widget.ingredients.isEmpty)
          Text(
            context.l10n.recipeViewNoIngredients,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
            ),
          ),

        // Ingredients list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: widget.ingredients.length,
          itemBuilder: (context, index) {
            final ingredient = widget.ingredients[index];

            // Section header
            if (ingredient.type == 'section') {
              return Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 0 : AppSpacing.xl, // More spacing on top
                  bottom: AppSpacing.sm, // Less spacing on bottom
                ),
                child: Text(
                  ingredient.name.toUpperCase(),
                  style: AppTypography.sectionLabel,
                ),
              );
            }

            // Check if previous item was a section (to skip top separator)
            final isFirstAfterSection = index > 0 &&
                widget.ingredients[index - 1].type == 'section';

            // Regular ingredient with match indicator (if available)
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Full-width separator (except for first item or first after section)
                if (index > 0 && !isFirstAfterSection)
                  Transform.translate(
                    offset: const Offset(-16, 0), // Extend left into padding
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: AppColors.of(context).border,
                      ),
                    ),
                  ),
                // Ingredient content with padding
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: ingredient.recipeId != null
                        ? () => _navigateToLinkedRecipe(context, ingredient.recipeId!)
                        : null,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bullet point
                        Text(
                          '•',
                          style: AppTypography.body.copyWith(
                            fontSize: scaledFontSize * 1.4,
                            height: 1.0,
                            color: AppColors.of(context).textSecondary,
                          ),
                        ),
                        SizedBox(width: AppSpacing.xs),
                        // Ingredient name (with optional scaling/conversion)
                        Expanded(
                          child: _buildIngredientText(
                            ingredient: ingredient,
                            transformed: transformedIngredients[ingredient.id],
                            fontSize: scaledFontSize,
                            isLinkedRecipe: ingredient.recipeId != null,
                          ),
                        ),

                        // Stock status chip (right-aligned)
                        if (currentMatches != null) ...[
                          SizedBox(width: AppSpacing.sm),
                          () {
                            // Find the matching IngredientPantryMatch for this ingredient
                            final match = currentMatches!.matches.firstWhere(
                              (m) => m.ingredient.id == ingredient.id,
                              // If no match found, create a default one with no pantry match
                              orElse: () => IngredientPantryMatch(ingredient: ingredient),
                            );

                            return GestureDetector(
                              onTap: () => _showMatchesBottomSheet(context, ref, currentMatches!),
                              child: IngredientStockChip(match: match),
                            );
                          }(),
                        ],

                      // Note (if available)
                      if (ingredient.note != null && ingredient.note!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '(${ingredient.note})',
                            style: AppTypography.caption.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppColors.of(context).textTertiary,
                            ),
                          ),
                        ),
                      ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Extracts trailing parenthetical text from ingredient name.
  /// Returns a tuple of (mainText, parentheticalText) or null if no trailing parens.
  /// Handles nested parentheses like "(real, not artificial (sub honey))".
  ({String main, String paren})? _extractTrailingParenthetical(String text) {
    final trimmed = text.trimRight();
    if (!trimmed.endsWith(')')) return null;

    // Find the matching opening paren by counting depth from the end
    int depth = 0;
    int openIndex = -1;
    for (int i = trimmed.length - 1; i >= 0; i--) {
      final char = trimmed[i];
      if (char == ')') {
        depth++;
      } else if (char == '(') {
        depth--;
        if (depth == 0) {
          openIndex = i;
          break;
        }
      }
    }

    // No matching open paren found, or it's at the start (entire string is in parens)
    if (openIndex <= 0) return null;

    final main = trimmed.substring(0, openIndex).trimRight();
    final paren = trimmed.substring(openIndex + 1, trimmed.length - 1);

    // Don't extract if main text is empty
    if (main.isEmpty) return null;

    return (main: main, paren: paren);
  }

  /// Builds ingredient text with bold quantities and markdown support.
  ///
  /// Supports:
  /// - Bold quantities (from ingredient parsing)
  /// - `[text](url)` - External links
  /// - `**text**` - Bold formatting
  /// - `*text*` / `_text_` - Italic formatting
  /// - Trailing parenthetical text displayed on second line
  ///
  /// If [transformed] is provided, uses the transformed display text and quantity
  /// positions. Otherwise falls back to parsing the original ingredient name.
  Widget _buildIngredientText({
    required Ingredient ingredient,
    TransformedIngredient? transformed,
    required double fontSize,
    bool isLinkedRecipe = false,
  }) {
    final colors = AppColors.of(context);
    final baseStyle = AppTypography.body.copyWith(
      fontSize: fontSize,
      color: colors.contentPrimary,
    );

    // Determine which text and quantity positions to use
    String text;
    List<({int start, int end})> quantityPositions;

    if (transformed != null && (transformed.wasScaled || transformed.wasConverted)) {
      // Use transformed text and positions
      text = transformed.displayText;
      quantityPositions = transformed.quantities
          .map((q) => (start: q.start, end: q.end))
          .toList();
    } else {
      // Parse original ingredient name
      text = ingredient.name;
      try {
        final parseResult = _parser.parse(text);
        quantityPositions = parseResult.quantities
            .map((q) => (start: q.start, end: q.end))
            .toList();
      } catch (_) {
        quantityPositions = [];
      }
    }

    // Check for trailing parenthetical text
    final parenResult = _extractTrailingParenthetical(text);

    // If we have trailing parens, use only the main text for rich text processing
    final displayText = parenResult?.main ?? text;

    // Adjust quantity positions if we removed parenthetical text
    // (positions remain valid since we only trim from the end)
    final adjustedQuantities = quantityPositions
        .where((q) => q.end <= displayText.length)
        .toList();

    // Parse markdown tokens from the text
    final markdownTokens = _parseMarkdownTokens(displayText);

    // Build styled ranges by merging quantities and markdown
    final styledRanges = _buildStyledRanges(displayText, adjustedQuantities, markdownTokens);

    // Build TextSpan children from styled ranges
    final children = _buildSpansFromRanges(displayText, styledRanges, baseStyle, colors);

    // Add external link icon for linked recipes (via ingredient.recipeId)
    if (isLinkedRecipe) {
      children.add(const TextSpan(text: ' '));
      children.add(WidgetSpan(
        child: Icon(
          Icons.open_in_new,
          size: 14,
          color: colors.contentSecondary,
        ),
        alignment: PlaceholderAlignment.middle,
      ));
    }

    final mainTextWidget = RichText(
      text: TextSpan(
        children: children,
        style: isLinkedRecipe
            ? TextStyle(
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dotted,
                decorationColor: colors.contentPrimary,
              )
            : null,
      ),
    );

    // If no parenthetical text, just return the main text
    if (parenResult == null) {
      return mainTextWidget;
    }

    // Otherwise, return a Column with main text and parenthetical below
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        mainTextWidget,
        const SizedBox(height: 2),
        Padding(
          padding: EdgeInsets.only(left: AppSpacing.xs),
          child: Text(
            parenResult.paren,
            style: AppTypography.bodySmall.copyWith(
              fontSize: fontSize * 0.85,
              color: colors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  /// Parse markdown tokens from text.
  List<_MarkdownToken> _parseMarkdownTokens(String text) {
    final tokens = <_MarkdownToken>[];

    // [text](url) - external links
    final linkPattern = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
    for (final match in linkPattern.allMatches(text)) {
      tokens.add(_MarkdownToken(
        type: _MarkdownType.link,
        start: match.start,
        end: match.end,
        content: match.group(1)!,
        url: match.group(2),
      ));
    }

    // **bold** - must be processed before single *
    final boldPattern = RegExp(r'\*\*([^*]+)\*\*');
    for (final match in boldPattern.allMatches(text)) {
      tokens.add(_MarkdownToken(
        type: _MarkdownType.bold,
        start: match.start,
        end: match.end,
        content: match.group(1)!,
      ));
    }

    // *italic* - single asterisks not part of **
    final italicAsteriskPattern = RegExp(r'(?<!\*)\*(?!\*)([^*]+)\*(?!\*)');
    for (final match in italicAsteriskPattern.allMatches(text)) {
      tokens.add(_MarkdownToken(
        type: _MarkdownType.italic,
        start: match.start,
        end: match.end,
        content: match.group(1)!,
      ));
    }

    // _italic_ - underscore style
    final italicUnderscorePattern = RegExp(r'_([^_]+)_');
    for (final match in italicUnderscorePattern.allMatches(text)) {
      tokens.add(_MarkdownToken(
        type: _MarkdownType.italic,
        start: match.start,
        end: match.end,
        content: match.group(1)!,
      ));
    }

    // Sort by start position
    tokens.sort((a, b) => a.start.compareTo(b.start));

    // Remove overlapping tokens (keep the one that starts first)
    final filtered = <_MarkdownToken>[];
    int lastEnd = 0;
    for (final token in tokens) {
      if (token.start >= lastEnd) {
        filtered.add(token);
        lastEnd = token.end;
      }
    }

    return filtered;
  }

  /// Build a list of styled ranges by merging quantity positions and markdown tokens.
  List<_StyledRange> _buildStyledRanges(
    String text,
    List<({int start, int end})> quantities,
    List<_MarkdownToken> markdown,
  ) {
    final ranges = <_StyledRange>[];

    // Add quantity ranges (bold)
    for (final q in quantities) {
      ranges.add(_StyledRange(
        start: q.start,
        end: q.end,
        isBold: true,
        isItalic: false,
        isLink: false,
        displayText: text.substring(q.start, q.end),
      ));
    }

    // Add markdown ranges, checking for overlaps with quantities
    for (final token in markdown) {
      // Check if this token overlaps with any quantity range
      final overlapsQuantity = quantities.any((q) =>
          !(token.end <= q.start || token.start >= q.end));

      if (overlapsQuantity) {
        // Skip markdown tokens that overlap with quantities
        // (quantity formatting takes precedence)
        continue;
      }

      ranges.add(_StyledRange(
        start: token.start,
        end: token.end,
        isBold: token.type == _MarkdownType.bold,
        isItalic: token.type == _MarkdownType.italic,
        isLink: token.type == _MarkdownType.link,
        displayText: token.content,
        url: token.url,
      ));
    }

    // Sort by start position
    ranges.sort((a, b) => a.start.compareTo(b.start));

    return ranges;
  }

  /// Build TextSpan children from styled ranges.
  List<InlineSpan> _buildSpansFromRanges(
    String text,
    List<_StyledRange> ranges,
    TextStyle baseStyle,
    AppColors colors,
  ) {
    final children = <InlineSpan>[];
    int currentIndex = 0;

    for (final range in ranges) {
      // Add plain text before this range
      if (range.start > currentIndex) {
        children.add(TextSpan(
          text: text.substring(currentIndex, range.start),
          style: baseStyle,
        ));
      }

      // Build styled span for this range
      if (range.isLink) {
        // Create link with gesture recognizer
        final recognizer = TapGestureRecognizer()
          ..onTap = () => _launchUrl(range.url!);
        _linkRecognizers.add(recognizer);

        children.add(TextSpan(
          text: range.displayText,
          style: baseStyle.copyWith(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: colors.textSecondary,
          ),
          recognizer: recognizer,
        ));
      } else {
        // Regular styled text
        children.add(TextSpan(
          text: range.displayText,
          style: baseStyle.copyWith(
            fontWeight: range.isBold ? FontWeight.bold : null,
            fontStyle: range.isItalic ? FontStyle.italic : null,
          ),
        ));
      }

      currentIndex = range.end;
    }

    // Add remaining text after last range
    if (currentIndex < text.length) {
      children.add(TextSpan(
        text: text.substring(currentIndex),
        style: baseStyle,
      ));
    }

    return children;
  }

  /// Launch a URL in external browser.
  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Navigates to the linked recipe
  void _navigateToLinkedRecipe(BuildContext context, String recipeId) {
    context.push('/recipe/$recipeId', extra: {
      'previousPageTitle': 'Recipe'
    });
  }

  /// Shows the bottom sheet with ingredient match details
  void _showMatchesBottomSheet(BuildContext context, WidgetRef ref, RecipeIngredientMatches matches) {
    // Refresh the recipe ingredient match data before showing the sheet
    // This ensures we have the latest data including newly added ingredients
    ref.invalidate(recipeIngredientMatchesProvider(matches.recipeId));

    // Show the bottom sheet after refreshing the data
    Future.microtask(() {
      // Wait for the provider to refresh its data before showing the sheet
      ref.read(recipeIngredientMatchesProvider(matches.recipeId).future).then((refreshedMatches) {
        showIngredientMatchesBottomSheet(
          context,
          matches: refreshedMatches,
        );
      }).catchError((error) {
        // If there's an error refreshing, still show the sheet with the original data
        showIngredientMatchesBottomSheet(
          context,
          matches: matches,
        );
      });
    });
  }
}

/// Types of markdown formatting tokens.
enum _MarkdownType {
  bold,
  italic,
  link,
}

/// A parsed markdown token with position and content.
class _MarkdownToken {
  final _MarkdownType type;
  final int start;
  final int end;
  final String content;
  final String? url;

  _MarkdownToken({
    required this.type,
    required this.start,
    required this.end,
    required this.content,
    this.url,
  });
}

/// A styled range with merged formatting from quantities and markdown.
class _StyledRange {
  final int start;
  final int end;
  final bool isBold;
  final bool isItalic;
  final bool isLink;
  final String displayText;
  final String? url;

  _StyledRange({
    required this.start,
    required this.end,
    required this.isBold,
    required this.isItalic,
    required this.isLink,
    required this.displayText,
    this.url,
  });
}
