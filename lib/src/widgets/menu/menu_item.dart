import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';

class MenuItem extends StatefulWidget {
  final int index;
  final String title;
  final IconData icon;
  final bool isActive;
  final Color color;
  final Color textColor;
  final Color activeTextColor;
  final Color backgroundColor;
  final void Function(int index) onTap;
  final Widget? trailing;

  const MenuItem({
    super.key,
    required this.index,
    required this.title,
    required this.icon,
    required this.isActive,
    required this.color,
    required this.activeTextColor,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    this.trailing,
  });

  @override
  MenuItemState createState() => MenuItemState();
}

class MenuItemState extends State<MenuItem> {
  double _opacity = 1.0; // Default opacity
  bool _shouldAnimate = false; // Controls animation behavior

  void _handleTapDown(TapDownDetails details) {
    // On touch start, immediately set opacity to 75%
    setState(() {
      _shouldAnimate = false; // Disable animation for this state change
      _opacity = 0.5;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    // On touch end, animate back to full opacity (1.0)
    setState(() {
      _shouldAnimate = true; // Enable animation for this state change
      _opacity = 1.0;
    });

    // Trigger the onTap callback
    widget.onTap(widget.index);
  }

  void _handleTapCancel() {
    // If the gesture is canceled, animate back to full opacity (1.0)
    setState(() {
      _shouldAnimate = true; // Enable animation for this state change
      _opacity = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final typography = CupertinoTheme.of(context).textTheme;

    final effectiveTextStyle = widget.isActive
        ? typography.textStyle.copyWith(
      color: widget.activeTextColor,
      fontWeight: FontWeight.w600,
    )
        : typography.textStyle;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedOpacity(
        duration: _shouldAnimate
            ? const Duration(milliseconds: 100) // Animate back to 100%
            : Duration.zero, // Immediate change for touch start
        opacity: _opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 0.0),
          decoration: BoxDecoration(
            color: widget.isActive ? widget.backgroundColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: widget.isActive
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.08), // Shadow color
                blurRadius: 10.0, // How blurred the shadow should be
                offset: const Offset(0, 2), // Position of the shadow
              ),
            ]
                : [],
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: widget.color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.title, style: effectiveTextStyle),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 8),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
