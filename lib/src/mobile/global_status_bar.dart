import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../database/database.dart';
import '../../database/models/timers.dart';
import '../features/recipes/widgets/cook_modal/cook_modal.dart';
import '../features/timers/widgets/timer_expiration_listener.dart';
import '../providers/cook_provider.dart';
import '../providers/timer_provider.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'adaptive_app.dart' show globalRootNavigatorKey;

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
  void _toggleExpand() {
    // Dismiss any open timer action sheet first
    _TimerMenuButton.dismissSheet();

    ref.read(statusBarExpandedProvider.notifier).state =
        !ref.read(statusBarExpandedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = ref.watch(statusBarExpandedProvider);
    final activeCooks = ref.watch(inProgressCooksProvider);
    final activeTimers = ref.watch(activeTimersProvider);
    final shouldShowStatusBar = activeCooks.isNotEmpty || activeTimers.isNotEmpty;

    final mediaQuery = MediaQuery.of(context);
    final safeAreaTop = mediaQuery.padding.top;

    // Content heights for collapsed/expanded states
    const collapsedContentHeight = 22.0;
    // Expanded height: header(22) + gap(8) + buttons(28) + bottomMargin(10) = 68 for first cook
    // Each additional cook: gap(12) + header(22) + gap(8) + buttons(28) = 70, plus extra 6px bottom margin
    const firstCookExpandedHeight = 68.0;
    const additionalCookHeight = 70.0;
    const extraBottomMarginForMultipleCooks = 6.0;
    // Timer expanded height: header(22) + gap(8) + timer item(28) = 58 for first timer
    // Each additional timer: gap(8) + timer item(28) = 36
    const firstTimerExpandedHeight = 58.0;
    const additionalTimerHeight = 36.0;

    double expandedContentHeight = collapsedContentHeight;
    if (activeCooks.isNotEmpty) {
      expandedContentHeight = firstCookExpandedHeight
          + (activeCooks.length - 1) * additionalCookHeight
          + (activeCooks.length > 1 ? extraBottomMarginForMultipleCooks : 0);
    }
    // Add timer height if there are timers
    if (activeTimers.isNotEmpty) {
      // Add separator if we have cooks
      if (activeCooks.isNotEmpty) {
        expandedContentHeight += 16; // Gap before timer section
      }
      // When no cooks, keep the base collapsedContentHeight (22) for the header row
      expandedContentHeight += firstTimerExpandedHeight
          + (activeTimers.length - 1) * additionalTimerHeight
          + 10; // Bottom margin
    }

    final statusBarColor = AppColorSwatches.primary[500]!;

    // Wrap everything with timer expiration listener
    return TimerExpirationListener(
      child: TweenAnimationBuilder<double>(
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
            end: isExpanded ? expandedContentHeight : collapsedContentHeight,
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
                          // Position content slightly into safe area for better centering.
                          // Use max(0, ...) to avoid negative padding in landscape.
                          top: math.max(0, safeAreaTop - 8),
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                        ),
                        // No alignment - content flows from top, stays fixed on expand
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Opacity(
                            opacity: showT,
                            child: _GlobalStatusBar(
                              activeCooks: activeCooks,
                              activeTimers: activeTimers,
                              isExpanded: isExpanded,
                            ),
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
      ),
    );
  }
}

/// The actual status bar content widget.
class _GlobalStatusBar extends StatelessWidget {
  final List<CookEntry> activeCooks;
  final List<TimerEntry> activeTimers;
  final bool isExpanded;

  const _GlobalStatusBar({
    required this.activeCooks,
    required this.activeTimers,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    if (activeCooks.isEmpty && activeTimers.isEmpty) return const SizedBox.shrink();

    final hasCooks = activeCooks.isNotEmpty;
    final hasTimers = activeTimers.isNotEmpty;

    // Only show header transition if multiple cooks (single cook shows same text)
    final needsHeaderTransition = activeCooks.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row - cooks on left, timers on right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side: Cook info
            if (hasCooks)
              Flexible(
                child: needsHeaderTransition
                    ? Stack(
                        children: [
                          // Collapsed header fades out
                          AnimatedOpacity(
                            opacity: isExpanded ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            child: _CollapsedHeader(activeCooks: activeCooks),
                          ),
                          // Expanded header fades in
                          AnimatedOpacity(
                            opacity: isExpanded ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: _CookHeaderRow(cook: activeCooks.first),
                          ),
                        ],
                      )
                    : _CookHeaderRow(cook: activeCooks.first),
              )
            else
              const Spacer(),

            // Right side: Timer info
            if (hasTimers)
              _TimerStatusDisplay(
                timer: activeTimers.first,
                totalTimers: activeTimers.length,
              ),
          ],
        ),

        // Expanded content - buttons and additional items (simple fade in/out)
        AnimatedOpacity(
          opacity: isExpanded ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cook buttons and additional cooks
              if (hasCooks) ...[
                const SizedBox(height: 8),
                _CookButtonRow(cook: activeCooks.first),
                // Additional cooks
                for (final cook in activeCooks.skip(1)) ...[
                  const SizedBox(height: 12),
                  _CookItem(cook: cook),
                ],
              ],

              // Timer section (if there are timers)
              if (hasTimers) ...[
                if (hasCooks) const SizedBox(height: 16),
                _TimerSection(timers: activeTimers),
              ],

              // Bottom margin
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}

/// Collapsed header - shows "🔥 Recipe Name" or "🔥 Cooking N recipes"
class _CollapsedHeader extends StatelessWidget {
  final List<CookEntry> activeCooks;

  const _CollapsedHeader({required this.activeCooks});

  @override
  Widget build(BuildContext context) {
    final count = activeCooks.length;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Show "Cooking" prefix on wider screens or for multiple recipes
    final isWideScreen = screenWidth >= 600;
    final showCookingPrefix = isWideScreen || count > 1;

    final String mainText;
    if (count == 1) {
      mainText = activeCooks.first.recipeName;
    } else {
      mainText = '$count recipes';
    }

    final textStyle = AppTypography.body.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          CupertinoIcons.flame_fill,
          color: Colors.white,
          size: 16,
        ),
        const SizedBox(width: 6),
        if (showCookingPrefix) ...[
          Text(
            'Cooking',
            style: count == 1
                ? textStyle.copyWith(fontWeight: FontWeight.w800)
                : textStyle,
          ),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            mainText,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: textStyle,
          ),
        ),
      ],
    );
  }
}

/// Header row for a single cook - shows "🔥 Recipe Name"
class _CookHeaderRow extends StatelessWidget {
  final CookEntry cook;

  const _CookHeaderRow({required this.cook});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWideScreen = screenWidth >= 600;

    final textStyle = AppTypography.body.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          CupertinoIcons.flame_fill,
          color: Colors.white,
          size: 16,
        ),
        const SizedBox(width: 6),
        if (isWideScreen) ...[
          Text(
            'Cooking',
            style: textStyle.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            cook.recipeName,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: textStyle,
          ),
        ),
      ],
    );
  }
}

/// Button row for a cook - Instructions, Recipe, and Complete buttons
class _CookButtonRow extends ConsumerWidget {
  final CookEntry cook;

  const _CookButtonRow({required this.cook});

  Future<void> _confirmAndCompleteCook(WidgetRef ref) async {
    final navigatorContext = globalRootNavigatorKey.currentContext;
    if (navigatorContext == null) return;

    final confirmed = await showCupertinoDialog<bool>(
      context: navigatorContext,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Complete Cook?'),
        content: Text('Mark "${cook.recipeName}" as complete?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(cookNotifierProvider.notifier).finishCook(cookId: cook.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Shared button properties
    final buttonPadding = WidgetStateProperty.all(
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
    final buttonShape = WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

    // Filled style for Instructions button
    final filledButtonStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.all(Colors.white),
      foregroundColor: WidgetStateProperty.all(AppColorSwatches.primary[500]),
      padding: buttonPadding,
      minimumSize: WidgetStateProperty.all(Size.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: buttonShape,
    );

    // Outline style for Recipe button
    final outlineButtonStyle = ButtonStyle(
      foregroundColor: WidgetStateProperty.all(Colors.white),
      side: WidgetStateProperty.all(
        BorderSide(color: Colors.white.withValues(alpha: 0.6)),
      ),
      padding: buttonPadding,
      minimumSize: WidgetStateProperty.all(Size.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: buttonShape,
    );

    final textStyle = AppTypography.caption.copyWith(
      fontWeight: FontWeight.w600,
    );

    // Left padding to align buttons with recipe name text (icon 16px + gap 6px = 22px)
    return Padding(
      padding: const EdgeInsets.only(left: 22),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            style: filledButtonStyle,
            onPressed: () {
              // Use global navigator key to get context for modal
              final navigatorContext = globalRootNavigatorKey.currentContext;
              if (navigatorContext != null) {
                showCookModal(
                  navigatorContext,
                  cookId: cook.id,
                  recipeId: cook.recipeId,
                );
              }
            },
            child: Text('Instructions', style: textStyle.copyWith(
              color: AppColorSwatches.primary[500],
            )),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            style: outlineButtonStyle,
            onPressed: () {
              // Use global navigator key for GoRouter navigation
              final navigatorContext = globalRootNavigatorKey.currentContext;
              if (navigatorContext != null) {
                final router = GoRouter.of(navigatorContext);
                final targetPath = '/recipe/${cook.recipeId}';
                // Don't push if already on this recipe's page
                // Check both location and full match list for nested navigators
                final currentLocation = router.state.uri.toString();
                if (!currentLocation.contains(targetPath)) {
                  router.push(targetPath);
                }
              }
            },
            child: Text('Recipe', style: textStyle.copyWith(
              color: Colors.white,
            )),
          ),
          const SizedBox(width: 12),
          // Complete cook button
          GestureDetector(
            onTap: () => _confirmAndCompleteCook(ref),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                CupertinoIcons.xmark,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full cook item with header and buttons - for 2nd+ cooks
class _CookItem extends StatelessWidget {
  final CookEntry cook;

  const _CookItem({required this.cook});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _CookHeaderRow(cook: cook),
        const SizedBox(height: 8),
        _CookButtonRow(cook: cook),
      ],
    );
  }
}

/// Timer status display for the collapsed header (right side).
/// Shows countdown and timer count.
class _TimerStatusDisplay extends StatelessWidget {
  final TimerEntry timer;
  final int totalTimers;

  const _TimerStatusDisplay({
    required this.timer,
    required this.totalTimers,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTypography.body.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );

    // Tabular figures make all digits equal width, preventing layout shift
    final timerTextStyle = textStyle.copyWith(
      fontFeatures: [const FontFeature.tabularFigures()],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Offset icon down slightly to align with text baseline
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: const Icon(
            CupertinoIcons.timer,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          timer.formattedRemaining,
          style: timerTextStyle,
        ),
        if (totalTimers > 1) ...[
          const SizedBox(width: 4),
          Text(
            '+${totalTimers - 1}',
            style: textStyle.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

/// Timer section shown in expanded view.
class _TimerSection extends ConsumerWidget {
  final List<TimerEntry> timers;

  const _TimerSection({required this.timers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textStyle = AppTypography.body.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section header
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Offset icon down slightly to align with text baseline
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: const Icon(
                CupertinoIcons.timer,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Timers',
              style: textStyle.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Timer list
        for (final timer in timers) ...[
          _TimerItem(timer: timer),
          if (timer != timers.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Individual timer item with action menu.
class _TimerItem extends ConsumerWidget {
  final TimerEntry timer;

  const _TimerItem({required this.timer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textStyle = AppTypography.caption.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );

    // Tabular figures make all digits equal width, preventing layout shift
    final timerTextStyle = textStyle.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 14,
      fontFeatures: [const FontFeature.tabularFigures()],
    );

    return Padding(
      padding: const EdgeInsets.only(left: 22), // Align with header text
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Timer countdown
          Text(
            timer.formattedRemaining,
            style: timerTextStyle,
          ),
          const SizedBox(width: 8),
          // Recipe name and step
          Expanded(
            child: Text(
              '${timer.recipeName} · Step ${timer.stepDisplay}',
              style: textStyle.copyWith(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          // Menu button (on RIGHT)
          _TimerMenuButton(timer: timer),
          const SizedBox(width: 2),
        ],
      ),
    );
  }
}

/// Menu button for timer actions using CupertinoActionSheet.
class _TimerMenuButton extends ConsumerWidget {
  final TimerEntry timer;

  const _TimerMenuButton({required this.timer});

  /// Static flag to track if an action sheet is currently showing.
  /// Prevents multiple sheets from stacking.
  static bool _isSheetOpen = false;

  /// Static function to dismiss the currently open sheet.
  /// Called when status bar is tapped.
  static void dismissSheet() {
    if (_isSheetOpen) {
      final navigatorContext = globalRootNavigatorKey.currentContext;
      if (navigatorContext != null) {
        Navigator.of(navigatorContext).pop();
      }
      _isSheetOpen = false;
    }
  }

  void _showActionSheet(WidgetRef ref) {
    // Prevent multiple sheets from stacking
    if (_isSheetOpen) return;

    // Use global navigator context to show the action sheet
    final navigatorContext = globalRootNavigatorKey.currentContext;
    if (navigatorContext == null) return;

    _isSheetOpen = true;
    final timerNotifier = ref.read(timerNotifierProvider.notifier);

    showCupertinoModalPopup<void>(
      context: navigatorContext,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(timer.recipeName),
        message: Text('Step ${timer.stepDisplay} · ${timer.detectedText}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              await timerNotifier.extendTimer(
                timer.id,
                const Duration(minutes: 1),
              );
            },
            child: const Text('Extend 1 min'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              await timerNotifier.extendTimer(
                timer.id,
                const Duration(minutes: 5),
              );
            },
            child: const Text('Extend 5 min'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetContext).pop();
              // Look for an active cook for this recipe
              final activeCook = ref.read(activeCookForRecipeProvider(timer.recipeId));
              if (activeCook != null) {
                showCookModal(
                  navigatorContext,
                  cookId: activeCook.id,
                  recipeId: timer.recipeId,
                );
              } else {
                // No active cook - just navigate to recipe
                GoRouter.of(navigatorContext).push('/recipe/${timer.recipeId}');
              }
            },
            child: const Text('Instructions'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(sheetContext).pop();
              GoRouter.of(navigatorContext).push('/recipe/${timer.recipeId}');
            },
            child: const Text('View Recipe'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              // Show confirmation dialog
              final confirmed = await showCupertinoDialog<bool>(
                context: navigatorContext,
                builder: (dialogContext) => CupertinoAlertDialog(
                  title: const Text('Cancel Timer?'),
                  content: Text(
                    'Cancel the ${timer.detectedText} timer for "${timer.recipeName}"?',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Keep'),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('Cancel Timer'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await timerNotifier.cancelTimer(timer.id);
              }
            },
            child: const Text('Cancel Timer'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('Cancel'),
        ),
      ),
    ).then((_) {
      _isSheetOpen = false;
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Outlined style button for use on colored status bar background
    return GestureDetector(
      onTap: () => _showActionSheet(ref),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Icon(
            CupertinoIcons.ellipsis,
            color: Colors.white,
            size: 14,
          ),
        ),
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
