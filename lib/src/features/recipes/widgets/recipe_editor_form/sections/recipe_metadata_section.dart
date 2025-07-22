import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../widgets/app_text_field.dart';
import '../../../../../widgets/app_duration_picker.dart';
import '../../../../../widgets/section_header.dart';

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
        // Title - full width
        AppTextField(
          controller: titleController,
          placeholder: "Recipe Title",
          variant: AppTextFieldVariant.outline,
        ),
        const SizedBox(height: 6),

        // Description - full width
        AppTextField(
          controller: descriptionController,
          placeholder: "Description (optional)",
          variant: AppTextFieldVariant.outline,
          multiline: true,
        ),
        const SizedBox(height: 6),

        // Servings - half width, on its own row
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: AppTextField(
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
        const SizedBox(height: 6),

        // Prep and Cook Time - each half width
        Row(
          children: [
            Expanded(
              child: AppDurationPicker(
                controller: prepTimeController,
                placeholder: "Prep Time",
                variant: AppTextFieldVariant.outline,
                mode: DurationPickerMode.hoursMinutes,
              ),
            ),
            const SizedBox(width: 6),
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
        const SizedBox(height: 6),

        // Source - full width
        AppTextField(
          controller: sourceController,
          placeholder: "Source (optional)",
          variant: AppTextFieldVariant.outline,
        ),
      ],
    );
  }
}
