import 'package:flutter/material.dart';
import 'app_button.dart';

void main() {
  runApp(const AppButtonDemoApp());
}

class AppButtonDemoApp extends StatelessWidget {
  const AppButtonDemoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Button Design System Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AppButtonDemo(),
    );
  }
}

/// Demo page showing all button variants from the design system
class AppButtonDemo extends StatelessWidget {
  const AppButtonDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Button Design System'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Headers
              const Row(
                children: [
                  SizedBox(width: 200), // Space for row labels
                  SizedBox(
                    width: 150,
                    child: Text(
                      'Default',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5E6970),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 24),
                  SizedBox(
                    width: 150,
                    child: Text(
                      'Hover',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5E6970),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            
            // Primary/Fill/Round
            _buildButtonRow(
              'Primary/Fill/Round',
              AppButton(
                text: 'Button',
                onPressed: () {},
                theme: AppButtonTheme.primary,
                style: AppButtonStyle.fill,
                shape: AppButtonShape.round,
              ),
            ),
            const SizedBox(height: 24),
            
            // Primary/Outline/Round
            _buildButtonRow(
              'Primary/Outline/Round',
              AppButton(
                text: 'Button',
                onPressed: () {},
                theme: AppButtonTheme.primary,
                style: AppButtonStyle.outline,
                shape: AppButtonShape.round,
              ),
            ),
            const SizedBox(height: 48),
            
            // Primary/Fill/Square
            _buildButtonRow(
              'Primary/Fill/Square',
              AppButton(
                text: 'Button',
                onPressed: () {},
                theme: AppButtonTheme.primary,
                style: AppButtonStyle.fill,
                shape: AppButtonShape.square,
              ),
            ),
            const SizedBox(height: 24),
            
            // Primary/Outline/Square
            _buildButtonRow(
              'Primary/Outline/Square',
              AppButton(
                text: 'Button',
                onPressed: () {},
                theme: AppButtonTheme.primary,
                style: AppButtonStyle.outline,
                shape: AppButtonShape.square,
              ),
            ),
            const SizedBox(height: 48),
            
            // Secondary/Fill/Round
            _buildButtonRow(
              'Secondary/Fill/Round',
              AppButton(
                text: 'Button',
                onPressed: () {},
                theme: AppButtonTheme.secondary,
                style: AppButtonStyle.fill,
                shape: AppButtonShape.round,
              ),
            ),
            const SizedBox(height: 24),
            
            // Secondary/Outline/Round
            _buildButtonRow(
              'Secondary/Outline/Round',
              AppButton(
                text: 'Button',
                onPressed: () {},
                theme: AppButtonTheme.secondary,
                style: AppButtonStyle.outline,
                shape: AppButtonShape.round,
              ),
            ),
            const SizedBox(height: 48),
            
            // Secondary/Fill/Square
            _buildButtonRow(
              'Secondary/Fill/Square',
              AppButton(
                text: 'Button',
                onPressed: () {},
                theme: AppButtonTheme.secondary,
                style: AppButtonStyle.fill,
                shape: AppButtonShape.square,
              ),
            ),
            const SizedBox(height: 24),
            
            // Secondary/Outline/Square
            _buildButtonRow(
              'Secondary/Outline/Square',
              AppButton(
                text: 'Button',
                onPressed: () {},
                theme: AppButtonTheme.secondary,
                style: AppButtonStyle.outline,
                shape: AppButtonShape.square,
              ),
            ),
            
            const SizedBox(height: 48),
            const Divider(),
            const SizedBox(height: 24),
            
            // Additional examples
            const Text(
              'Additional Examples',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Different sizes
            const Text(
              'Sizes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                AppButton(
                  text: 'Small',
                  onPressed: () {},
                  size: AppButtonSize.small,
                ),
                const SizedBox(width: 16),
                AppButton(
                  text: 'Medium',
                  onPressed: () {},
                  size: AppButtonSize.medium,
                ),
                const SizedBox(width: 16),
                AppButton(
                  text: 'Large',
                  onPressed: () {},
                  size: AppButtonSize.large,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // With icons
            const Text(
              'With Icons',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                AppButton(
                  text: 'Download',
                  onPressed: () {},
                  leadingIcon: const Icon(Icons.download),
                ),
                const SizedBox(width: 16),
                AppButton(
                  text: 'Next',
                  onPressed: () {},
                  trailingIcon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // States
            const Text(
              'States',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const AppButton(
                  text: 'Disabled',
                  onPressed: null,
                ),
                const SizedBox(width: 16),
                AppButton(
                  text: 'Loading',
                  onPressed: () {},
                  loading: true,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Convenience constructors
            const Text(
              'Convenience Constructors',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                AppButtonVariants.primaryFilled(
                  text: 'Primary Filled',
                  onPressed: () {},
                ),
                AppButtonVariants.primaryOutline(
                  text: 'Primary Outline',
                  onPressed: () {},
                ),
                AppButtonVariants.secondaryFilled(
                  text: 'Secondary Filled',
                  onPressed: () {},
                ),
                AppButtonVariants.secondaryOutline(
                  text: 'Secondary Outline',
                  onPressed: () {},
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Full width buttons
            const Text(
              'Full Width Buttons',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 400,
              child: Column(
                children: [
                  AppButton(
                    text: 'Full Width Primary',
                    onPressed: () {},
                    fullWidth: true,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'Full Width Secondary',
                    onPressed: () {},
                    theme: AppButtonTheme.secondary,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'Full Width Outline',
                    onPressed: () {},
                    style: AppButtonStyle.outline,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonRow(String label, Widget button) {
    return Row(
      children: [
        SizedBox(
          width: 200,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5E6970),
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 24),
        SizedBox(
          width: 150,
          child: Center(child: button),
        ),
        const SizedBox(width: 24),
        SizedBox(
          width: 150,
          child: Center(
            child: Text(
              '(Hover to see)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ],
    );
  }
}