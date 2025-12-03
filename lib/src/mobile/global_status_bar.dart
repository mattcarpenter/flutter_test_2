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

  /// Calculate the status bar height when visible.
  /// This includes SafeArea top padding + content padding + text.
  double _calculateStatusBarHeight(BuildContext context) {
    final safeAreaTop = MediaQuery.of(context).padding.top;
    // Compact bar: just enough for text + small bottom margin
    const contentHeight = 22.0;
    return safeAreaTop + contentHeight;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCooks = ref.watch(inProgressCooksProvider);
    final activeCookCount = activeCooks.length;
    final shouldShowStatusBar = activeCookCount > 0;
    // Future: || ref.watch(activeTimersProvider).isNotEmpty;

    final fullStatusBarHeight = _calculateStatusBarHeight(context);
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final targetHeight = shouldShowStatusBar ? fullStatusBarHeight : 0.0;
    final statusBarColor = AppColorSwatches.primary[500]!;

    // Use TweenAnimationBuilder to synchronize the container height animation
    // with the MediaQuery adjustments - this prevents the "jump then animate" issue
    // Note: begin is intentionally null so it uses the current animated value for transitions
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: targetHeight),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, animatedHeight, _) {
        // Calculate visibility ratio for smooth padding interpolation
        // When fully visible: 1.0, when hidden: 0.0
        // This prevents the discrete jump that occurred with a boolean switch
        final visibilityRatio = fullStatusBarHeight > 0
            ? (animatedHeight / fullStatusBarHeight).clamp(0.0, 1.0)
            : 0.0;

        // Smoothly interpolate padding.top:
        // - When status bar visible (ratio=1): padding.top = 0 (bar handles safe area)
        // - When status bar hidden (ratio=0): padding.top = original (content needs safe area)
        final adjustedPaddingTop = safeAreaTop * (1.0 - visibilityRatio);

        return Column(
          children: [
            // Status bar container - height driven by animation
            Container(
              height: animatedHeight,
              width: double.infinity,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: statusBarColor,
              ),
              padding: EdgeInsets.only(
                top: safeAreaTop,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: 6.0, // Small margin between text and bottom edge
              ),
              alignment: Alignment.bottomLeft,
              child: _GlobalStatusBar(activeCookCount: activeCookCount),
            ),
            // Main content (all routes) with inverted corner decorations
            Expanded(
              child: MediaQuery(
                // Use animatedHeight (not target) so MediaQuery changes sync with animation
                data: MediaQuery.of(context).copyWith(
                  size: Size(
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height - animatedHeight,
                  ),
                  // Smoothly interpolate padding.top based on visibility ratio
                  // This prevents content from jumping when animation completes
                  padding: MediaQuery.of(context).padding.copyWith(
                    top: adjustedPaddingTop,
                  ),
                ),
                // Stack to overlay the inverted corners on top of content
                child: Stack(
                  children: [
                    // Actual content
                    child,
                    // Inverted corners - painted on top of content to create
                    // the illusion that content has rounded top corners
                    // sitting on the status bar
                    if (visibilityRatio > 0) ...[
                      // Top-left inverted corner
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Opacity(
                          opacity: visibilityRatio,
                          child: _InvertedCorner(
                            color: statusBarColor,
                            size: _kCornerRadius,
                            corner: _Corner.topLeft,
                          ),
                        ),
                      ),
                      // Top-right inverted corner
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Opacity(
                          opacity: visibilityRatio,
                          child: _InvertedCorner(
                            color: statusBarColor,
                            size: _kCornerRadius,
                            corner: _Corner.topRight,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
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

    // Background color and padding handled by parent AnimatedContainer
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
