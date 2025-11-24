import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../providers/tag_management_provider.dart';
import '../widgets/settings_group.dart';
import '../widgets/tag_management_row.dart';

class ManageTagsPage extends ConsumerWidget {
  const ManageTagsPage({super.key});

  void _showError(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagManagementState = ref.watch(tagManagementProvider);
    final tagManagementNotifier = ref.read(tagManagementProvider.notifier);
    final colors = AppColors.of(context);

    // Show error if there is one
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (tagManagementState.error != null) {
        _showError(context, tagManagementState.error!);
        tagManagementNotifier.clearError();
      }
    });

    return AdaptiveSliverPage(
      title: 'Manage Tags',
      automaticallyImplyLeading: true,
      previousPageTitle: 'Settings',
      slivers: [
        if (tagManagementState.isLoading)
          const SliverFillRemaining(
            child: Center(
              child: CupertinoActivityIndicator(),
            ),
          )
        else if (tagManagementState.tags.isEmpty)
          SliverFillRemaining(
            child: _buildEmptyState(context, colors),
          )
        else
          SliverToBoxAdapter(
            child: _buildTagsList(context, tagManagementState, tagManagementNotifier),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, AppColors colors) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.tag,
              size: 64,
              color: colors.textTertiary,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'No Tags Yet',
              style: AppTypography.h4.copyWith(
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Tags help you organize your recipes.\nCreate your first tag by adding one when editing a recipe.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsList(
    BuildContext context,
    TagManagementState state,
    TagManagementNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: AppSpacing.xl),

        // Tags section
        SettingsGroup(
          header: 'Your Tags',
          footer: 'Tap a color circle to change the tag color. Deleting a tag will remove it from all recipes.',
          children: state.tags.indexed.map((indexed) {
            final (index, tag) = indexed;
            final recipeCount = state.recipeCounts[tag.id] ?? 0;
            final isFirst = index == 0;
            final isLast = index == state.tags.length - 1;

            return TagManagementRow(
              tag: tag,
              recipeCount: recipeCount,
              isFirst: isFirst,
              isLast: isLast,
              onColorChanged: (color) {
                notifier.updateTagColor(tag.id, color);
              },
              onDelete: () {
                notifier.deleteTag(tag.id);
              },
            );
          }).toList(),
        ),

        // Bottom spacing
        SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
