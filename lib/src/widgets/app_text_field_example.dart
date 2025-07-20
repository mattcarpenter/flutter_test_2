import 'package:flutter/material.dart';
import 'app_text_field.dart';

// Example usage of AppTextField widget
class AppTextFieldExample extends StatefulWidget {
  const AppTextFieldExample({Key? key}) : super(key: key);

  @override
  State<AppTextFieldExample> createState() => _AppTextFieldExampleState();
}

class _AppTextFieldExampleState extends State<AppTextFieldExample> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _emailError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('AppTextField Examples'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Outline Variant',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Basic outline field
            AppTextField(
              controller: _nameController,
              placeholder: 'First name',
              variant: AppTextFieldVariant.outline,
            ),
            
            const SizedBox(height: 24),
            
            // Outline field with error
            AppTextField(
              controller: _emailController,
              placeholder: 'Email address',
              variant: AppTextFieldVariant.outline,
              keyboardType: TextInputType.emailAddress,
              errorText: _emailError,
              onChanged: (value) {
                setState(() {
                  if (value.isEmpty) {
                    _emailError = null;
                  } else if (!value.contains('@')) {
                    _emailError = 'Please enter a valid email';
                  } else {
                    _emailError = null;
                  }
                });
              },
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),
            
            const Text(
              'Filled Variant',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Filled password field
            AppTextField(
              controller: _passwordController,
              placeholder: 'Password',
              variant: AppTextFieldVariant.filled,
              obscureText: true,
              suffix: IconButton(
                icon: const Icon(Icons.visibility_outlined),
                onPressed: () {
                  // Toggle password visibility
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Filled multiline field
            AppTextField(
              controller: _notesController,
              placeholder: 'Notes',
              variant: AppTextFieldVariant.filled,
              maxLines: 3,
            ),
            
            const SizedBox(height: 24),
            
            // Disabled field
            AppTextField(
              controller: TextEditingController(text: 'Disabled field'),
              placeholder: 'Disabled',
              variant: AppTextFieldVariant.filled,
              enabled: false,
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),
            
            const Text(
              'With Prefix/Suffix',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Field with prefix icon
            AppTextField(
              controller: TextEditingController(),
              placeholder: 'Search',
              variant: AppTextFieldVariant.outline,
              prefix: const Icon(Icons.search, size: 20, color: Colors.grey),
            ),
            
            const SizedBox(height: 24),
            
            // Field with suffix action
            AppTextField(
              controller: TextEditingController(),
              placeholder: 'Username',
              variant: AppTextFieldVariant.outline,
              suffix: TextButton(
                onPressed: () {
                  // Check availability
                },
                child: const Text('Check'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}