import 'package:flutter/cupertino.dart';
import 'package:super_context_menu/super_context_menu.dart';
import '../../../../database/database.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

class ClippingCard extends StatelessWidget {
  final ClippingEntry clipping;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ClippingCard({
    super.key,
    required this.clipping,
    required this.onTap,
    required this.onDelete,
  });

  String _formatTimeAgo(int? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  String _getPreviewText() {
    final content = clipping.content;
    if (content == null || content.isEmpty) return '';

    // Try to extract plain text from Quill Delta JSON
    try {
      // Simple extraction - just remove JSON formatting for preview
      if (content.startsWith('[') || content.startsWith('{')) {
        // It's JSON, try to extract text
        final RegExp textPattern = RegExp(r'"insert"\s*:\s*"([^"]*)"');
        final matches = textPattern.allMatches(content);
        final buffer = StringBuffer();
        for (final match in matches) {
          buffer.write(match.group(1));
        }
        return buffer.toString().replaceAll('\\n', '\n').trim();
      }
      return content;
    } catch (_) {
      return content;
    }
  }

  String _getDisplayTitle() {
    final title = clipping.title;
    if (title != null && title.isNotEmpty) {
      return title;
    }

    // Extract from content preview
    final preview = _getPreviewText();
    if (preview.isEmpty) return 'Untitled';

    final firstLine = preview.split('\n').first;
    final words = firstLine.split(' ').take(6).join(' ');
    return words.isEmpty ? 'Untitled' : (words.length > 40 ? '${words.substring(0, 40)}...' : words);
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = _getDisplayTitle();
    final previewText = _getPreviewText();
    final timeAgo = _formatTimeAgo(clipping.updatedAt);

    return ContextMenuWidget(
      menuProvider: (_) {
        return Menu(
          children: [
            MenuAction(
              title: 'Delete',
              image: MenuImage.icon(CupertinoIcons.trash),
              attributes: const MenuActionAttributes(destructive: true),
              callback: onDelete,
            ),
          ],
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.of(context).surfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.hardEdge,
          child: Row(
            children: [
              // Preview thumbnail area
              Container(
                width: 70,
                height: 70,
                margin: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.of(context).surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.all(AppSpacing.xs),
                child: Text(
                  previewText,
                  style: TextStyle(
                    fontSize: 7,
                    height: 1.2,
                    color: AppColors.of(context).textSecondary,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.clip,
                ),
              ),

              // Text content area
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xs,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        displayTitle,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.of(context).textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (timeAgo.isNotEmpty) ...[
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          timeAgo,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.of(context).textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
