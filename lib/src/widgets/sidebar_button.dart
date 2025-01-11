import 'package:flutter/cupertino.dart';

class SidebarButton extends StatefulWidget {
  final VoidCallback onTap;

  const SidebarButton({super.key, required this.onTap});

  @override
  State<SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<SidebarButton> {
  double _opacity = 1.0;
  bool _shouldAnimate = false;

  void _handleTap() {
    // Trigger the onTap callback
    widget.onTap();

    // Immediately set opacity to 0 (no animation)
    setState(() {
      _shouldAnimate = false; // Disable animation
      _opacity = 0.0;
    });

    // Animate fade-in after a short delay
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          _shouldAnimate = true; // Enable animation
          _opacity = 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedOpacity(
        duration: _shouldAnimate
            ? const Duration(milliseconds: 200) // Fade-in duration
            : Duration.zero, // No animation for fade-out
        opacity: _opacity,
        child: const Icon(CupertinoIcons.sidebar_left),
      ),
    );
  }
}
