import 'package:flutter/material.dart';

/// Utility function that checks if the tap location is outside a specified key's RenderBox
/// Used to determine whether to show a context menu based on tap location
bool isLocationOutsideKey(Offset location, GlobalKey key) {
  final renderObject = key.currentContext?.findRenderObject();

  if (renderObject is RenderBox) {
    final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    // If the location is within the specified area, return false
    if (rect.contains(location)) {
      return false;
    }
  }

  // Otherwise, allow the context menu
  return true;
}

/// ProxyDecorator for ReorderableListView to create a nice lifting effect
Widget defaultProxyDecorator(Widget child, int index, Animation<double> animation) {
  // Use tweens to define the animation ranges
  final scaleTween = Tween<double>(begin: 1.0, end: 1.05);
  final opacityTween = Tween<double>(begin: 1.0, end: 0.85);

  // Create a curved animation for more natural feel
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.easeInOut,
  );

  return AnimatedBuilder(
    animation: curvedAnimation,
    builder: (context, child) {
      final scale = scaleTween.evaluate(curvedAnimation);
      final opacity = opacityTween.evaluate(curvedAnimation);

      return Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Material(
            borderRadius: BorderRadius.circular(8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.09 * animation.value),
                    blurRadius: 9.0 * animation.value,
                    spreadRadius: 2.0 * animation.value,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      );
    },
    child: child,
  );
}