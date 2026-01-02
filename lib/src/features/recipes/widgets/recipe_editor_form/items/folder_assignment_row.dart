import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../theme/colors.dart';
import '../../../../../theme/typography.dart';
import '../../../../../localization/l10n_extension.dart';
import '../../../../../providers/recipe_folder_provider.dart';
import '../../folder_selection_modal.dart';

class FolderAssignmentRow extends ConsumerWidget {
  final List<String> currentFolderIds;
  final ValueChanged<List<String>> onFolderIdsChanged;
  final bool grouped;

  const FolderAssignmentRow({
    super.key,
    required this.currentFolderIds,
    required this.onFolderIdsChanged,
    this.grouped = false,
  });

  String _getFolderDisplayText(BuildContext context, List<String> folderIds) {
    if (folderIds.isEmpty) {
      return context.l10n.recipeEditorNoFolders;
    } else if (folderIds.length == 1) {
      return context.l10n.recipeEditorOneFolder;
    } else {
      return context.l10n.recipeEditorFolderCount(folderIds.length);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final foldersAsync = ref.watch(recipeFolderNotifierProvider);
    
    return GestureDetector(
      onTap: () {
        showFolderSelectionModal(
          context,
          currentFolderIds: currentFolderIds,
          onFolderIdsChanged: onFolderIdsChanged,
          ref: ref,
        );
      },
      child: Container(
        height: 48, // Match other condensed field heights
        decoration: BoxDecoration(
          border: grouped
              ? null
              : Border.all(
                  color: colors.border,
                  width: 1,
                ),
          borderRadius: grouped
              ? null
              : BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              context.l10n.recipeEditorFolders,
              style: AppTypography.fieldInput.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            foldersAsync.when(
              data: (folders) {
                return Text(
                  _getFolderDisplayText(context, currentFolderIds),
                  style: AppTypography.fieldInput.copyWith(
                    color: colors.textSecondary,
                  ),
                );
              },
              loading: () => Text(
                context.l10n.commonLoading,
                style: AppTypography.fieldInput.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              error: (_, __) => Text(
                _getFolderDisplayText(context, currentFolderIds),
                style: AppTypography.fieldInput.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: colors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}