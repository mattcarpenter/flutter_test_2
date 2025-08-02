import 'package:flutter/material.dart';

/// Theme options for the button
enum AppButtonTheme {
  primary,
  secondary,
}

/// Style options for the button
enum AppButtonStyle {
  fill,
  outline,
  muted,
  mutedOutline,
}

/// Shape options for the button
enum AppButtonShape {
  round,
  square,
}

/// Size options for the button
enum AppButtonSize {
  small,
  medium,
  large,
}

/// A button widget that follows the app's design system
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonTheme theme;
  final AppButtonStyle style;
  final AppButtonShape shape;
  final AppButtonSize size;
  final bool loading;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool fullWidth;

  const AppButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.theme = AppButtonTheme.primary,
    this.style = AppButtonStyle.fill,
    this.shape = AppButtonShape.round,
    this.size = AppButtonSize.medium,
    this.loading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  // Color definitions based on Figma design system
  static const Map<AppButtonTheme, Map<String, Color>> _colors = {
    AppButtonTheme.primary: {
      'default': Color(0xFF000000), // Pure black
      'hover': Color(0xFF333333),   // Dark gray (20% lighter)
      'pressed': Color(0xFF666666),  // Medium gray (40% lighter)
    },
    AppButtonTheme.secondary: {
      'default': Color(0xFFFF595E),
      'hover': Color(0xFFFF595E),
      'pressed': Color(0xFFFF595E),
    },
  };

  // Generate muted background color (very light version of the theme color)
  Color get _mutedBackgroundColor {
    final baseColor = _colors[widget.theme]!['default']!;
    return Color.lerp(baseColor, Colors.white, 0.9)!;
  }

  // Generate muted text color (darker version of the theme color)
  Color get _mutedTextColor {
    final baseColor = _colors[widget.theme]!['default']!;
    return Color.lerp(baseColor, Colors.black, 0.3)!;
  }

  Color get _backgroundColor {
    if (widget.style == AppButtonStyle.outline || widget.style == AppButtonStyle.mutedOutline) {
      return Colors.transparent;
    }

    final colorMap = _colors[widget.theme]!;
    
    if (widget.style == AppButtonStyle.muted) {
      return _mutedBackgroundColor;
    }
    
    if (widget.onPressed == null || widget.loading) {
      return colorMap['default']!.withOpacity(0.5);
    }
    if (_isPressed) {
      return colorMap['pressed']!;
    }
    if (_isHovered) {
      return colorMap['hover']!;
    }
    return colorMap['default']!;
  }

  Color get _borderColor {
    final colorMap = _colors[widget.theme]!;
    
    if (widget.style == AppButtonStyle.mutedOutline) {
      return _mutedTextColor;
    }
    
    if (widget.onPressed == null || widget.loading) {
      return colorMap['default']!.withOpacity(0.5);
    }
    if (_isPressed) {
      return colorMap['pressed']!;
    }
    if (_isHovered) {
      return colorMap['hover']!;
    }
    return colorMap['default']!;
  }

  Color get _textColor {
    final colorMap = _colors[widget.theme]!;
    
    if (widget.style == AppButtonStyle.fill) {
      return Colors.white;
    }
    
    if (widget.style == AppButtonStyle.muted || widget.style == AppButtonStyle.mutedOutline) {
      return _mutedTextColor;
    }

    if (widget.onPressed == null || widget.loading) {
      return colorMap['default']!.withOpacity(0.5);
    }
    if (_isPressed) {
      return colorMap['pressed']!;
    }
    if (_isHovered) {
      return colorMap['hover']!;
    }
    return colorMap['default']!;
  }

  double get _height {
    switch (widget.size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 40;
      case AppButtonSize.large:
        return 52;
    }
  }

  EdgeInsets get _padding {
    switch (widget.size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 18, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 22, vertical: 10);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 26, vertical: 14);
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case AppButtonSize.small:
        return 12;
      case AppButtonSize.medium:
        return 14;
      case AppButtonSize.large:
        return 16;
    }
  }

  BorderRadius get _borderRadius {
    if (widget.shape == AppButtonShape.round) {
      // Pill shape - fully rounded
      return BorderRadius.circular(_height / 2);
    } else {
      // Stadium/racetrack shape - gentle curves on top/bottom, sharper on left/right
      return BorderRadius.circular(_height / 2.5);
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.loading) {
      setState(() {
        _isPressed = true;
      });
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.loading;

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: _height,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: _borderRadius,
            border: (widget.style == AppButtonStyle.outline || widget.style == AppButtonStyle.mutedOutline)
                ? Border.all(
                    color: _borderColor,
                    width: 1,
                  )
                : null,
          ),
          child: Padding(
            padding: _padding,
            child: Row(
              mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.loading) ...[
                  SizedBox(
                    width: _fontSize,
                    height: _fontSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_textColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (widget.leadingIcon != null) ...[
                  IconTheme(
                    data: IconThemeData(
                      size: _fontSize,
                      color: _textColor,
                    ),
                    child: widget.leadingIcon!,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    height: 1,
                  ),
                ),
                if (widget.trailingIcon != null && !widget.loading) ...[
                  const SizedBox(width: 8),
                  IconTheme(
                    data: IconThemeData(
                      size: _fontSize,
                      color: _textColor,
                    ),
                    child: widget.trailingIcon!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Convenience constructors for common button configurations
extension AppButtonVariants on AppButton {
  /// Creates a primary filled button
  static AppButton primaryFilled({
    required String text,
    VoidCallback? onPressed,
    AppButtonShape shape = AppButtonShape.round,
    AppButtonSize size = AppButtonSize.medium,
    bool loading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
    bool fullWidth = false,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      theme: AppButtonTheme.primary,
      style: AppButtonStyle.fill,
      shape: shape,
      size: size,
      loading: loading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      fullWidth: fullWidth,
    );
  }

  /// Creates a primary outline button
  static AppButton primaryOutline({
    required String text,
    VoidCallback? onPressed,
    AppButtonShape shape = AppButtonShape.round,
    AppButtonSize size = AppButtonSize.medium,
    bool loading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
    bool fullWidth = false,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      theme: AppButtonTheme.primary,
      style: AppButtonStyle.outline,
      shape: shape,
      size: size,
      loading: loading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      fullWidth: fullWidth,
    );
  }

  /// Creates a secondary filled button
  static AppButton secondaryFilled({
    required String text,
    VoidCallback? onPressed,
    AppButtonShape shape = AppButtonShape.round,
    AppButtonSize size = AppButtonSize.medium,
    bool loading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
    bool fullWidth = false,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      theme: AppButtonTheme.secondary,
      style: AppButtonStyle.fill,
      shape: shape,
      size: size,
      loading: loading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      fullWidth: fullWidth,
    );
  }

  /// Creates a secondary outline button
  static AppButton secondaryOutline({
    required String text,
    VoidCallback? onPressed,
    AppButtonShape shape = AppButtonShape.round,
    AppButtonSize size = AppButtonSize.medium,
    bool loading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
    bool fullWidth = false,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      theme: AppButtonTheme.secondary,
      style: AppButtonStyle.outline,
      shape: shape,
      size: size,
      loading: loading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      fullWidth: fullWidth,
    );
  }
}
