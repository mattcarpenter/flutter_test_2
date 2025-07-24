import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../widgets/app_text_field.dart';
import '../../../../../widgets/app_text_field_condensed.dart';
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
        AppTextFieldCondensed(
          controller: titleController,
          placeholder: "Recipe Title",
          variant: AppTextFieldVariant.outline,
          first: true,
          last: false,
        ),
        AppTextFieldCondensed(
          controller: descriptionController,
          placeholder: "Description (optional)",
          variant: AppTextFieldVariant.outline,
          multiline: true,
          minLines: 2,
          first: false,
          last: true,
        ),
        const SizedBox(height: 12),

        // Timing group: Prep Time + Cook Time + Servings
        AppDurationPickerCondensed(
          controller: prepTimeController,
          placeholder: "Prep Time",
          variant: AppTextFieldVariant.outline,
          mode: DurationPickerMode.hoursMinutes,
          first: true,
          last: false,
        ),
        AppDurationPickerCondensed(
          controller: cookTimeController,
          placeholder: "Cook Time",
          variant: AppTextFieldVariant.outline,
          mode: DurationPickerMode.hoursMinutes,
          first: false,
          last: false,
        ),
        AppTextFieldCondensed(
          controller: servingsController,
          placeholder: "Servings",
          variant: AppTextFieldVariant.outline,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          first: false,
          last: true,
        ),
      ],
    );
  }
}
