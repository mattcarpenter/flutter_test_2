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
  final TextEditingController sourceController;

  const RecipeMetadataSection({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.servingsController,
    required this.prepTimeController,
    required this.cookTimeController,
    required this.sourceController,
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

        // Servings - using condensed field
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: AppTextFieldCondensed(
                  controller: servingsController,
                  placeholder: "Servings",
                  variant: AppTextFieldVariant.outline,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const Expanded(flex: 1, child: SizedBox()), // Empty space
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Prep and Cook Time - using condensed duration pickers
        Row(
          children: [
            Expanded(
              child: AppDurationPickerCondensed(
                controller: prepTimeController,
                placeholder: "Prep Time",
                variant: AppTextFieldVariant.outline,
                mode: DurationPickerMode.hoursMinutes,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppDurationPickerCondensed(
                controller: cookTimeController,
                placeholder: "Cook Time",
                variant: AppTextFieldVariant.outline,
                mode: DurationPickerMode.hoursMinutes,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Source - using condensed field
        AppTextFieldCondensed(
          controller: sourceController,
          placeholder: "Source (optional)",
          variant: AppTextFieldVariant.outline,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }
}
