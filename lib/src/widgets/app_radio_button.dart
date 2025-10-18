import 'package:flutter/cupertino.dart';
import '../theme/colors.dart';

/// A custom radio button widget that follows the app's design system
class AppRadioButton extends StatefulWidget {
  /// Whether this radio button is selected
  final bool selected;

  /// Callback when the radio button is tapped
  final VoidCallback? onTap;

  /// Size of the radio button (defaults to 24px to match shopping list)
  final double size;

  const AppRadioButton({
    super.key,
    required this.selected,
    this.onTap,
    this.size = 24.0,
  });

  @override
  State<AppRadioButton> createState() => _AppRadioButtonState();
}

class _AppRadioButtonState extends State<AppRadioButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

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
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _handleTapCancel() {
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
                color: widget.selected ? colors.primary : colors.input,
                border: Border.all(
                  color: widget.selected ? colors.primary : colors.borderRadio,
                  width: 1,
                ),
              ),
              child: widget.selected
                  ? Icon(
                      CupertinoIcons.check_mark,
                      size: widget.size * 0.67, // 16px for 24px container
                      color: CupertinoColors.white,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
