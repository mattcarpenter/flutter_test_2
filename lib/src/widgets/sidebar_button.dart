import 'package:flutter/cupertino.dart';

class SidebarButton extends StatefulWidget {
  final VoidCallback onTap;

  const SidebarButton({super.key, required this.onTap});

  @override
  State<SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<SidebarButton> {
  double _opacity = 1.0; // Default opacity
  bool _shouldAnimate = false; // Controls animation behavior

  void _handleTapDown(TapDownDetails details) {
    // On touch start, immediately set opacity to 20%
    setState(() {
      _shouldAnimate = false; // Disable animation for this state change
      _opacity = 0.4;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    // On touch end, animate back to full opacity (1.0)
    setState(() {
      _shouldAnimate = true; // Enable animation for this state change
      _opacity = 1.0;
    });

    // Trigger the onTap callback
    widget.onTap();
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
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedOpacity(
        duration: _shouldAnimate
            ? const Duration(milliseconds: 200) // Animate back to 100%
            : Duration.zero, // Immediate change for touch start
        opacity: _opacity,
        child: const Icon(CupertinoIcons.sidebar_left),
      ),
    );
  }
}
