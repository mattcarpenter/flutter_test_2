import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/typography.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// A simple text field widget without floating labels
/// Displays placeholder text that disappears when the user starts typing
class AppTextFieldSimple extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final String? errorText;
  final bool enabled;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool multiline;
  final int minLines;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final int? maxLength;
  final Widget? suffix;
  final Widget? prefix;
  final String? Function(String?)? validator;
  final bool autocorrect;

  const AppTextFieldSimple({
    super.key,
    required this.controller,
    required this.placeholder,
    this.errorText,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.multiline = false,
    this.minLines = 1,
    this.maxLines,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.inputFormatters,
    this.textInputAction,
    this.focusNode,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.maxLength,
    this.suffix,
    this.prefix,
    this.validator,
    this.autocorrect = true,
  });

  @override
  State<AppTextFieldSimple> createState() => _AppTextFieldSimpleState();
}

class _AppTextFieldSimpleState extends State<AppTextFieldSimple> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  String? _validationError;

  // Design tokens
  static const double _fieldHeight = 56.0;
  static const double _borderRadius = 8.0;
  static const double _horizontalPadding = 16.0;
  static const double _verticalPadding = 15.0;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  String? get _effectiveErrorText {
    if (widget.validator != null) {
      return _validationError;
    }
    return widget.errorText;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final effectiveMaxLines = widget.multiline ? (widget.maxLines ?? 4) : 1;

    // When multiline is true and keyboardType wasn't explicitly set (is still default text),
    // use TextInputType.multiline to satisfy Flutter's assertion
    final effectiveKeyboardType = widget.multiline && widget.keyboardType == TextInputType.text
        ? TextInputType.multiline
        : widget.keyboardType;

    // Determine border color
    final borderColor = _effectiveErrorText != null
        ? colors.error
        : colors.border;

    // Build the text field
    final textField = TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      keyboardType: effectiveKeyboardType,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      maxLines: effectiveMaxLines,
      minLines: widget.multiline ? widget.minLines : 1,
      onChanged: (value) {
        if (widget.validator != null) {
          setState(() {
            _validationError = widget.validator!(value);
          });
        }
        widget.onChanged?.call(value);
      },
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
      inputFormatters: widget.inputFormatters,
      textInputAction: widget.textInputAction ??
          (widget.multiline ? TextInputAction.newline : TextInputAction.done),
      autofocus: widget.autofocus,
      textCapitalization: widget.textCapitalization,
      textAlign: widget.textAlign,
      maxLength: widget.maxLength,
      style: AppTypography.fieldInput.copyWith(
        color: widget.enabled ? colors.textPrimary : colors.textSecondary,
      ),
      decoration: InputDecoration(
        hintText: widget.placeholder,
        hintStyle: AppTypography.fieldLabel.copyWith(
          color: colors.inputPlaceholder,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _horizontalPadding,
          vertical: _verticalPadding,
        ),
        filled: true,
        fillColor: colors.input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(
            color: colors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(
            color: colors.error,
            width: 1,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(
            color: colors.border.withOpacity(0.5),
            width: 1,
          ),
        ),
        suffixIcon: widget.suffix,
        prefixIcon: widget.prefix,
        isDense: false,
        counterText: '', // Hide the counter text if maxLength is set
      ),
    );

    // Return with error text if needed
    if (_effectiveErrorText != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: widget.multiline ? null : _fieldHeight,
            child: textField,
          ),
          SizedBox(height: AppSpacing.xs),
          Padding(
            padding: EdgeInsets.only(left: _horizontalPadding),
            child: Text(
              _effectiveErrorText!,
              style: AppTypography.fieldError.copyWith(
                color: colors.error,
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      height: widget.multiline ? null : _fieldHeight,
      child: textField,
    );
  }
}
