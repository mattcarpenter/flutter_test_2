import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/app_text_field_simple.dart';
import '../../../widgets/folder_selection_row.dart';
import 'folder_selection_view_model.dart';

/// Page 1: Select existing folders with option to create new ones
class FolderSelectionPage {
  FolderSelectionPage._();

  static WoltModalSheetPage build(BuildContext context) {
    return WoltModalSheetPage(
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: false,
      isTopBarLayerAlwaysVisible: false,
      leadingNavBarWidget: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        onPressed: () {
          // Cancel - clean up temporary folders
          final viewModel = provider.Provider.of<FolderSelectionViewModel>(context, listen: false);
          viewModel.cancelAllChanges();
          Navigator.of(context).pop();
        },
        child: const Text('Cancel'),
      ),
      trailingNavBarWidget: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        onPressed: () async {
          // Save - convert temporary folders to real folders
          final viewModel = provider.Provider.of<FolderSelectionViewModel>(context, listen: false);
          final success = await viewModel.saveAllChanges();
          if (success && context.mounted) {
            Navigator.of(context).pop();
          }
          // If failed, stay on modal to show error
        },
        child: const Text('Save'),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
        child: const FolderSelectionPageContent(),
      ),
    );
  }
}

class FolderSelectionPageContent extends ConsumerWidget {
  const FolderSelectionPageContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    
    return provider.Consumer<FolderSelectionViewModel>(
      builder: (context, viewModel, child) {
        final allFolders = viewModel.getAllDisplayFolders();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title and Create button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Recipe to Folders',
                  style: AppTypography.h4.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                AppButton(
                  text: 'Create New Folder',
                  onPressed: () {
                    WoltModalSheet.of(context).showNext();
                  },
                  theme: AppButtonTheme.secondary,
                  style: AppButtonStyle.outline,
                  shape: AppButtonShape.square,
                  size: AppButtonSize.small,
                  leadingIcon: const Icon(Icons.add),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            
            // Error message if any
            if (viewModel.errorMessage != null) ...[
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.1),
                  border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colors.error, size: 20),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        viewModel.errorMessage!,
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg),
            ],
            
            // Folder list
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: allFolders.isEmpty
                    ? Center(
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
                              'Create your first folder using the button above',
                              style: AppTypography.bodySmall.copyWith(
                                color: colors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: allFolders.asMap().entries.map((entry) {
                              final index = entry.key;
                              final folder = entry.value;
                              final isFirst = index == 0;
                              final isLast = index == allFolders.length - 1;
                              final isSelected = viewModel.isFolderSelected(folder.id);

                              return FolderSelectionRow(
                                folderId: folder.id,
                                label: folder.name,
                                checked: isSelected,
                                first: isFirst,
                                last: isLast,
                                onToggle: () {
                                  viewModel.toggleFolderSelection(folder.id);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Page 2: Create a new folder
class CreateFolderPage {
  CreateFolderPage._();

  static WoltModalSheetPage build(BuildContext context) {
    return WoltModalSheetPage(
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: false,
      isTopBarLayerAlwaysVisible: false,
      leadingNavBarWidget: Padding(
        padding: EdgeInsets.only(left: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.back,
          variant: AppCircleButtonVariant.neutral,
          size: 32,
          onPressed: () {
            WoltModalSheet.of(context).showPrevious();
          },
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
        child: const CreateFolderPageContent(),
      ),
    );
  }
}

class CreateFolderPageContent extends StatefulWidget {
  const CreateFolderPageContent({super.key});

  @override
  State<CreateFolderPageContent> createState() => _CreateFolderPageContentState();
}

class _CreateFolderPageContentState extends State<CreateFolderPageContent> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createFolderAndReturn() {
    final viewModel = provider.Provider.of<FolderSelectionViewModel>(context, listen: false);
    final folderId = viewModel.createTemporaryFolder(_nameController.text);
    
    if (folderId.isNotEmpty) {
      // Success - clear form and return to selection page
      _nameController.clear();
      WoltModalSheet.of(context).showPrevious();
    }
    // If failed, stay on page to show error
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    return provider.Consumer<FolderSelectionViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Create New Folder',
              style: AppTypography.h4.copyWith(
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            
            // Folder name input
            Text(
              'Folder Name',
              style: AppTypography.label.copyWith(
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            AppTextFieldSimple(
              controller: _nameController,
              placeholder: 'Enter folder name',
              onChanged: (_) {
                setState(() {}); // Rebuild to update button state
                viewModel.clearError();
              },
              autofocus: true,
            ),
            SizedBox(height: AppSpacing.xl),
            
            // Create button
            AppButton(
              text: 'Create',
              onPressed: _nameController.text.trim().isEmpty ? null : _createFolderAndReturn,
              theme: AppButtonTheme.primary,
              style: AppButtonStyle.fill,
              shape: AppButtonShape.square,
              size: AppButtonSize.large,
              fullWidth: true,
            ),
          ],
        );
      },
    );
  }
}