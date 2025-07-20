import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppTextFieldVariant { filled, outline }

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final AppTextFieldVariant variant;
  final String? errorText;
  final bool enabled;
  final TextInputType keyboardType;
  final bool obscureText;
  final int maxLines;
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

  const AppTextField({
    Key? key,
    required this.controller,
    required this.placeholder,
    this.variant = AppTextFieldVariant.outline,
    this.errorText,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLines = 1,
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

  // Design tokens
  static const double _fieldHeight = 56.0;
  static const double _borderRadius = 12.0;
  static const double _horizontalPadding = 16.0;
  static const double _labelFontSize = 16.0;
  static const double _floatingLabelFontSize = 12.0;
  static const Duration _animationDuration = Duration(milliseconds: 250);

  // Colors
  static const Color _focusColor = Color(0xFFE91E63); // Pink/Magenta
  static const Color _errorColor = Color(0xFFDC2626); // Red
  static const Color _defaultBorderColor = Color(0xFFE5E7EB); // Gray 200
  static const Color _labelColor = Color(0xFF6B7280); // Gray 500
  static const Color _filledBackgroundColor = Color(0xFFF3F4F6); // Gray 100
  static const Color _disabledColor = Color(0xFF9CA3AF); // Gray 400

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
  }

  Color get _borderColor {
    if (widget.errorText != null) return _errorColor;
    if (_isFocused) return _focusColor;
    if (!widget.enabled) return _disabledColor;
    return _defaultBorderColor;
  }

  Color get _labelColorAnimated {
    if (widget.errorText != null) return _errorColor;
    if (_isFocused) return _focusColor;
    return _labelColor;
  }

  @override
  Widget build(BuildContext context) {
    final isFloating = _isFocused || _hasValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _fieldHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background container with animated border
              AnimatedBuilder(
                animation: _focusAnimation,
                builder: (context, child) {
                  final borderColor = widget.errorText != null
                      ? _errorColor
                      : _borderColorAnimation.value ?? _defaultBorderColor;

                  return Container(
                    height: _fieldHeight,
                    decoration: BoxDecoration(
                      color: widget.variant == AppTextFieldVariant.filled
                          ? (widget.enabled
                              ? _filledBackgroundColor
                              : _filledBackgroundColor.withOpacity(0.5))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(_borderRadius),
                      border: Border.all(
                        color: widget.variant == AppTextFieldVariant.outline
                            ? borderColor
                            : Colors.transparent,
                        width: widget.variant == AppTextFieldVariant.outline
                            ? (_isFocused ? 2.0 : 1.0)
                            : 0,
                      ),
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
                  // From center (28px) to top inside box (12px)
                  final yPosition = 28.0 - (progress * 16.0);
                  
                  // Linear scale from 1.0 to 0.75
                  final scale = 1.0 - (progress * 0.25);
                  
                  // Subtle opacity change for polish
                  final opacity = 0.7 + (progress * 0.3);
                  
                  // Animated label color
                  final labelColor = widget.errorText != null
                      ? _errorColor
                      : _labelColorAnimation.value ?? _labelColor;

                  return Transform(
                    transform: Matrix4.identity()
                      ..translate(_horizontalPadding, yPosition - 8.0)
                      ..scale(scale),
                    alignment: Alignment.centerLeft,
                    child: Opacity(
                      opacity: opacity,
                      child: Text(
                        widget.placeholder,
                        style: TextStyle(
                          color: labelColor,
                          fontSize: _labelFontSize,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Input field
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: widget.prefix != null ? 0 : _horizontalPadding,
                    right: widget.suffix != null ? 0 : _horizontalPadding,
                    top: isFloating ? 16.0 : 0.0,
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
                          keyboardType: widget.keyboardType,
                          obscureText: widget.obscureText,
                          maxLines: widget.maxLines,
                          onChanged: widget.onChanged,
                          onEditingComplete: widget.onEditingComplete,
                          onSubmitted: widget.onSubmitted,
                          inputFormatters: widget.inputFormatters,
                          textInputAction: widget.textInputAction,
                          autofocus: widget.autofocus,
                          textCapitalization: widget.textCapitalization,
                          textAlign: widget.textAlign,
                          maxLength: widget.maxLength,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                            color: widget.enabled ? Colors.black : _disabledColor,
                            height: 1.5,
                          ),
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
              ),
            ],
          ),
        ),

        // Error text
        if (widget.errorText != null)
          AnimatedContainer(
            duration: _animationDuration,
            height: widget.errorText != null ? null : 0,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 4.0,
                left: _horizontalPadding,
                right: _horizontalPadding,
              ),
              child: Text(
                widget.errorText ?? '',
                style: TextStyle(
                  color: _errorColor,
                  fontSize: 12.0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}