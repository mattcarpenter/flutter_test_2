import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../models/help_topic.dart';

/// An accordion widget for displaying a help topic.
/// Shows title with chevron; expands to show markdown content.
class HelpTopicAccordion extends StatelessWidget {
  final HelpTopic topic;
  final bool isExpanded;
  final VoidCallback onToggle;

  const HelpTopicAccordion({
    super.key,
    required this.topic,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header row (always visible)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToggle,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md + 2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    topic.title,
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    CupertinoIcons.chevron_down,
                    size: 16,
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expanded content
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildExpandedContent(context, colors),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context, AppColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Divider between title and content
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            height: 1,
            color: colors.border,
          ),
        ),

        // Markdown content
        Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: MarkdownBody(
            data: topic.content,
            selectable: true,
            styleSheet: _buildMarkdownStyleSheet(context, colors),
          ),
        ),
      ],
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(
    BuildContext context,
    AppColors colors,
  ) {
    return MarkdownStyleSheet(
      // Body text
      p: AppTypography.body.copyWith(
        color: colors.textSecondary,
        height: 1.5,
      ),

      // Headers (h2 and below since h1 is used for title)
      h2: AppTypography.h5.copyWith(
        color: colors.textPrimary,
      ),
      h3: AppTypography.bodyLarge.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),

      // Lists
      listBullet: AppTypography.body.copyWith(
        color: colors.textSecondary,
      ),

      // Strong/bold
      strong: AppTypography.body.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),

      // Emphasis/italic
      em: AppTypography.body.copyWith(
        color: colors.textSecondary,
        fontStyle: FontStyle.italic,
      ),

      // Code
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        color: colors.textPrimary,
        backgroundColor: colors.surfaceVariant,
      ),
      codeblockDecoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),

      // Block spacing
      blockSpacing: AppSpacing.md,
      listIndent: AppSpacing.lg,

      // Horizontal rule
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.border, width: 1),
        ),
      ),
    );
  }
}
