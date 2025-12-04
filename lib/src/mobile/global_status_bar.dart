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
class GlobalStatusBarWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalStatusBarWrapper({super.key, required this.child});

  @override
  ConsumerState<GlobalStatusBarWrapper> createState() =>
      _GlobalStatusBarWrapperState();
}

class _GlobalStatusBarWrapperState extends ConsumerState<GlobalStatusBarWrapper> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
    // Auto-collapse after delay for demo
    if (_isExpanded) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isExpanded) {
          setState(() => _isExpanded = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCooks = ref.watch(inProgressCooksProvider);
    final activeCookCount = activeCooks.length;
    final shouldShowStatusBar = activeCookCount > 0;
    // Future: || ref.watch(activeTimersProvider).isNotEmpty;

    final mediaQuery = MediaQuery.of(context);
    final safeAreaTop = mediaQuery.padding.top;

    // Content heights for collapsed/expanded states
    const collapsedContentHeight = 22.0;
    const expandedContentHeight = 80.0;

    final statusBarColor = AppColorSwatches.primary[500]!;

    return TweenAnimationBuilder<double>(
      // 0.0 = hidden, 1.0 = fully visible
      tween: Tween<double>(end: shouldShowStatusBar ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      // Pass child so it doesn't rebuild every animation tick
      child: widget.child,
      builder: (context, visibility, appChild) {
        final showT = visibility.clamp(0.0, 1.0);

        // Nested builder for expand/collapse animation
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(
            end: _isExpanded ? expandedContentHeight : collapsedContentHeight,
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, contentHeight, _) {
            // Content is pushed down by the content height (not safe area).
            // contentHeight animates between 22 (collapsed) and 80 (expanded).
            final topOffset = contentHeight * showT;

            // Full height of the bar (safe area + content).
            final fullStatusBarHeight = safeAreaTop + contentHeight;
            final barHeight = fullStatusBarHeight * showT;

            return Stack(
              children: [
                // Main app content (all routes).
                //
                // We change its *layout* top (not a transform) so:
                // - top moves down as the bar appears/expands
                // - bottom remains anchored at 0 → SafeArea bottom still respected,
                //   and the tab bar does NOT get pushed into the home indicator.
                Positioned(
                  top: topOffset,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: RepaintBoundary(
                    child: appChild!,
                  ),
                ),

                // Animated status bar drawn over the top.
                if (showT > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: barHeight,
                    child: GestureDetector(
                      onTap: _toggleExpand,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: statusBarColor,
                        ),
                        padding: EdgeInsets.only(
                          // padding.top is always the full safeAreaTop; as the
                          // container height grows, the safe-area region fills.
                          top: safeAreaTop,
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                          bottom: 6.0,
                        ),
                        alignment: Alignment.bottomLeft,
                        child: Opacity(
                          opacity: showT,
                          child: _GlobalStatusBar(
                            activeCookCount: activeCookCount,
                            isExpanded: _isExpanded,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Inverted corners - painted on top of content to create
                // the illusion that content has rounded top corners
                // sitting on the status bar.
                if (showT > 0) ...[
                  // Top-left inverted corner
                  Positioned(
                    top: barHeight,
                    left: 0,
                    child: Opacity(
                      opacity: showT,
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
                      opacity: showT,
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
        );
      },
    );
  }
}

/// The actual status bar content widget.
class _GlobalStatusBar extends StatelessWidget {
  final int activeCookCount;
  final bool isExpanded;

  const _GlobalStatusBar({
    required this.activeCookCount,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final text = activeCookCount == 1
        ? 'Active Cook'
        : '$activeCookCount Active Cooks';

    // Background color and padding handled by parent container
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: AppTypography.body.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap to collapse',
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ],
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
