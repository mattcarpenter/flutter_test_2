import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../widgets/app_text_field.dart';
import '../../../../../widgets/app_text_field_condensed.dart';
import '../../../../../widgets/app_text_field_group.dart';
import '../../../../../widgets/app_duration_picker.dart';
import '../../../../../widgets/app_duration_picker_condensed.dart';

class RecipeMetadataSection extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController servingsController;
  final TextEditingController prepTimeController;
  final TextEditingController cookTimeController;

  const RecipeMetadataSection({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.servingsController,
    required this.prepTimeController,
    required this.cookTimeController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        
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
        
        const SizedBox(height: 12),

        // Timing group: Prep Time + Cook Time + Servings
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
          ],
        ),
      ],
    );
  }
}
