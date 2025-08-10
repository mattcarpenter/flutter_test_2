import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// A custom radio button widget that follows the app's design system
class AppRadioButton extends StatefulWidget {
  /// Whether this radio button is selected
  final bool selected;
  
  /// Callback when the radio button is tapped
  final VoidCallback? onTap;
  
  /// Size of the radio button (defaults to 20px)
  final double size;

  const AppRadioButton({
    super.key,
    required this.selected,
    this.onTap,
    this.size = 20.0,
  });

  @override
  State<AppRadioButton> createState() => _AppRadioButtonState();
}

class _AppRadioButtonState extends State<AppRadioButton>
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
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.selected ? colors.primary : Colors.transparent,
                border: widget.selected 
                    ? null 
                    : Border.all(
                        color: colors.border.withOpacity(0.7),
                        width: 1.5,
                      ),
              ),
              child: widget.selected
                  ? Icon(
                      Icons.check,
                      size: widget.size * 0.7, // 14px for 20px container
                      color: colors.onPrimary,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}