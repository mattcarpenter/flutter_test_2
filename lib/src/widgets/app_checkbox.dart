import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// A custom checkbox widget that follows the app's design system
/// Matches the style of AppRadioButton but for checkbox functionality
class AppCheckbox extends StatefulWidget {
  /// Whether this checkbox is checked
  final bool checked;
  
  /// Callback when the checkbox is tapped
  final VoidCallback? onTap;
  
  /// Size of the checkbox (defaults to 20px)
  final double size;

  const AppCheckbox({
    super.key,
    required this.checked,
    this.onTap,
    this.size = 20.0,
  });

  @override
  State<AppCheckbox> createState() => _AppCheckboxState();
}

class _AppCheckboxState extends State<AppCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    final checkboxWidget = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.checked ? colors.primary : Colors.transparent,
              border: widget.checked 
                  ? null 
                  : Border.all(
                      color: colors.border.withOpacity(0.7),
                      width: 1.5,
                    ),
            ),
            child: widget.checked
                ? Icon(
                    Icons.check,
                    size: widget.size * 0.7, // 14px for 20px container
                    color: colors.onPrimary,
                  )
                : null,
          ),
        );
      },
    );

    // Only add gesture detection if onTap is provided
    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: checkboxWidget,
      );
    }

    // When onTap is null, return widget without gesture detection
    // This allows parent widgets to handle gestures
    return checkboxWidget;
  }
}