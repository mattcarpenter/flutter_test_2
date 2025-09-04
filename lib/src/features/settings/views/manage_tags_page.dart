import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
      body: tagManagementState.isLoading
          ? const Center(
              child: CupertinoActivityIndicator(),
            )
          : RefreshIndicator(
              onRefresh: () => tagManagementNotifier.refresh(),
              child: tagManagementState.tags.isEmpty
                  ? _buildEmptyState(context, colors)
                  : _buildTagsList(context, tagManagementState, tagManagementNotifier),
            ),
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
              color: colors.textSecondary,
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
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.md),
          
          // Tags section
          SettingsGroup(
            children: state.tags.map((tag) {
              final recipeCount = state.recipeCounts[tag.id] ?? 0;
              
              return TagManagementRow(
                tag: tag,
                recipeCount: recipeCount,
                onColorChanged: (color) {
                  notifier.updateTagColor(tag.id, color);
                },
                onDelete: () {
                  notifier.deleteTag(tag.id);
                },
              );
            }).toList(),
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // Help text
          Text(
            'Tap a color circle to change the tag color. '
            'Deleting a tag will remove it from all recipes.',
            style: AppTypography.caption.copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}