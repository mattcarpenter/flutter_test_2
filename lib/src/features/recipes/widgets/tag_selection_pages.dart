import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../constants/tag_colors.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field_simple.dart';
import '../../../providers/recipe_tag_provider.dart';
import '../../../widgets/tag_selection_row.dart';
import '../../../widgets/wolt/button/wolt_modal_sheet_back_button.dart';
import 'tag_selection_view_model.dart';

/// Page 1: Select existing tags with option to create new ones
class TagSelectionPage {
  TagSelectionPage._();

  static WoltModalSheetPage build(BuildContext context) {
    return WoltModalSheetPage(
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: false,
      isTopBarLayerAlwaysVisible: false,
      leadingNavBarWidget: TextButton(
        onPressed: () {
          // Cancel - clean up temporary tags
          final viewModel = provider.Provider.of<TagSelectionViewModel>(context, listen: false);
          viewModel.cancelAllChanges();
          Navigator.of(context).pop();
        },
        child: const Text('Cancel'),
      ),
      trailingNavBarWidget: TextButton(
        onPressed: () async {
          // Save - convert temporary tags to real tags
          final viewModel = provider.Provider.of<TagSelectionViewModel>(context, listen: false);
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
        child: const TagSelectionPageContent(),
      ),
    );
  }
}

class TagSelectionPageContent extends ConsumerWidget {
  const TagSelectionPageContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    
    return provider.Consumer<TagSelectionViewModel>(
      builder: (context, viewModel, child) {
        final allTags = viewModel.getAllDisplayTags();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title and Create button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Tags',
                  style: AppTypography.h4.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                AppButton(
                  text: 'Create New Tag',
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
            
            // Tag list
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: allTags.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'No tags yet',
                              style: AppTypography.body.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'Create your first tag using the button above',
                              style: AppTypography.bodySmall.copyWith(
                                color: colors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: allTags.asMap().entries.map((entry) {
                            final index = entry.key;
                            final tag = entry.value;
                            final isFirst = index == 0;
                            final isLast = index == allTags.length - 1;
                            final isSelected = viewModel.isTagSelected(tag.id);

                            return TagSelectionRow(
                              tagId: tag.id,
                              label: tag.name,
                              color: tag.color,
                              checked: isSelected,
                              first: isFirst,
                              last: isLast,
                              onToggle: () {
                                viewModel.toggleTagSelection(tag.id);
                              },
                              onColorChanged: (newColor) {
                                // Handle color changes for existing tags
                                if (!tag.id.startsWith('temp_')) {
                                  ref.read(recipeTagNotifierProvider.notifier).updateTag(
                                    tagId: tag.id,
                                    color: newColor,
                                  );
                                }
                                // For temporary tags, we could update the temp tag color
                                // but for now, let's keep it simple
                              },
                            );
                          }).toList(),
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

/// Page 2: Create a new tag
class CreateTagPage {
  CreateTagPage._();

  static WoltModalSheetPage build(BuildContext context) {
    return WoltModalSheetPage(
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: false,
      isTopBarLayerAlwaysVisible: false,
      leadingNavBarWidget: WoltModalSheetBackButton(
        onBackPressed: () {
          WoltModalSheet.of(context).showPrevious();
        },
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
        child: const CreateTagPageContent(),
      ),
    );
  }
}

class CreateTagPageContent extends StatefulWidget {
  const CreateTagPageContent({super.key});

  @override
  State<CreateTagPageContent> createState() => _CreateTagPageContentState();
}

class _CreateTagPageContentState extends State<CreateTagPageContent> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedColor = TagColors.toHex(TagColors.defaultColor);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createTagAndReturn() {
    final viewModel = provider.Provider.of<TagSelectionViewModel>(context, listen: false);
    final tagId = viewModel.createTemporaryTag(_nameController.text, _selectedColor);
    
    if (tagId.isNotEmpty) {
      // Success - clear form and return to selection page
      _nameController.clear();
      _selectedColor = TagColors.toHex(TagColors.defaultColor);
      WoltModalSheet.of(context).showPrevious();
    }
    // If failed, stay on page to show error
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    return provider.Consumer<TagSelectionViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Create New Tag',
              style: AppTypography.h4.copyWith(
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            
            // Tag name input
            Text(
              'Tag Name',
              style: AppTypography.label.copyWith(
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            AppTextFieldSimple(
              controller: _nameController,
              placeholder: 'Enter tag name',
              onChanged: (_) {
                setState(() {}); // Rebuild to update button state
                viewModel.clearError();
              },
              autofocus: true,
            ),
            SizedBox(height: AppSpacing.xl),
            
            // Color selection
            Text(
              'Tag Color',
              style: AppTypography.label.copyWith(
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            
            // Color picker grid
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: TagColors.palette.map((color) {
                final colorHex = TagColors.toHex(color);
                final isSelected = colorHex == _selectedColor;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = colorHex;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? colors.textPrimary : colors.border,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 18,
                            color: TagColors.getContrastColor(color),
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            
            SizedBox(height: AppSpacing.xl),
            
            // Create button
            AppButton(
              text: 'Create',
              onPressed: _nameController.text.trim().isEmpty ? null : _createTagAndReturn,
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