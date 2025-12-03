import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cook_provider.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Global status bar shown when there are active cooks (or future: active timers).
/// This wraps the entire app navigator to be visible on ALL routes.
class GlobalStatusBarWrapper extends ConsumerWidget {
  final Widget child;

  const GlobalStatusBarWrapper({super.key, required this.child});

  /// Calculate the status bar height when visible.
  /// This includes SafeArea top padding + content padding + text.
  double _calculateStatusBarHeight(BuildContext context) {
    final safeAreaTop = MediaQuery.of(context).padding.top;
    // Vertical padding: AppSpacing.sm (8) * 2 = 16
    // Approximate text height: ~20px for body text
    const contentHeight = 16.0 + 20.0;
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
                color: AppColorSwatches.success[500],
              ),
              padding: EdgeInsets.only(
                top: safeAreaTop,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.sm,
              ),
              alignment: Alignment.centerLeft,
              child: _GlobalStatusBar(activeCookCount: activeCookCount),
            ),
            // Main content (all routes)
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
                child: child,
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
