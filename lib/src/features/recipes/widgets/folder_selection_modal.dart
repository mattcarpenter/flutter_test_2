import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_checkbox_group.dart';
import '../../../widgets/wolt/text/modal_sheet_title.dart';
import '../../../providers/recipe_folder_provider.dart';
import '../views/add_folder_modal.dart';

void showFolderSelectionModal(
  BuildContext context, {
  required List<String> currentFolderIds,
  required ValueChanged<List<String>> onFolderIdsChanged,
}) {
  final GlobalKey<FolderSelectionContentState> contentKey = GlobalKey<FolderSelectionContentState>();

  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      FolderSelectionModalPage.build(
        context: context,
        currentFolderIds: currentFolderIds,
        onFolderIdsChanged: onFolderIdsChanged,
        contentKey: contentKey,
      ),
    ],
  );
}

class FolderSelectionModalPage {
  FolderSelectionModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required List<String> currentFolderIds,
    required ValueChanged<List<String>> onFolderIdsChanged,
    required GlobalKey<FolderSelectionContentState> contentKey,
  }) {
    return WoltModalSheetPage(
      backgroundColor: AppColors.of(context).background,
      // Removed hasTopBarLayer and isTopBarLayerAlwaysVisible to eliminate border
      hasTopBarLayer: false,
      isTopBarLayerAlwaysVisible: false,
      leadingNavBarWidget: TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Cancel'),
      ),
      trailingNavBarWidget: TextButton(
        onPressed: () {
          // Save changes and close
          contentKey.currentState?.saveChanges();
          Navigator.of(context).pop();
        },
        child: const Text('Save'),
      ),
      child: Padding(
        // Extra top padding for better spacing above title
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title row with Add Folder button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Recipe to Folders',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.of(context).textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    showAddFolderModal(context).then((newFolderName) {
                      if (newFolderName != null) {
                        // The folder was created, recipeFolderNotifierProvider will update
                      }
                    });
                  },
                  child: const Text('Add Folder'),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            FolderSelectionContent(
              key: contentKey,
              currentFolderIds: currentFolderIds,
              onFolderIdsChanged: onFolderIdsChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class FolderSelectionContent extends ConsumerStatefulWidget {
  final List<String> currentFolderIds;
  final ValueChanged<List<String>> onFolderIdsChanged;

  const FolderSelectionContent({
    super.key,
    required this.currentFolderIds,
    required this.onFolderIdsChanged,
  });

  @override
  ConsumerState<FolderSelectionContent> createState() => FolderSelectionContentState();
}

class FolderSelectionContentState extends ConsumerState<FolderSelectionContent> {
  late Set<String> _selectedFolderIds;

  @override
  void initState() {
    super.initState();
    _selectedFolderIds = Set<String>.from(widget.currentFolderIds);
  }

  void saveChanges() {
    widget.onFolderIdsChanged(_selectedFolderIds.toList());
  }


  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(recipeFolderNotifierProvider);
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Folder list
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: foldersAsync.when(
              data: (folders) {
                if (folders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No folders yet',
                          style: AppTypography.body.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          'Create your first folder to organize recipes',
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Convert folders to checkbox options
                final folderOptions = folders.map((folder) =>
                  CheckboxOption<String>(
                    value: folder.id,
                    label: folder.name,
                  )
                ).toList();

                return AppCheckboxGroup<String>(
                  options: folderOptions,
                  selectedValues: _selectedFolderIds,
                  onChanged: (newSelection) {
                    setState(() {
                      _selectedFolderIds = newSelection;
                    });
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading folders: $error',
                  style: AppTypography.body.copyWith(
                    color: colors.error,
                  ),
                ),
              ),
            ),
          ),
        ),

      ],
    );
  }
}
