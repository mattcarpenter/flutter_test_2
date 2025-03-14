import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
        CupertinoTextField(
          controller: titleController,
          placeholder: "Recipe Title",
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Recipe Description
        CupertinoTextField(
          controller: descriptionController,
          placeholder: "Description (optional)",
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Recipe Details Row
        Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                controller: servingsController,
                placeholder: "Servings",
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CupertinoTextField(
                controller: prepTimeController,
                placeholder: "Prep Time (min)",
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CupertinoTextField(
                controller: cookTimeController,
                placeholder: "Cook Time (min)",
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Source Field
        CupertinoTextField(
          controller: sourceController,
          placeholder: "Source (optional)",
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}
