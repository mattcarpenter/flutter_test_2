import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cook_provider.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Corner radius for the inverted corners effect
const double _kCornerRadius = 12.0;

/// Global status bar shown when there are active cooks (or future: active timers).
/// This wraps the entire app navigator to be visible on ALL routes.
class GlobalStatusBarWrapper extends ConsumerWidget {
  final Widget child;

  const GlobalStatusBarWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCooks = ref.watch(inProgressCooksProvider);
    final activeCookCount = activeCooks.length;
    final shouldShowStatusBar = activeCookCount > 0;
    // Future: || ref.watch(activeTimersProvider).isNotEmpty;

    final mediaQuery = MediaQuery.of(context);
    final safeAreaTop = mediaQuery.padding.top;

    // Compact bar: just enough for text + small bottom margin
    const contentBarHeight = 22.0;

    // Full height of the bar when fully visible
    final fullStatusBarHeight = safeAreaTop + contentBarHeight;

    final statusBarColor = AppColorSwatches.primary[500]!;

    // MediaQuery is OUTSIDE the animation - only changes when shouldShowStatusBar changes.
    // This prevents expensive per-frame rebuilds of the entire widget tree.
    // When bar is visible, tell children safe area is handled (padding.top = 0).
    final adjustedMediaQuery = mediaQuery.copyWith(
      padding: mediaQuery.padding.copyWith(
        top: shouldShowStatusBar ? 0 : safeAreaTop,
      ),
    );

    return MediaQuery(
      data: adjustedMediaQuery,
      child: TweenAnimationBuilder<double>(
      // Animate between "hidden" (0.0) and "visible" (1.0)
      tween: Tween<double>(end: shouldShowStatusBar ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      // Pass child so it doesn't rebuild every animation tick
      child: child,
      builder: (context, visibility, child) {
        final t = visibility.clamp(0.0, 1.0);

        // Bottom edge of the status bar from the top of the screen.
        final barHeight = fullStatusBarHeight * t;

        return Stack(
          children: [
            // Main app content, positioned below the status bar.
            // Using Positioned (not Transform) so the child's LAYOUT
            // shrinks to fit, keeping bottom nav in the correct position.
            Positioned(
              top: barHeight,
              left: 0,
              right: 0,
              bottom: 0,
              child: RepaintBoundary(
                child: child!,
              ),
            ),

            // Animated status bar drawn over the top.
            if (t > 0)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: barHeight,
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: statusBarColor,
                  ),
                  padding: EdgeInsets.only(
                    // As the bar appears, we gradually grow the safe-area padding
                    // so that by t=1 the notch / system bar region is fully filled.
                    top: safeAreaTop * t,
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: 6.0, // Small margin between text and bottom edge
                  ),
                  alignment: Alignment.bottomLeft,
                  child: Opacity(
                    opacity: t,
                    child: _GlobalStatusBar(activeCookCount: activeCookCount),
                  ),
                ),
              ),

            // Inverted corners - painted on top of content to create
            // the illusion that content has rounded top corners
            // sitting on the status bar.
            if (t > 0) ...[
              // Top-left inverted corner
              Positioned(
                top: barHeight,
                left: 0,
                child: Opacity(
                  opacity: t,
                  child: _InvertedCorner(
                    color: statusBarColor,
                    size: _kCornerRadius,
                    corner: _Corner.topLeft,
                  ),
                ),
              ),
              // Top-right inverted corner
              Positioned(
                top: barHeight,
                right: 0,
                child: Opacity(
                  opacity: t,
                  child: _InvertedCorner(
                    color: statusBarColor,
                    size: _kCornerRadius,
                    corner: _Corner.topRight,
                  ),
                ),
              ),
            ],
          ],
        );
      },
      ),
    );
  }
}

/// The actual status bar content widget.
class _GlobalStatusBar extends StatelessWidget {
  final int activeCookCount;

  const _GlobalStatusBar({required this.activeCookCount});

  @override
  Widget build(BuildContext context) {
    final text = activeCookCount == 1
        ? 'Active Cook'
        : '$activeCookCount Active Cooks';

    // Background color and padding handled by parent container
    return Text(
      text,
      style: AppTypography.body.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Which corner the inverted corner is for
enum _Corner { topLeft, topRight }

/// An inverted corner decoration that creates the illusion of rounded corners
/// on the content below. This is painted ON TOP of the content using the
/// status bar color, filling the space that would be outside a rounded corner.
class _InvertedCorner extends StatelessWidget {
  final Color color;
  final double size;
  final _Corner corner;

  const _InvertedCorner({
    required this.color,
    required this.size,
    required this.corner,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _InvertedCornerPainter(
        color: color,
        corner: corner,
      ),
    );
  }
}

/// CustomPainter that draws an inverted corner - a small square with a
/// quarter-circle cut out, creating the visual effect of a rounded corner
/// on whatever is behind it.
class _InvertedCornerPainter extends CustomPainter {
  final Color color;
  final _Corner corner;

  _InvertedCornerPainter({
    required this.color,
    required this.corner,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final s = size.width; // Assuming square

    switch (corner) {
      case _Corner.topLeft:
      // Fill is in top-left, concave curve bows inward toward corner
      // Path: top-left → top-right → arc to bottom-left → close
        path.moveTo(0, 0);
        path.lineTo(s, 0);
        path.arcToPoint(
          Offset(0, s),
          radius: Radius.circular(s),
          clockwise: false, // Counter-clockwise = concave (bows toward top-left)
        );
        path.close();
        break;

      case _Corner.topRight:
      // Fill is in top-right, concave curve bows inward toward corner
      // Path: top-right → top-left → arc to bottom-right → close
        path.moveTo(s, 0);
        path.lineTo(0, 0);
        path.arcToPoint(
          Offset(s, s),
          radius: Radius.circular(s),
          clockwise: true, // Clockwise from top-left to bottom-right = concave
        );
        path.close();
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _InvertedCornerPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.corner != corner;
  }
}
