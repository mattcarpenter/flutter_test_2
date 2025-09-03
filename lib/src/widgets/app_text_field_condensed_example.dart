import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_text_field_condensed.dart';
import 'app_duration_picker_condensed.dart';
import 'app_duration_picker.dart' show DurationPickerMode;

class AppTextFieldCondensedExample extends StatefulWidget {
  const AppTextFieldCondensedExample({Key? key}) : super(key: key);

  @override
  State<AppTextFieldCondensedExample> createState() => _AppTextFieldCondensedExampleState();
}

class _AppTextFieldCondensedExampleState extends State<AppTextFieldCondensedExample> {
  final _titleController = TextEditingController();
  final _servingsController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _sourceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _servingsController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _sourceController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('AppTextFieldCondensed Example'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Single-line Condensed Fields',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Single condensed fields
              AppTextFieldCondensed(
                controller: _titleController,
                placeholder: 'Recipe Title',
                variant: AppTextFieldVariant.outline,
              ),
              const SizedBox(height: 8),
              
              AppTextFieldCondensed(
                controller: _servingsController,
                placeholder: 'Servings',
                variant: AppTextFieldVariant.outline,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              
              AppTextFieldCondensed(
                controller: _prepTimeController,
                placeholder: 'Prep Time',
                variant: AppTextFieldVariant.outline,
              ),
              const SizedBox(height: 8),
              
              AppTextFieldCondensed(
                controller: _cookTimeController,
                placeholder: 'Cook Time',
                variant: AppTextFieldVariant.outline,
              ),
              const SizedBox(height: 8),
              
              AppTextFieldCondensed(
                controller: _sourceController,
                placeholder: 'Source URL',
                variant: AppTextFieldVariant.outline,
                keyboardType: TextInputType.url,
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'Grouped Condensed Fields',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Title/Description Group
              AppTextFieldCondensed(
                controller: TextEditingController(text: 'Chocolate Cake'),
                placeholder: 'Recipe Title',
                variant: AppTextFieldVariant.outline,
                first: true,
                last: false,
              ),
              AppTextFieldCondensed(
                controller: TextEditingController(text: 'A rich, moist chocolate cake perfect for any occasion'),
                placeholder: 'Description',
                variant: AppTextFieldVariant.outline,
                multiline: true,
                minLines: 2,
                first: false,
                last: true,
              ),
              
              const SizedBox(height: 16),
              
              // Timing Group
              AppTextFieldCondensed(
                controller: TextEditingController(text: '4'),
                placeholder: 'Servings',
                variant: AppTextFieldVariant.outline,
                first: true,
                last: false,
              ),
              AppTextFieldCondensed(
                controller: TextEditingController(text: '15 min'),
                placeholder: 'Prep Time',
                variant: AppTextFieldVariant.outline,
                first: false,
                last: false,
              ),
              AppTextFieldCondensed(
                controller: TextEditingController(text: '30 min'),
                placeholder: 'Cook Time',
                variant: AppTextFieldVariant.outline,
                first: false,
                last: true,
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'Multiline Fields',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Multiline fields
              AppTextFieldCondensed(
                controller: _descriptionController,
                placeholder: 'Description',
                variant: AppTextFieldVariant.outline,
                multiline: true,
                minLines: 2,
              ),
              const SizedBox(height: 8),
              
              AppTextFieldCondensed(
                controller: _notesController,
                placeholder: 'Recipe Notes',
                variant: AppTextFieldVariant.outline,
                multiline: true,
                minLines: 3,
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'Form Hierarchy Groups',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Servings - standalone
              AppTextFieldCondensed(
                controller: TextEditingController(text: '4'),
                placeholder: 'Servings',
                variant: AppTextFieldVariant.outline,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                first: true,
                last: true,
              ),
              const SizedBox(height: 8),
              
              // Timing group
              AppDurationPickerCondensed(
                controller: TextEditingController(text: '15'),
                placeholder: 'Prep Time',
                variant: AppTextFieldVariant.outline,
                mode: DurationPickerMode.hoursMinutes,
                first: true,
                last: false,
              ),
              AppDurationPickerCondensed(
                controller: TextEditingController(text: '30'),
                placeholder: 'Cook Time',
                variant: AppTextFieldVariant.outline,
                mode: DurationPickerMode.hoursMinutes,
                first: false,
                last: true,
              ),
              const SizedBox(height: 8),
              
              // Source - standalone
              AppTextFieldCondensed(
                controller: TextEditingController(text: 'example.com/recipe'),
                placeholder: 'Source',
                variant: AppTextFieldVariant.outline,
                keyboardType: TextInputType.url,
                first: true,
                last: true,
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'Filled Variant',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              AppTextFieldCondensed(
                controller: TextEditingController(text: 'Chocolate Cake'),
                placeholder: 'Recipe Title',
                variant: AppTextFieldVariant.filled,
              ),
              const SizedBox(height: 8),
              
              AppTextFieldCondensed(
                controller: TextEditingController(),
                placeholder: 'Disabled Field',
                variant: AppTextFieldVariant.filled,
                enabled: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}