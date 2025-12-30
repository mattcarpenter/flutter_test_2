import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/recipe_provider.dart';
import '../services/duration_detection_service.dart';
import '../theme/colors.dart';

/// Callback type for when a duration is tapped.
/// [duration] is the parsed duration value.
/// [detectedText] is the original matched text (e.g., "25 minutes").
typedef DurationTapCallback = void Function(Duration duration, String detectedText);

/// A widget that renders recipe text with rich formatting support.
///
/// Supports:
/// - `[text](url)` - External links (dotted underline, opens in browser)
/// - `**text**` - Bold formatting
/// - `*text*` - Italic formatting
/// - `_text_` - Italic formatting
/// - `[recipe:Name]` - Recipe links (only when [enableRecipeLinks] is true)
/// - Duration expressions - Time expressions like "25 minutes" or "1時間30分"
///   (only when [enableDurationLinks] is true)
///
/// Recipe links are resolved at render time - if a recipe with matching title
/// is found, it renders as a tappable link. Otherwise, just the name is shown.
class RecipeTextRenderer extends ConsumerStatefulWidget {
  final String text;
  final TextStyle baseStyle;

  /// When true, `[recipe:Name]` tokens are parsed and linked if a matching
  /// recipe is found. When false, they're rendered as plain text.
  final bool enableRecipeLinks;

  /// When true, duration expressions (e.g., "25 minutes", "1時間30分") are
  /// detected and rendered as tappable links. When false, they're rendered
  /// as plain text.
  final bool enableDurationLinks;

  /// Callback invoked when a duration is tapped.
  /// Only called when [enableDurationLinks] is true.
  final DurationTapCallback? onDurationTap;

  /// Text alignment for the rendered text.
  final TextAlign? textAlign;

  const RecipeTextRenderer({
    super.key,
    required this.text,
    required this.baseStyle,
    this.enableRecipeLinks = false,
    this.enableDurationLinks = false,
    this.onDurationTap,
    this.textAlign,
  });

  @override
  ConsumerState<RecipeTextRenderer> createState() => _RecipeTextRendererState();
}

class _RecipeTextRendererState extends ConsumerState<RecipeTextRenderer> {
  final List<TapGestureRecognizer> _recognizers = [];
  final DurationDetectionService _durationService = DurationDetectionService();

  // Cache parsed tokens to avoid re-parsing on every build
  List<_ParsedToken>? _cachedTokens;
  String? _cachedText;
  bool? _cachedEnableDurationLinks;

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(RecipeTextRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.enableDurationLinks != widget.enableDurationLinks) {
      // Invalidate cache when text or duration links setting changes
      _cachedTokens = null;
      _cachedText = null;
      _cachedEnableDurationLinks = null;
      // Clear old recognizers
      for (final recognizer in _recognizers) {
        recognizer.dispose();
      }
      _recognizers.clear();
    }
  }

  /// Get cached tokens or parse if needed
  List<_ParsedToken> _getTokens() {
    if (_cachedTokens != null &&
        _cachedText == widget.text &&
        _cachedEnableDurationLinks == widget.enableDurationLinks) {
      return _cachedTokens!;
    }

    _cachedTokens = _parseTokens(widget.text);
    _cachedText = widget.text;
    _cachedEnableDurationLinks = widget.enableDurationLinks;
    return _cachedTokens!;
  }

  @override
  Widget build(BuildContext context) {
    // Clear and rebuild recognizers on each build (needed for gesture handling)
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final colors = AppColors.of(context);
    final spans = _buildSpans(context, colors);

    return Text.rich(
      TextSpan(children: spans),
      textAlign: widget.textAlign,
    );
  }

  List<InlineSpan> _buildSpans(BuildContext context, AppColors colors) {
    final text = widget.text;
    final tokens = _getTokens(); // Use cached tokens

    if (tokens.isEmpty) {
      return [TextSpan(text: text, style: widget.baseStyle)];
    }

    final spans = <InlineSpan>[];
    int currentIndex = 0;

    for (final token in tokens) {
      // Add plain text before this token
      if (token.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, token.start),
          style: widget.baseStyle,
        ));
      }

      // Add the token span
      spans.add(_buildTokenSpan(context, token, colors));
      currentIndex = token.end;
    }

    // Add remaining text after last token
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: widget.baseStyle,
      ));
    }

    return spans;
  }

  InlineSpan _buildTokenSpan(
    BuildContext context,
    _ParsedToken token,
    AppColors colors,
  ) {
    switch (token.type) {
      case _TokenType.bold:
        return TextSpan(
          text: token.content,
          style: widget.baseStyle.copyWith(fontWeight: FontWeight.bold),
        );

      case _TokenType.italic:
        return TextSpan(
          text: token.content,
          style: widget.baseStyle.copyWith(fontStyle: FontStyle.italic),
        );

      case _TokenType.link:
        final recognizer = TapGestureRecognizer()
          ..onTap = () => _launchUrl(token.url!);
        _recognizers.add(recognizer);

        return TextSpan(
          text: token.content,
          style: widget.baseStyle.copyWith(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: colors.textSecondary,
          ),
          recognizer: recognizer,
        );

      case _TokenType.recipeLink:
        return _buildRecipeLinkSpan(context, token, colors);

      case _TokenType.duration:
        return _buildDurationSpan(context, token, colors);
    }
  }

  InlineSpan _buildDurationSpan(
    BuildContext context,
    _ParsedToken token,
    AppColors colors,
  ) {
    if (!widget.enableDurationLinks) {
      // Duration links disabled entirely - render as plain text
      return TextSpan(text: token.content, style: widget.baseStyle);
    }

    // Duration links enabled - render with highlight styling
    final highlightedStyle = widget.baseStyle.copyWith(
      color: Theme.of(context).primaryColor,
      fontWeight: FontWeight.w500,
    );

    if (widget.onDurationTap == null) {
      // No tap handler - render styled but not tappable (for animations)
      return TextSpan(text: token.content, style: highlightedStyle);
    }

    // Full interactive version
    final recognizer = TapGestureRecognizer()
      ..onTap = () => widget.onDurationTap!(token.duration!, token.content);
    _recognizers.add(recognizer);

    return TextSpan(
      text: token.content,
      style: highlightedStyle,
      recognizer: recognizer,
    );
  }

  InlineSpan _buildRecipeLinkSpan(
    BuildContext context,
    _ParsedToken token,
    AppColors colors,
  ) {
    if (!widget.enableRecipeLinks) {
      // Recipe links disabled - render as plain text
      return TextSpan(text: token.content, style: widget.baseStyle);
    }

    // Look up the recipe by title
    final recipeAsync = ref.watch(recipeByTitleProvider(token.content));

    return recipeAsync.when(
      loading: () => TextSpan(text: token.content, style: widget.baseStyle),
      error: (_, __) => TextSpan(text: token.content, style: widget.baseStyle),
      data: (recipe) {
        if (recipe == null) {
          // No matching recipe found - render as plain text
          return TextSpan(text: token.content, style: widget.baseStyle);
        }

        // Recipe found - render as tappable link
        final recognizer = TapGestureRecognizer()
          ..onTap = () => context.push('/recipe/${recipe.id}');
        _recognizers.add(recognizer);

        return TextSpan(
          text: token.content,
          style: widget.baseStyle.copyWith(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: colors.textSecondary,
          ),
          recognizer: recognizer,
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Parse all tokens from the text.
  ///
  /// Returns tokens sorted by start position. Overlapping tokens are resolved
  /// by keeping the one that starts first.
  List<_ParsedToken> _parseTokens(String text) {
    final tokens = <_ParsedToken>[];

    // Pattern for [text](url) - external links
    final linkPattern = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
    for (final match in linkPattern.allMatches(text)) {
      tokens.add(_ParsedToken(
        type: _TokenType.link,
        start: match.start,
        end: match.end,
        content: match.group(1)!,
        url: match.group(2),
      ));
    }

    // Pattern for [recipe:Name] - recipe links
    final recipePattern = RegExp(r'\[recipe:([^\]]+)\]');
    for (final match in recipePattern.allMatches(text)) {
      tokens.add(_ParsedToken(
        type: _TokenType.recipeLink,
        start: match.start,
        end: match.end,
        content: match.group(1)!,
      ));
    }

    // Pattern for **bold** - must be processed before single *
    final boldPattern = RegExp(r'\*\*([^*]+)\*\*');
    for (final match in boldPattern.allMatches(text)) {
      tokens.add(_ParsedToken(
        type: _TokenType.bold,
        start: match.start,
        end: match.end,
        content: match.group(1)!,
      ));
    }

    // Pattern for *italic* - single asterisks not part of **
    // This regex looks for * not preceded or followed by another *
    final italicAsteriskPattern = RegExp(r'(?<!\*)\*(?!\*)([^*]+)\*(?!\*)');
    for (final match in italicAsteriskPattern.allMatches(text)) {
      tokens.add(_ParsedToken(
        type: _TokenType.italic,
        start: match.start,
        end: match.end,
        content: match.group(1)!,
      ));
    }

    // Pattern for _italic_ - underscore style
    final italicUnderscorePattern = RegExp(r'_([^_]+)_');
    for (final match in italicUnderscorePattern.allMatches(text)) {
      tokens.add(_ParsedToken(
        type: _TokenType.italic,
        start: match.start,
        end: match.end,
        content: match.group(1)!,
      ));
    }

    // Detect duration expressions (e.g., "25 minutes", "1時間30分")
    if (widget.enableDurationLinks) {
      final detectedDurations = _durationService.detectDurations(text);
      for (final detected in detectedDurations) {
        tokens.add(_ParsedToken(
          type: _TokenType.duration,
          start: detected.startIndex,
          end: detected.endIndex,
          content: detected.matchedText,
          duration: detected.duration,
        ));
      }
    }

    // Sort by start position
    tokens.sort((a, b) => a.start.compareTo(b.start));

    // Remove overlapping tokens (keep the one that starts first)
    final filtered = <_ParsedToken>[];
    int lastEnd = 0;

    for (final token in tokens) {
      if (token.start >= lastEnd) {
        filtered.add(token);
        lastEnd = token.end;
      }
    }

    return filtered;
  }
}

enum _TokenType {
  bold,
  italic,
  link,
  recipeLink,
  duration,
}

class _ParsedToken {
  final _TokenType type;
  final int start;
  final int end;
  final String content;
  final String? url;
  final Duration? duration;

  _ParsedToken({
    required this.type,
    required this.start,
    required this.end,
    required this.content,
    this.url,
    this.duration,
  });
}
