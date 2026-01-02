import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../localization/l10n_extension.dart';

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
  final bool autocorrect;
  final bool enableSuggestions;
  final TextCapitalization textCapitalization;

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
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    // Use platform-adaptive form fields with proper validation
    if (Platform.isIOS) {
      return _buildCupertinoFormField(context);
    } else {
      return _buildMaterialFormField(context);
    }
  }

  Widget _buildCupertinoFormField(BuildContext context) {
    if (validator != null) {
      // For fields with validation, use FormField wrapper
      return FormField<String>(
        initialValue: controller?.text,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        builder: (FormFieldState<String> field) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CupertinoTextField(
                controller: controller,
                placeholder: placeholder ?? label,
                obscureText: obscureText,
                keyboardType: keyboardType ?? TextInputType.text,
                textInputAction: textInputAction,
                autocorrect: autocorrect,
                enableSuggestions: enableSuggestions,
                textCapitalization: textCapitalization,
                onChanged: (value) {
                  field.didChange(value);
                  onChanged?.call(value);
                },
                onSubmitted: onSubmitted,
                focusNode: focusNode,
                enabled: enabled,
                autofocus: autofocus,
                autofillHints: autofillHints,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: field.hasError
                        ? CupertinoColors.destructiveRed
                        : CupertinoColors.systemGrey4,
                    width: field.hasError ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.all(12.0),
              ),
              if (field.hasError) ...[
                const SizedBox(height: 6),
                Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: CupertinoColors.destructiveRed,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          );
        },
      );
    } else {
      // Simple field without validation
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder ?? label,
        obscureText: obscureText,
        keyboardType: keyboardType ?? TextInputType.text,
        textInputAction: textInputAction,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        textCapitalization: textCapitalization,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        focusNode: focusNode,
        enabled: enabled,
        autofocus: autofocus,
        autofillHints: autofillHints,
        decoration: BoxDecoration(
          border: Border.all(
            color: CupertinoColors.systemGrey4,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.all(12.0),
      );
    }
  }

  Widget _buildMaterialFormField(BuildContext context) {
    if (validator != null) {
      // Use TextFormField for validation
      return TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType ?? TextInputType.text,
        textInputAction: textInputAction,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        textCapitalization: textCapitalization,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        focusNode: focusNode,
        enabled: enabled,
        autofocus: autofocus,
        autofillHints: autofillHints,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.all(12.0),
        ),
      );
    } else {
      // Simple field without validation
      return TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType ?? TextInputType.text,
        textInputAction: textInputAction,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        textCapitalization: textCapitalization,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        focusNode: focusNode,
        enabled: enabled,
        autofocus: autofocus,
        autofillHints: autofillHints,
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

  String? _validateEmail(String? value, BuildContext context) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.authEmailRequired;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return context.l10n.authEmailInvalid;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormField(
      controller: controller,
      label: context.l10n.authEmailLabel,
      placeholder: context.l10n.authEmailPlaceholder,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enableSuggestions: false,
      validator: (value) => _validateEmail(value, context),
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
  final String? label;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool requireValidation;
  final TextInputAction? textInputAction;

  const PasswordFormField({
    super.key,
    this.controller,
    this.label,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.requireValidation = true,
    this.textInputAction,
  });

  String? _validatePassword(String? value, BuildContext context) {
    if (!requireValidation) return null;

    if (value == null || value.isEmpty) {
      return context.l10n.authPasswordRequired;
    }

    if (value.length < 6) {
      return context.l10n.authPasswordTooShort;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormField(
      controller: controller,
      label: label ?? context.l10n.authPasswordLabel,
      obscureText: true,
      textInputAction: textInputAction ?? TextInputAction.done,
      validator: requireValidation ? (value) => _validatePassword(value, context) : null,
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

  String? _validatePasswordConfirm(String? value, BuildContext context) {
    if (value == null || value.isEmpty) {
      return context.l10n.authConfirmPasswordRequired;
    }

    if (value != passwordController.text) {
      return context.l10n.authPasswordsDoNotMatch;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormField(
      controller: controller,
      label: context.l10n.authConfirmPasswordLabel,
      obscureText: true,
      textInputAction: TextInputAction.done,
      validator: (value) => _validatePasswordConfirm(value, context),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      enabled: enabled,
      autofillHints: const [AutofillHints.password],
    );
  }
}