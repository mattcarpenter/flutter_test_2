import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../../widgets/app_text_field.dart';
import '../../../../../widgets/app_duration_picker.dart';

class RecipeMetadataSection extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController servingsController;
  final TextEditingController prepTimeController;
  final TextEditingController cookTimeController;
  final TextEditingController sourceController;

  const RecipeMetadataSection({
    Key? key,
    required this.titleController,
    required this.descriptionController,
    required this.servingsController,
    required this.prepTimeController,
    required this.cookTimeController,
    required this.sourceController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipe Title
        AppTextField(
          controller: titleController,
          placeholder: "Recipe Title",
          variant: AppTextFieldVariant.outline,
        ),
        const SizedBox(height: 16),

        // Recipe Description
        AppTextField(
          controller: descriptionController,
          placeholder: "Description (optional)",
          variant: AppTextFieldVariant.outline,
          multiline: true,
        ),
        const SizedBox(height: 16),

        // Recipe Details Row
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: servingsController,
                placeholder: "Servings",
                variant: AppTextFieldVariant.outline,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppDurationPicker(
                controller: prepTimeController,
                placeholder: "Prep Time",
                variant: AppTextFieldVariant.outline,
                mode: DurationPickerMode.hoursMinutes,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppDurationPicker(
                controller: cookTimeController,
                placeholder: "Cook Time",
                variant: AppTextFieldVariant.outline,
                mode: DurationPickerMode.hoursMinutes,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Source Field
        AppTextField(
          controller: sourceController,
          placeholder: "Source (optional)",
          variant: AppTextFieldVariant.outline,
        ),
      ],
    );
  }
}
