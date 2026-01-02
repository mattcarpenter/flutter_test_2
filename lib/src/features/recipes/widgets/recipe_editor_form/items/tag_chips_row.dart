import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../database/database.dart';
import '../../../../../constants/tag_colors.dart';
import '../../../../../providers/recipe_tag_provider.dart';
import '../../../../../theme/colors.dart';
import '../../../../../theme/spacing.dart';
import '../../../../../theme/typography.dart';
import '../../../../../localization/l10n_extension.dart';

/// A row displaying assigned tags as chips with an "Edit Tags" button
class TagChipsRow extends ConsumerWidget {
  final List<String> tagIds;
  final VoidCallback onEditTags;

  const TagChipsRow({
    super.key,
    required this.tagIds,
    required this.onEditTags,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(recipeTagNotifierProvider);
    
    return tagsAsync.when(
      data: (allTags) {
        final selectedTags = allTags
            .where((tag) => tagIds.contains(tag.id))
            .toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.recipeEditorTags,
                  style: AppTypography.fieldLabel.copyWith(
                    color: AppColors.of(context).textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: onEditTags,
                  child: Text(context.l10n.recipeEditorEditTags),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            if (selectedTags.isEmpty)
              Text(
                context.l10n.recipeEditorNoTagsAssigned,
                style: AppTypography.body.copyWith(
                  color: AppColors.of(context).textSecondary,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: selectedTags.map((tag) => 
                  TagChip(tag: tag)
                ).toList(),
              ),
          ],
        );
      },
      loading: () => const SizedBox(height: 48),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// A chip widget that displays a tag with its color indicator
class TagChip extends StatelessWidget {
  final RecipeTagEntry tag;

  const TagChip({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final tagColor = TagColors.fromHex(tag.color);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.1),
        border: Border.all(color: tagColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: tagColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            tag.name,
            style: AppTypography.caption.copyWith(
              color: AppColors.of(context).textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}