import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

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
  extraSmall,
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
  final bool iconOnly;
  final Widget? icon;
  final bool visuallyEnabled;
  final Offset leadingIconOffset;
  final Offset trailingIconOffset;

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
    this.iconOnly = false,
    this.icon,
    this.visuallyEnabled = false,
    this.leadingIconOffset = Offset.zero,
    this.trailingIconOffset = Offset.zero,
  }) : super(key: key);

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  Color _getThemeColor(AppColors colors, {bool hover = false, bool pressed = false}) {
    if (widget.theme == AppButtonTheme.primary) {
      // Primary uses main primary color
      if (pressed) return AppColorSwatches.primary[700]!;
      if (hover) return AppColorSwatches.primary[600]!;
      return colors.primary;
    } else {
      // Secondary uses primary color
      if (pressed) return colors.primaryVariant;
      if (hover) return AppColorSwatches.primary[600]!;
      return colors.primary;
    }
  }

  Color get _backgroundColor {
    final colors = AppColors.of(context);

    if (widget.style == AppButtonStyle.outline || widget.style == AppButtonStyle.mutedOutline) {
      return Colors.transparent;
    }

    final baseColor = _getThemeColor(colors, hover: _isHovered, pressed: _isPressed);

    if (widget.style == AppButtonStyle.muted) {
      // Muted style uses very light version of the color
      return widget.theme == AppButtonTheme.primary
          ? colors.brightness == Brightness.light
              ? AppColorSwatches.neutral[100]!
              : AppColorSwatches.neutral[800]!
          : colors.brightness == Brightness.light
              ? AppColorSwatches.primary[50]!
              : AppColorSwatches.primary[900]!.withOpacity(0.15);
    }

    // Check visuallyEnabled to override disabled appearance
    if ((widget.onPressed == null && !widget.visuallyEnabled) || widget.loading) {
      return baseColor.withOpacity(0.5);
    }

    return baseColor;
  }

  Color get _borderColor {
    final colors = AppColors.of(context);

    if (widget.style == AppButtonStyle.mutedOutline) {
      // Muted outline uses very subtle border
      return widget.theme == AppButtonTheme.primary
          ? colors.textPrimary.withOpacity(0.35) // Very light border
          : colors.primary.withOpacity(0.35);
    }

    // For outline styles, use the theme color for border
    if (widget.style == AppButtonStyle.outline) {
      return _getThemeColor(colors, hover: _isHovered, pressed: _isPressed);
    }

    // For other styles, use the background color logic
    final baseColor = _getThemeColor(colors, hover: _isHovered, pressed: _isPressed);

    // Check visuallyEnabled to override disabled appearance
    if ((widget.onPressed == null && !widget.visuallyEnabled) || widget.loading) {
      return baseColor.withOpacity(0.5);
    }

    return baseColor;
  }

  Color get _textColor {
    final colors = AppColors.of(context);

    if (widget.style == AppButtonStyle.fill) {
      // Filled buttons use contrasting text
      if (widget.theme == AppButtonTheme.primary) {
        // Primary uses white text on primary background
        return colors.onPrimary;
      } else {
        // Secondary uses contrasting text
        return colors.onPrimary;
      }
    }

    if (widget.style == AppButtonStyle.muted) {
      // Muted style uses darker text
      return widget.theme == AppButtonTheme.primary
          ? colors.textPrimary
          : colors.primary;
    }

    if (widget.style == AppButtonStyle.mutedOutline) {
      // Muted outline uses lighter text
      return widget.theme == AppButtonTheme.primary
          ? colors.textPrimary.withOpacity(0.65)
          : colors.primary.withOpacity(0.65);
    }

    // Outline styles use theme color for text
    final baseColor = _getThemeColor(colors, hover: _isHovered, pressed: _isPressed);

    // Check visuallyEnabled to override disabled appearance
    if ((widget.onPressed == null && !widget.visuallyEnabled) || widget.loading) {
      return baseColor.withOpacity(0.5);
    }

    return baseColor;
  }

  double get _height {
    switch (widget.size) {
      case AppButtonSize.extraSmall:
        return 28;
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 40;
      case AppButtonSize.large:
        return 52;
    }
  }

  EdgeInsets get _padding {
    // Icon-only buttons get equal padding on all sides for square appearance
    if (widget.iconOnly) {
      switch (widget.size) {
        case AppButtonSize.extraSmall:
          return const EdgeInsets.all(8);
        case AppButtonSize.small:
          return const EdgeInsets.all(10);
        case AppButtonSize.medium:
          return const EdgeInsets.all(12);
        case AppButtonSize.large:
          return const EdgeInsets.all(18);
      }
    }

    // Reduce horizontal padding when leading icon is present for better balance
    final hasLeadingIcon = widget.leadingIcon != null && !widget.loading;
    final horizontalPadding = hasLeadingIcon ? 0.7 : 1.0; // 30% less padding with icon

    switch (widget.size) {
      case AppButtonSize.extraSmall:
        return EdgeInsets.symmetric(
          horizontal: (14 * horizontalPadding).round().toDouble(),
          vertical: 6
        );
      case AppButtonSize.small:
        return EdgeInsets.symmetric(
          horizontal: (18 * horizontalPadding).round().toDouble(),
          vertical: 8
        );
      case AppButtonSize.medium:
        return EdgeInsets.symmetric(
          horizontal: (22 * horizontalPadding).round().toDouble(),
          vertical: 10
        );
      case AppButtonSize.large:
        return EdgeInsets.symmetric(
          horizontal: (26 * horizontalPadding).round().toDouble(),
          vertical: 14
        );
    }
  }

  double get _fontSize {
    // Icon-only buttons use larger icon sizes for better visibility
    if (widget.iconOnly) {
      switch (widget.size) {
        case AppButtonSize.extraSmall:
          return 14;
        case AppButtonSize.small:
          return 16;  // Increased from 12 for better visibility
        case AppButtonSize.medium:
          return 18;
        case AppButtonSize.large:
          return 24;
      }
    }

    switch (widget.size) {
      case AppButtonSize.extraSmall:
        return 11;
      case AppButtonSize.small:
        return 12;
      case AppButtonSize.medium:
        return 14;
      case AppButtonSize.large:
        return 16;
    }
  }

  // SF Pro Rounded letter spacing based on Apple's typography guidelines
  double get _letterSpacing {
    switch (_fontSize.toInt()) {
      case 11:
      case 12:
        return 0.0; // Small sizes use default spacing
      case 14:
        return 0.48; // +0.48 for 14px
      case 16:
        return 0.41; // +0.41 for 16px
      case 18:
        return 0.37; // +0.37 for 18px
      case 24:
        return 0.35; // +0.35 for 24px
      default:
        return 0.41; // Default fallback
    }
  }

  BorderRadius get _borderRadius {
    if (widget.shape == AppButtonShape.round) {
      // Pill shape - fully rounded
      return BorderRadius.circular(_height / 2);
    } else {
      // Square shape - fixed 8px radius to match text inputs
      return BorderRadius.circular(8.0);
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
    final showEnabledCursor = isEnabled || widget.visuallyEnabled;

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      cursor: showEnabledCursor ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: isEnabled ? _handleTapDown : null,
        onTapUp: isEnabled ? _handleTapUp : null,
        onTapCancel: isEnabled ? _handleTapCancel : null,
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: _height,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: _borderRadius,
            border: Border.all(
              color: (widget.style == AppButtonStyle.outline || widget.style == AppButtonStyle.mutedOutline)
                  ? _borderColor
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Padding(
            padding: _padding,
            child: widget.iconOnly
              ? widget.loading
                  ? Center(
                      child: SizedBox(
                        width: _fontSize,
                        height: _fontSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(_textColor),
                        ),
                      ),
                    )
                  : Container(
                      alignment: Alignment.center,
                      child: Transform.translate(
                        offset: const Offset(0.5, -2.5), // Center horizontally, slight upward nudge for optical balance
                        child: IconTheme(
                          data: IconThemeData(
                            size: _fontSize,
                            color: _textColor,
                          ),
                          child: widget.icon ?? widget.leadingIcon ?? const SizedBox(),
                        ),
                      ),
                    )
              : Row(
                  mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: widget.trailingIcon != null 
                      ? MainAxisAlignment.spaceBetween 
                      : MainAxisAlignment.center,
                  children: [
                    // Leading content (icon + text) - grouped together when trailing icon exists
                    if (widget.trailingIcon != null && !widget.loading)
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                            Transform.translate(
                              offset: widget.leadingIconOffset,
                              child: IconTheme(
                                data: IconThemeData(
                                  size: _fontSize,
                                  color: _textColor,
                                ),
                                child: widget.leadingIcon!,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            widget.text,
                            style: AppTypography.button.copyWith(
                              color: _textColor,
                              fontSize: _fontSize,
                              letterSpacing: _letterSpacing,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      )
                    else ...[
                      // Original behavior when no trailing icon
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
                        Transform.translate(
                          offset: widget.leadingIconOffset,
                          child: IconTheme(
                            data: IconThemeData(
                              size: _fontSize,
                              color: _textColor,
                            ),
                            child: widget.leadingIcon!,
                          ),
                        ),
                        const SizedBox(width: 6), // Reduced from 8 to 6
                      ],
                      Flexible(
                        child: Text(
                          widget.text,
                          style: AppTypography.button.copyWith(
                            color: _textColor,
                            fontSize: _fontSize,
                            letterSpacing: _letterSpacing,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                    
                    // Trailing icon - positioned at the end
                    if (widget.trailingIcon != null && !widget.loading)
                      Transform.translate(
                        offset: widget.trailingIconOffset,
                        child: IconTheme(
                          data: IconThemeData(
                            size: _fontSize,
                            color: _textColor,
                          ),
                          child: widget.trailingIcon!,
                        ),
                      ),
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
    Offset leadingIconOffset = Offset.zero,
    Offset trailingIconOffset = Offset.zero,
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
      leadingIconOffset: leadingIconOffset,
      trailingIconOffset: trailingIconOffset,
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
    Offset leadingIconOffset = Offset.zero,
    Offset trailingIconOffset = Offset.zero,
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
      leadingIconOffset: leadingIconOffset,
      trailingIconOffset: trailingIconOffset,
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
    Offset leadingIconOffset = Offset.zero,
    Offset trailingIconOffset = Offset.zero,
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
      leadingIconOffset: leadingIconOffset,
      trailingIconOffset: trailingIconOffset,
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
    Offset leadingIconOffset = Offset.zero,
    Offset trailingIconOffset = Offset.zero,
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
      leadingIconOffset: leadingIconOffset,
      trailingIconOffset: trailingIconOffset,
    );
  }

  /// Creates a muted outline button
  static AppButton mutedOutline({
    required String text,
    VoidCallback? onPressed,
    AppButtonTheme theme = AppButtonTheme.primary,
    AppButtonShape shape = AppButtonShape.round,
    AppButtonSize size = AppButtonSize.medium,
    bool loading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
    bool fullWidth = false,
    Offset leadingIconOffset = Offset.zero,
    Offset trailingIconOffset = Offset.zero,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      theme: theme,
      style: AppButtonStyle.mutedOutline,
      shape: shape,
      size: size,
      loading: loading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      fullWidth: fullWidth,
      leadingIconOffset: leadingIconOffset,
      trailingIconOffset: trailingIconOffset,
    );
  }

  /// Creates an icon-only button
  static AppButton iconOnly({
    required Widget icon,
    VoidCallback? onPressed,
    AppButtonTheme theme = AppButtonTheme.primary,
    AppButtonStyle style = AppButtonStyle.outline,
    AppButtonShape shape = AppButtonShape.round,
    AppButtonSize size = AppButtonSize.small,
    bool loading = false,
    bool visuallyEnabled = false,
    Offset leadingIconOffset = Offset.zero,
    Offset trailingIconOffset = Offset.zero,
  }) {
    return AppButton(
      text: '',
      onPressed: onPressed,
      theme: theme,
      style: style,
      shape: shape,
      size: size,
      loading: loading,
      iconOnly: true,
      icon: icon,
      visuallyEnabled: visuallyEnabled,
      leadingIconOffset: leadingIconOffset,
      trailingIconOffset: trailingIconOffset,
    );
  }
}
