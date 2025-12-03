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

    final statusBarHeight = shouldShowStatusBar ? _calculateStatusBarHeight(context) : 0.0;

    final fullStatusBarHeight = _calculateStatusBarHeight(context);
    final safeAreaTop = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        // Animated status bar - always render content, animate container height
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: shouldShowStatusBar ? fullStatusBarHeight : 0,
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          color: AppColorSwatches.success[500],
          // Manual padding instead of SafeArea to avoid layout issues
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
            // Adjust size.height so children using MediaQuery.of(context).size.height
            // get the correct available height (accounting for status bar)
            data: MediaQuery.of(context).copyWith(
              size: Size(
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height - statusBarHeight,
              ),
              padding: shouldShowStatusBar
                  ? MediaQuery.of(context).padding.copyWith(top: 0)
                  : MediaQuery.of(context).padding,
            ),
            child: child,
          ),
        ),
      ],
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
