import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../constants/tag_colors.dart';
import '../../../providers/recipe_tag_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field_simple.dart';
import '../../../widgets/tag_selection_row.dart';

/// Show the tag selection modal
void showTagSelectionModal(
  BuildContext context, {
  required List<String> currentTagIds,
  required ValueChanged<List<String>> onTagIdsChanged,
}) {
  final GlobalKey<TagSelectionContentState> contentKey = 
      GlobalKey<TagSelectionContentState>();

  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      TagSelectionModalPage.build(
        context: context,
        currentTagIds: currentTagIds,
        onTagIdsChanged: onTagIdsChanged,
        contentKey: contentKey,
      ),
    ],
  );
}

class TagSelectionModalPage {
  TagSelectionModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required List<String> currentTagIds,
    required ValueChanged<List<String>> onTagIdsChanged,
    required GlobalKey<TagSelectionContentState> contentKey,
  }) {
    return WoltModalSheetPage(
      backgroundColor: AppColors.of(context).background,
      hasTopBarLayer: false,
      isTopBarLayerAlwaysVisible: false,
      leadingNavBarWidget: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      trailingNavBarWidget: TextButton(
        onPressed: () {
          contentKey.currentState?.saveChanges();
          Navigator.of(context).pop();
        },
        child: const Text('Save'),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
        child: TagSelectionContent(
          key: contentKey,
          currentTagIds: currentTagIds,
          onTagIdsChanged: onTagIdsChanged,
        ),
      ),
    );
  }
}

/// Content widget for tag selection
class TagSelectionContent extends ConsumerStatefulWidget {
  final List<String> currentTagIds;
  final ValueChanged<List<String>> onTagIdsChanged;

  const TagSelectionContent({
    super.key,
    required this.currentTagIds,
    required this.onTagIdsChanged,
  });

  @override
  ConsumerState<TagSelectionContent> createState() => TagSelectionContentState();
}

class TagSelectionContentState extends ConsumerState<TagSelectionContent> {
  late Set<String> _selectedTagIds;
  final TextEditingController _newTagController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedTagIds = Set<String>.from(widget.currentTagIds);
  }

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  void saveChanges() {
    widget.onTagIdsChanged(_selectedTagIds.toList());
  }

  Future<void> _addNewTag() async {
    final tagName = _newTagController.text.trim();
    
    if (tagName.isEmpty) {
      setState(() {
        _errorMessage = 'Tag name cannot be empty';
      });
      return;
    }

    // Check if tag name already exists
    final tagsAsync = ref.read(recipeTagNotifierProvider);
    if (tagsAsync.hasValue) {
      final existingTag = tagsAsync.value!.any((tag) => 
        tag.name.toLowerCase() == tagName.toLowerCase());
      if (existingTag) {
        setState(() {
          _errorMessage = 'A tag with this name already exists';
        });
        return;
      }
    }

    try {
      final userId = supabase_flutter.Supabase.instance.client.auth.currentUser?.id;
      // Use default color for new tags
      final newTagColor = TagColors.toHex(TagColors.defaultColor);
      final newTagId = await ref.read(recipeTagNotifierProvider.notifier).addTag(
        name: tagName,
        color: newTagColor,
        userId: userId,
      );
      
      // Auto-select the newly created tag
      if (newTagId != null) {
        setState(() {
          _selectedTagIds.add(newTagId);
          _errorMessage = null;
        });
      }
      
      // Clear the form
      _newTagController.clear();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create tag: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(recipeTagNotifierProvider);
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title row with Add Tag button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Tags',
              style: AppTypography.h4.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        
        // Tag list
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: tagsAsync.when(
              data: (tags) {
                if (tags.isEmpty) {
                  return Center(
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
                          'Create your first tag below',
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    children: tags.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tag = entry.value;
                      final isFirst = index == 0;
                      final isLast = index == tags.length - 1;
                      final isSelected = _selectedTagIds.contains(tag.id);

                      return TagSelectionRow(
                        tagId: tag.id,
                        label: tag.name,
                        color: tag.color,
                        checked: isSelected,
                        first: isFirst,
                        last: isLast,
                        onToggle: () {
                          setState(() {
                            if (isSelected) {
                              _selectedTagIds.remove(tag.id);
                            } else {
                              _selectedTagIds.add(tag.id);
                            }
                          });
                        },
                        onColorChanged: (newColor) {
                          ref.read(recipeTagNotifierProvider.notifier).updateTag(
                            tagId: tag.id,
                            color: newColor,
                          );
                        },
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading tags: $error',
                  style: AppTypography.body.copyWith(
                    color: colors.error,
                  ),
                ),
              ),
            ),
          ),
        ),
        
        SizedBox(height: AppSpacing.lg),
        
        // Add new tag section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Tag',
              style: AppTypography.fieldLabel.copyWith(
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            
            // Tag name input with color indicator
            Row(
              children: [
                Expanded(
                  child: AppTextFieldSimple(
                    controller: _newTagController,
                    placeholder: 'Enter tag name',
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() {
                          _errorMessage = null;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            
            if (_errorMessage != null) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage!,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.error,
                ),
              ),
            ],
            
            SizedBox(height: AppSpacing.lg),
            
            // Add tag button
            AppButton(
              text: 'Add Tag',
              onPressed: _addNewTag,
              theme: AppButtonTheme.primary,
              style: AppButtonStyle.fill,
              shape: AppButtonShape.square,
              size: AppButtonSize.medium,
              fullWidth: true,
            ),
          ],
        ),
      ],
    );
  }
}