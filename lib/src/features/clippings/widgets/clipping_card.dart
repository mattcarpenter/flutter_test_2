import 'package:flutter/cupertino.dart';
import 'package:super_context_menu/super_context_menu.dart';
import '../../../../database/database.dart';
import '../../../localization/l10n_extension.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../utils/quill_text_extractor.dart';

/// A card widget for displaying a clipping in a grid layout.
/// Shows a preview area on top and the title below.
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

  String _getPreviewText() {
    return extractPlainTextFromQuillJson(clipping.content);
  }

  String _getDisplayTitle(String untitledLabel) {
    final title = clipping.title;
    if (title != null && title.isNotEmpty) {
      return title;
    }

    // Extract from content preview
    final preview = _getPreviewText();
    if (preview.isEmpty) return untitledLabel;

    final firstLine = preview.split('\n').first;
    final words = firstLine.split(' ').take(6).join(' ');
    return words.isEmpty
        ? untitledLabel
        : (words.length > 40 ? '${words.substring(0, 40)}...' : words);
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = _getDisplayTitle(context.l10n.clippingsUntitled);
    final previewText = _getPreviewText();

    return ContextMenuWidget(
      menuProvider: (_) {
        return Menu(
          children: [
            MenuAction(
              title: context.l10n.commonDelete,
              image: MenuImage.icon(CupertinoIcons.delete),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview area - takes most of the space
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: Text(
                    previewText,
                    style: TextStyle(
                      fontSize: 8,
                      height: 1.3,
                      color: AppColors.of(context).textSecondary,
                    ),
                    maxLines: 8,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ),

              // Title area at bottom
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Text(
                  displayTitle,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.of(context).textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
