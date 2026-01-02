import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/typography.dart';
import '../theme/colors.dart';
import 'app_text_field.dart' show AppTextFieldVariant;

class AppTextFieldCondensed extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final AppTextFieldVariant variant;
  final String? errorText;
  final bool enabled;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool multiline;
  final int minLines;
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
  final bool first;
  final bool last;
  final bool grouped;
  final String? valueHint;

  const AppTextFieldCondensed({
    Key? key,
    required this.controller,
    required this.placeholder,
    this.variant = AppTextFieldVariant.outline,
    this.errorText,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.multiline = false,
    this.minLines = 2,
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
    this.first = true,
    this.last = true,
    this.grouped = false,
    this.valueHint,
  }) : super(key: key);

  @override
  State<AppTextFieldCondensed> createState() => _AppTextFieldCondensedState();
}

class _AppTextFieldCondensedState extends State<AppTextFieldCondensed>
    with TickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late AnimationController _focusAnimationController;
  late Animation<double> _animation;
  late Animation<double> _focusAnimation;
  Animation<Color?>? _borderColorAnimation;
  Animation<Color?>? _labelColorAnimation;
  bool _hasValue = false;
  bool _isFocused = false;
  String? _validationError;

  // Design tokens
  static const double _condensedHeight = 48.0;
  static const double _multilineBaseHeight = 56.0;
  static const double _borderRadius = 8.0;
  static const double _horizontalPadding = 16.0;
  static const Duration _animationDuration = Duration(milliseconds: 250);
  static const double _lineHeight = 24.0;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _hasValue = widget.controller.text.isNotEmpty;

    _animationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutQuart,
    );

    _focusAnimation = CurvedAnimation(
      parent: _focusAnimationController,
      curve: Curves.easeInOut,
    );

    // Color animations will be initialized in didChangeDependencies

    if (_hasValue && widget.multiline) {
      _animationController.value = 1.0;
    }

    _focusNode.addListener(_handleFocusChange);
    widget.controller.addListener(_handleTextChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize color animations with theme-aware colors
    final colors = AppColors.of(context);
    _borderColorAnimation = ColorTween(
      begin: colors.border,
      end: colors.focus,
    ).animate(_focusAnimation);

    _labelColorAnimation = ColorTween(
      begin: colors.inputLabel,
      end: colors.focus,
    ).animate(_focusAnimation);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _focusNode.removeListener(_handleFocusChange);
    widget.controller.removeListener(_handleTextChange);
    _animationController.dispose();
    _focusAnimationController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    // Only animate for multiline mode
    if (widget.multiline) {
      if (_isFocused || _hasValue) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }

    if (_isFocused) {
      _focusAnimationController.forward();
    } else {
      _focusAnimationController.reverse();
    }
  }

  void _handleTextChange() {
    final hasValue = widget.controller.text.isNotEmpty;
    if (hasValue != _hasValue) {
      setState(() {
        _hasValue = hasValue;
      });

      // Only animate for multiline mode
      if (widget.multiline) {
        if (_hasValue || _isFocused) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      }
    }

    if (widget.validator != null) {
      final error = widget.validator!(widget.controller.text);
      if (error != _validationError) {
        setState(() {
          _validationError = error;
        });
      }
    }
  }

  String? get _effectiveErrorText {
    return widget.errorText ?? _validationError;
  }

  BorderRadius _getBorderRadius() {
    if (widget.first && widget.last) {
      return BorderRadius.circular(_borderRadius);
    } else if (widget.first && !widget.last) {
      return BorderRadius.only(
        topLeft: Radius.circular(_borderRadius),
        topRight: Radius.circular(_borderRadius),
      );
    } else if (!widget.first && widget.last) {
      return BorderRadius.only(
        bottomLeft: Radius.circular(_borderRadius),
        bottomRight: Radius.circular(_borderRadius),
      );
    } else {
      return BorderRadius.zero;
    }
  }

  Border _getBorder(Color borderColor) {
    if (widget.variant == AppTextFieldVariant.outline) {
      final borderWidth = _isFocused ? 2.0 : 1.0;

      if (_isFocused || widget.first) {
        return Border.all(
          color: borderColor,
          width: borderWidth,
        );
      } else {
        return Border(
          left: BorderSide(color: borderColor, width: borderWidth),
          right: BorderSide(color: borderColor, width: borderWidth),
          bottom: BorderSide(color: borderColor, width: borderWidth),
        );
      }
    } else {
      return Border.all(
        color: Colors.transparent,
        width: 0,
      );
    }
  }

  Widget _buildSingleLineField(AppColors colors) {
    // When grouped, render without container decoration
    if (widget.grouped) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _condensedHeight,
            child: Row(
              children: [
                if (widget.prefix != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: widget.prefix!,
                  ),
                  const SizedBox(width: 4),
                ] else ...[
                  const SizedBox(width: _horizontalPadding),
                ],

                // Fixed label on the left
                Text(
                  widget.placeholder,
                  style: AppTypography.fieldLabel.copyWith(
                    color: _effectiveErrorText != null
                        ? colors.error
                        : widget.enabled
                            ? colors.textPrimary
                            : colors.textDisabled,
                  ),
                ),

                const SizedBox(width: 16),

                // Right-aligned input
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    keyboardType: widget.keyboardType,
                    obscureText: widget.obscureText,
                    maxLines: 1,
                    onChanged: widget.onChanged,
                    onEditingComplete: widget.onEditingComplete,
                    onSubmitted: widget.onSubmitted,
                    inputFormatters: widget.inputFormatters,
                    textInputAction: widget.textInputAction ?? TextInputAction.done,
                    autofocus: widget.autofocus,
                    textCapitalization: widget.textCapitalization,
                    textAlign: TextAlign.end,
                    maxLength: widget.maxLength,
                    style: AppTypography.fieldInput.copyWith(
                      color: widget.enabled ? colors.textPrimary : colors.textDisabled,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      counterText: '',
                      hintText: _hasValue ? null : widget.valueHint,
                      hintStyle: AppTypography.fieldInput.copyWith(
                        color: colors.inputPlaceholder,
                      ),
                    ),
                  ),
                ),

                if (widget.suffix != null) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: widget.suffix!,
                  ),
                ] else ...[
                  const SizedBox(width: _horizontalPadding),
                ],
              ],
            ),
          ),

          // Error text for grouped fields
          if (_effectiveErrorText != null)
            Padding(
              padding: const EdgeInsets.only(
                top: 4.0,
                left: _horizontalPadding,
                right: _horizontalPadding,
              ),
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

    // Non-grouped field with container decoration
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _focusAnimation,
          builder: (context, child) {
            final borderColor = _effectiveErrorText != null
                ? colors.error
                : _borderColorAnimation?.value ?? colors.border;

            return Container(
              height: _condensedHeight,
              decoration: BoxDecoration(
                color: widget.variant == AppTextFieldVariant.filled
                    ? (widget.enabled
                        ? colors.inputBackgroundFilled
                        : colors.inputBackgroundFilled.withOpacity(0.5))
                    : colors.surface,
                borderRadius: _getBorderRadius(),
                border: _getBorder(borderColor),
              ),
              child: Row(
                children: [
                  if (widget.prefix != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: widget.prefix!,
                    ),
                    const SizedBox(width: 4),
                  ] else ...[
                    const SizedBox(width: _horizontalPadding),
                  ],

                    // Fixed label on the left
                    Text(
                      widget.placeholder,
                      style: AppTypography.fieldLabel.copyWith(
                        color: _effectiveErrorText != null
                            ? colors.error
                            : widget.enabled
                                ? colors.textPrimary
                                : colors.textDisabled,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Right-aligned input
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        enabled: widget.enabled,
                        keyboardType: widget.keyboardType,
                        obscureText: widget.obscureText,
                        maxLines: 1,
                        onChanged: widget.onChanged,
                        onEditingComplete: widget.onEditingComplete,
                        onSubmitted: widget.onSubmitted,
                        inputFormatters: widget.inputFormatters,
                        textInputAction: widget.textInputAction ?? TextInputAction.done,
                        autofocus: widget.autofocus,
                        textCapitalization: widget.textCapitalization,
                        textAlign: TextAlign.end,
                        maxLength: widget.maxLength,
                        style: AppTypography.fieldInput.copyWith(
                          color: widget.enabled ? colors.textPrimary : colors.textDisabled,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          counterText: '',
                          hintText: _hasValue ? null : widget.valueHint,
                          hintStyle: AppTypography.fieldInput.copyWith(
                            color: colors.inputPlaceholder,
                          ),
                        ),
                      ),
                    ),

                    if (widget.suffix != null) ...[
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: widget.suffix!,
                      ),
                    ] else ...[
                      const SizedBox(width: _horizontalPadding),
                    ],
                  ],
                ),
            );
          },
        ),

        // Error text for non-grouped fields
        if (_effectiveErrorText != null)
          AnimatedContainer(
            duration: _animationDuration,
            height: _effectiveErrorText != null ? null : 0,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 4.0,
                left: _horizontalPadding,
                right: _horizontalPadding,
              ),
              child: Text(
                _effectiveErrorText ?? '',
                style: AppTypography.fieldError.copyWith(
                  color: colors.error,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMultilineField(AppColors colors) {
    final isFloating = _isFocused || _hasValue;

    // When grouped, render without container decoration
    if (widget.grouped) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: BoxConstraints(
              minHeight: _multilineBaseHeight + ((widget.minLines - 1) * _lineHeight),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Floating label for grouped multiline
                AnimatedBuilder(
                  animation: Listenable.merge([_animation, _focusAnimation]),
                  builder: (context, child) {
                    final progress = _animation.value;
                    final textBaseline = 18.0;
                    final startY = 16.0 + textBaseline + 3.0;
                    final endY = 6 + textBaseline;
                    final yPosition = startY - (progress * (startY - endY));
                    final scale = 1.0 - (progress * 0.25);
                    final opacity = 0.7 + (progress * 0.3);

                    final labelColor = _effectiveErrorText != null
                        ? colors.error
                        : colors.inputLabel;

                    return Transform(
                      transform: Matrix4.identity()
                        ..translate(_horizontalPadding, yPosition - textBaseline)
                        ..scale(scale),
                      alignment: Alignment.centerLeft,
                      child: Opacity(
                        opacity: opacity,
                        child: Text(
                          widget.placeholder,
                          style: AppTypography.fieldLabel.copyWith(
                            color: labelColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Input field for grouped multiline
                Padding(
                  padding: EdgeInsets.only(
                    left: widget.prefix != null ? 0 : _horizontalPadding,
                    right: widget.suffix != null ? 0 : _horizontalPadding,
                    top: isFloating ? 24.0 : 16.0,
                    bottom: isFloating ? 8.0 : 16.0,
                  ),
                  child: Row(
                    children: [
                      if (widget.prefix != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: widget.prefix!,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          enabled: widget.enabled,
                          keyboardType: TextInputType.multiline,
                          obscureText: widget.obscureText,
                          minLines: widget.minLines,
                          maxLines: null,
                          onChanged: widget.onChanged,
                          onEditingComplete: widget.onEditingComplete,
                          onSubmitted: widget.onSubmitted,
                          inputFormatters: widget.inputFormatters,
                          textInputAction: widget.textInputAction ?? TextInputAction.newline,
                          autofocus: widget.autofocus,
                          textCapitalization: widget.textCapitalization,
                          textAlign: widget.textAlign,
                          maxLength: widget.maxLength,
                          style: AppTypography.fieldInput.copyWith(
                            color: widget.enabled ? colors.textPrimary : colors.textDisabled,
                          ),
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                      ),
                      if (widget.suffix != null) ...[
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: widget.suffix!,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Error text for grouped multiline fields
          if (_effectiveErrorText != null)
            Padding(
              padding: const EdgeInsets.only(
                top: 4.0,
                left: _horizontalPadding,
                right: _horizontalPadding,
              ),
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

    // Non-grouped multiline field with container decoration
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background container
              AnimatedBuilder(
                animation: _focusAnimation,
                builder: (context, child) {
                  final borderColor = _effectiveErrorText != null
                      ? colors.error
                      : _borderColorAnimation?.value ?? colors.border;

                  return Container(
                    constraints: BoxConstraints(
                      minHeight: _multilineBaseHeight + ((widget.minLines - 1) * _lineHeight),
                    ),
                    decoration: BoxDecoration(
                      color: widget.variant == AppTextFieldVariant.filled
                          ? (widget.enabled
                              ? colors.inputBackgroundFilled
                              : colors.inputBackgroundFilled.withOpacity(0.5))
                          : colors.surface,
                      borderRadius: _getBorderRadius(),
                      border: _getBorder(borderColor),
                    ),
                  );
                },
              ),

              // Floating label
              AnimatedBuilder(
                animation: Listenable.merge([_animation, _focusAnimation]),
                builder: (context, child) {
                  final progress = _animation.value;
                  final textBaseline = 18.0;
                  final startY = 16.0 + textBaseline + 3.0;
                  final endY = 6 + textBaseline;
                  final yPosition = startY - (progress * (startY - endY));
                  final scale = 1.0 - (progress * 0.25);
                  final opacity = 0.7 + (progress * 0.3);

                  final labelColor = _effectiveErrorText != null
                      ? colors.error
                      : _labelColorAnimation?.value ?? colors.inputLabel;

                  return Transform(
                    transform: Matrix4.identity()
                      ..translate(_horizontalPadding, yPosition - textBaseline)
                      ..scale(scale),
                    alignment: Alignment.centerLeft,
                    child: Opacity(
                      opacity: opacity,
                      child: Text(
                        widget.placeholder,
                        style: AppTypography.fieldLabel.copyWith(
                          color: labelColor,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Input field
              Padding(
                padding: EdgeInsets.only(
                  left: widget.prefix != null ? 0 : _horizontalPadding,
                  right: widget.suffix != null ? 0 : _horizontalPadding,
                  top: isFloating ? 24.0 : 16.0,
                  bottom: isFloating ? 8.0 : 16.0,
                ),
                child: Row(
                  children: [
                    if (widget.prefix != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: widget.prefix!,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        enabled: widget.enabled,
                        keyboardType: TextInputType.multiline,
                        obscureText: widget.obscureText,
                        minLines: widget.minLines,
                        maxLines: null,
                        onChanged: widget.onChanged,
                        onEditingComplete: widget.onEditingComplete,
                        onSubmitted: widget.onSubmitted,
                        inputFormatters: widget.inputFormatters,
                        textInputAction: widget.textInputAction ?? TextInputAction.newline,
                        autofocus: widget.autofocus,
                        textCapitalization: widget.textCapitalization,
                        textAlign: widget.textAlign,
                        maxLength: widget.maxLength,
                        style: AppTypography.fieldInput.copyWith(
                          color: widget.enabled ? colors.textPrimary : colors.textDisabled,
                        ),
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          counterText: '',
                        ),
                      ),
                    ),
                    if (widget.suffix != null) ...[
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: widget.suffix!,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Error text
        if (_effectiveErrorText != null)
          AnimatedContainer(
            duration: _animationDuration,
            height: _effectiveErrorText != null ? null : 0,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 4.0,
                left: _horizontalPadding,
                right: _horizontalPadding,
              ),
              child: Text(
                _effectiveErrorText ?? '',
                style: AppTypography.fieldError.copyWith(
                  color: colors.error,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    if (widget.multiline) {
      return _buildMultilineField(colors);
    } else {
      return _buildSingleLineField(colors);
    }
  }
}
