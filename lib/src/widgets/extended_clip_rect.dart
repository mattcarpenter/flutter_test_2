import 'dart:ui';

import 'package:fluent_ui/fluent_ui.dart';

class ExtendedClipRect extends StatelessWidget {
  final Widget child;
  final double extraVerticalPadding;
  const ExtendedClipRect({
    Key? key,
    required this.child,
    this.extraVerticalPadding = 10.0, // adjust based on your shadow
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          clipper: _ExtendedClipper(extraVerticalPadding: extraVerticalPadding),
          child: child,
        );
      },
    );
  }
}

class _ExtendedClipper extends CustomClipper<Rect> {
  final double extraVerticalPadding;
  _ExtendedClipper({required this.extraVerticalPadding});

  @override
  Rect getClip(Size size) {
    // Extend the clip region vertically while keeping the horizontal bounds the same.
    return Rect.fromLTRB(
      0,
      -extraVerticalPadding,
      size.width,
      size.height + extraVerticalPadding,
    );
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => true;
}
