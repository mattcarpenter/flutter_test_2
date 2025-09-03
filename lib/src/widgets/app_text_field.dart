import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/typography.dart';

enum AppTextFieldVariant { filled, outline }

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final AppTextFieldVariant variant;
  final String? errorText;
  final bool enabled;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool multiline;
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

  const AppTextField({
    Key? key,
    required this.controller,
    required this.placeholder,
    this.variant = AppTextFieldVariant.outline,
    this.errorText,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.multiline = false,
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
  }) : super(key: key);

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField>
    with TickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late AnimationController _focusAnimationController;
  late Animation<double> _animation;
  late Animation<double> _focusAnimation;
  late Animation<Color?> _borderColorAnimation;
  late Animation<Color?> _labelColorAnimation;
  bool _hasValue = false;
  bool _isFocused = false;
  String? _validationError;

  // Design tokens
  static const double _fieldHeight = 56.0;
  static const double _borderRadius = 8.0;
  static const double _horizontalPadding = 16.0;
  // Font sizes now managed by AppTypography system
  static const Duration _animationDuration = Duration(milliseconds: 250);
  static const double _lineHeight = 24.0; // For multiline calculation

  // Colors
  static const Color _focusColor = Color(0xFFE91E63); // Pink/Magenta
  static const Color _errorColor = Color(0xFFDC2626); // Red
  static const Color _defaultBorderColor = Color(0xFFE5E7EB); // Gray 200
  static const Color _labelColor = Color(0xFF5F6370); // Gray 500
  static const Color _filledBackgroundColor = Color(0xFFF3F4F6); // Gray 100
  static const Color _disabledColor = Color(0xFF9CA3AF); // Gray 400
  static const Color _textColor = Color(0xFF1D2129);

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _hasValue = widget.controller.text.isNotEmpty;

    // Main animation controller for position and scale
    _animationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    // Focus animation controller for colors
    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Position/scale animation with smooth easing
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutQuart,
    );

    // Focus animation for colors
    _focusAnimation = CurvedAnimation(
      parent: _focusAnimationController,
      curve: Curves.easeInOut,
    );

    // Animated colors
    _borderColorAnimation = ColorTween(
      begin: _defaultBorderColor,
      end: _focusColor,
    ).animate(_focusAnimation);

    _labelColorAnimation = ColorTween(
      begin: _labelColor,
      end: _focusColor,
    ).animate(_focusAnimation);

    // Set initial animation states
    if (_hasValue) {
      _animationController.value = 1.0;
    }

    _focusNode.addListener(_handleFocusChange);
    widget.controller.addListener(_handleTextChange);
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

    // Animate position/scale based on focus OR has value
    if (_isFocused || _hasValue) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    // Animate colors based on focus only
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

      if (_hasValue || _isFocused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }

    // Run validation if validator is provided
    if (widget.validator != null) {
      final error = widget.validator!(widget.controller.text);
      if (error != _validationError) {
        setState(() {
          _validationError = error;
        });
      }
    }
  }

  Color get _borderColor {
    if (widget.errorText != null || _validationError != null) return _errorColor;
    if (_isFocused) return _focusColor;
    if (!widget.enabled) return _disabledColor;
    return _defaultBorderColor;
  }

  Color get _labelColorAnimated {
    if (widget.errorText != null || _validationError != null) return _errorColor;
    if (_isFocused) return _focusColor;
    return _labelColor;
  }

  String? get _effectiveErrorText {
    return widget.errorText ?? _validationError;
  }

  int get _maxLines => widget.multiline ? 5 : 1;

  bool get _isMultiline => widget.multiline;

  @override
  Widget build(BuildContext context) {
    final isFloating = _isFocused || _hasValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background container with animated border
              AnimatedBuilder(
                animation: _focusAnimation,
                builder: (context, child) {
                  final borderColor = _effectiveErrorText != null
                      ? _errorColor
                      : _borderColorAnimation.value ?? _defaultBorderColor;

                  // Calculate border radius based on first/last
                  BorderRadius borderRadius;
                  if (widget.first && widget.last) {
                    // Standalone field - all corners rounded
                    borderRadius = BorderRadius.circular(_borderRadius);
                  } else if (widget.first && !widget.last) {
                    // First in group - only top corners rounded
                    borderRadius = BorderRadius.only(
                      topLeft: Radius.circular(_borderRadius),
                      topRight: Radius.circular(_borderRadius),
                    );
                  } else if (!widget.first && widget.last) {
                    // Last in group - only bottom corners rounded
                    borderRadius = BorderRadius.only(
                      bottomLeft: Radius.circular(_borderRadius),
                      bottomRight: Radius.circular(_borderRadius),
                    );
                  } else {
                    // Middle item - no rounded corners
                    borderRadius = BorderRadius.zero;
                  }

                  // Calculate border based on first/last and focus state
                  Border border;
                  if (widget.variant == AppTextFieldVariant.outline) {
                    final borderWidth = _isFocused ? 2.0 : 1.0;

                    // When focused, always show full border regardless of position
                    if (_isFocused || widget.first) {
                      // Focused items or first item - full border
                      border = Border.all(
                        color: borderColor,
                        width: borderWidth,
                      );
                    } else {
                      // Not focused and not first - no top border to avoid doubles
                      border = Border(
                        left: BorderSide(color: borderColor, width: borderWidth),
                        right: BorderSide(color: borderColor, width: borderWidth),
                        bottom: BorderSide(color: borderColor, width: borderWidth),
                      );
                    }
                  } else {
                    // Filled variant - no border
                    border = Border.all(
                      color: Colors.transparent,
                      width: 0,
                    );
                  }

                  return Container(
                    constraints: BoxConstraints(
                      minHeight: _fieldHeight,
                    ),
                    decoration: BoxDecoration(
                      color: widget.variant == AppTextFieldVariant.filled
                          ? (widget.enabled
                              ? _filledBackgroundColor
                              : _filledBackgroundColor.withOpacity(0.5))
                          : Colors.white,
                      borderRadius: borderRadius,
                      border: border,
                    ),
                  );
                },
              ),

              // Floating label with smooth linear animation
              AnimatedBuilder(
                animation: Listenable.merge([_animation, _focusAnimation]),
                builder: (context, child) {
                  final progress = _animation.value;

                  // Linear interpolation for position
                  // Calculate proper baseline positions
                  final textBaseline = 18.0; // Approximate baseline offset for 16px font

                  // Single line: visual center of container (56px)
                  // Multiline: align with input text position
                  final startY = _isMultiline
                      ? 16.0 + textBaseline + 3.0  // Match input padding + baseline + adjustment
                      : (_fieldHeight / 2) + (textBaseline / 2); // Visual center, nudged down 1px

                  final endY = 6 + textBaseline; // Floating position much higher up
                  final yPosition = startY - (progress * (startY - endY));

                  // Linear scale from 1.0 to 0.75
                  final scale = 1.0 - (progress * 0.25);

                  // Subtle opacity change for polish
                  final opacity = 0.7 + (progress * 0.3);

                  // Animated label color
                  final labelColor = _effectiveErrorText != null
                      ? _errorColor
                      : _labelColorAnimation.value ?? _labelColor;

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
                          keyboardType: widget.multiline
                              ? TextInputType.multiline
                              : widget.keyboardType,
                          obscureText: widget.obscureText,
                          minLines: 1,
                          maxLines: widget.obscureText ? 1 : _maxLines,
                          onChanged: widget.onChanged,
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
                            color: widget.enabled ? _textColor : _disabledColor,
                          ),
                          textAlignVertical: _isMultiline
                              ? TextAlignVertical.top
                              : TextAlignVertical.center,
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
                  color: _errorColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
