import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../localization/l10n_extension.dart';
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
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(context.l10n.commonError),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(context.l10n.commonOk),
            onPressed: () => Navigator.of(dialogContext).pop(),
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
      title: context.l10n.settingsManageTags,
      automaticallyImplyLeading: true,
      previousPageTitle: context.l10n.settingsTitle,
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
            HugeIcon(
              icon: HugeIcons.strokeRoundedTag01,
              size: 64,
              color: colors.textTertiary,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.settingsTagsNoTagsTitle,
              style: AppTypography.h4.copyWith(
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.settingsTagsNoTagsDescription,
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
          header: context.l10n.settingsTagsYourTags,
          footer: context.l10n.settingsTagsDescription,
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
