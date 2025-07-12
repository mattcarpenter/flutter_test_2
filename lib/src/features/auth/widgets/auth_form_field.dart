import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../widgets/wolt/text/app_text_form_field.dart';

class AuthFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? placeholder;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool enabled;
  final bool autofocus;
  final List<String>? autofillHints;

  const AuthFormField({
    super.key,
    this.controller,
    required this.label,
    this.placeholder,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    // Use AppTextFormField for forms with validation (all platforms)
    // This provides better error handling and validation UI
    if (validator != null) {
      return AppTextFormField(
        controller: controller,
        labelText: label,
        obscureText: obscureText,
        textInputType: keyboardType,
        textInputAction: textInputAction,
        onValidate: validator,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        focusNode: focusNode,
        enabled: enabled,
        autocorrect: !obscureText,
        autofillHints: autofillHints,
        autoValidateMode: AutovalidateMode.onUserInteraction,
      );
    }

    // Use platform-specific simple fields for non-validated inputs
    if (Platform.isIOS) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder ?? label,
        obscureText: obscureText,
        keyboardType: keyboardType ?? TextInputType.text,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        focusNode: focusNode,
        enabled: enabled,
        autofocus: autofocus,
        decoration: BoxDecoration(
          border: Border.all(
            color: CupertinoColors.systemGrey4,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.all(12.0),
      );
    } else {
      return TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType ?? TextInputType.text,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        focusNode: focusNode,
        enabled: enabled,
        autofocus: autofocus,
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.all(12.0),
        ),
      );
    }
  }
}

// Email field with built-in validation
class EmailFormField extends StatelessWidget {
  final TextEditingController? controller;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  const EmailFormField({
    super.key,
    this.controller,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
  });

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormField(
      controller: controller,
      label: 'Email',
      placeholder: 'your@email.com',
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: _validateEmail,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: autofocus,
      autofillHints: const [AutofillHints.email],
    );
  }
}

// Password field with built-in validation
class PasswordFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool requireValidation;
  final TextInputAction? textInputAction;

  const PasswordFormField({
    super.key,
    this.controller,
    this.label = 'Password',
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.requireValidation = true,
    this.textInputAction,
  });

  String? _validatePassword(String? value) {
    if (!requireValidation) return null;
    
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormField(
      controller: controller,
      label: label,
      obscureText: true,
      textInputAction: textInputAction ?? TextInputAction.done,
      validator: requireValidation ? _validatePassword : null,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      enabled: enabled,
      autofillHints: const [AutofillHints.password],
    );
  }
}

// Confirm password field with validation against another password
class ConfirmPasswordFormField extends StatelessWidget {
  final TextEditingController? controller;
  final TextEditingController passwordController;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const ConfirmPasswordFormField({
    super.key,
    this.controller,
    required this.passwordController,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  String? _validatePasswordConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormField(
      controller: controller,
      label: 'Confirm Password',
      obscureText: true,
      textInputAction: TextInputAction.done,
      validator: _validatePasswordConfirm,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      enabled: enabled,
      autofillHints: const [AutofillHints.password],
    );
  }
}