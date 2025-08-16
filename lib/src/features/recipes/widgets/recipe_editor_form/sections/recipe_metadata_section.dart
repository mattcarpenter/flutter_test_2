import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../widgets/app_text_field.dart';
import '../../../../../widgets/app_text_field_condensed.dart';
import '../../../../../widgets/app_text_field_group.dart';
import '../../../../../widgets/app_duration_picker.dart';
import '../../../../../widgets/app_duration_picker_condensed.dart';
import '../../../../../theme/spacing.dart';
import '../items/folder_assignment_row.dart';

class RecipeMetadataSection extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController servingsController;
  final TextEditingController prepTimeController;
  final TextEditingController cookTimeController;
  final List<String> currentFolderIds;
  final ValueChanged<List<String>> onFolderIdsChanged;

  const RecipeMetadataSection({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.servingsController,
    required this.prepTimeController,
    required this.cookTimeController,
    required this.currentFolderIds,
    required this.onFolderIdsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        
        // Title and Description grouped together
        AppTextFieldGroup(
          variant: AppTextFieldVariant.outline,
          children: [
            AppTextFieldCondensed(
              controller: titleController,
              placeholder: "Recipe Title",
              grouped: true,
            ),
            AppTextFieldCondensed(
              controller: descriptionController,
              placeholder: "Description (optional)",
              multiline: true,
              minLines: 2,
              grouped: true,
            ),
          ],
        ),
        
        const SizedBox(height: AppSpacing.md),

        // Timing group: Prep Time + Cook Time + Servings + Folders
        AppTextFieldGroup(
          variant: AppTextFieldVariant.outline,
          children: [
            AppDurationPickerCondensed(
              controller: prepTimeController,
              placeholder: "Prep Time",
              mode: DurationPickerMode.hoursMinutes,
              grouped: true,
            ),
            AppDurationPickerCondensed(
              controller: cookTimeController,
              placeholder: "Cook Time",
              mode: DurationPickerMode.hoursMinutes,
              grouped: true,
            ),
            AppTextFieldCondensed(
              controller: servingsController,
              placeholder: "Servings",
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              grouped: true,
            ),
            FolderAssignmentRow(
              currentFolderIds: currentFolderIds,
              onFolderIdsChanged: onFolderIdsChanged,
              grouped: true,
            ),
          ],
        ),
      ],
    );
  }
}
