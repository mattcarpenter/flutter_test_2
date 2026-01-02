import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../localization/l10n_extension.dart';
import '../../../theme/colors.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../providers/recipe_provider.dart' as recipe_provider;
import '../widgets/recipe_view/recipe_view.dart';
import '../widgets/recipe_view/recipe_hero_image.dart';
import '../widgets/recipe_view/ingredient_matches_bottom_sheet.dart';
import 'add_recipe_modal.dart';
import 'locked_recipe_page.dart';

class RecipePage extends ConsumerStatefulWidget {
  final String recipeId;
  final String previousPageTitle;

  const RecipePage({super.key, required this.recipeId, required this.previousPageTitle});

  @override
  ConsumerState<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends ConsumerState<RecipePage> {
  late ScrollController _scrollController;
  static const double _heroHeightWithImage = 300.0;
  static const double _heroHeightWithoutImage = 150.0;
  bool _isSnapping = false;

  double _getHeroHeight(bool hasImages) =>
      hasImages ? _heroHeightWithImage : _heroHeightWithoutImage;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScrollEnd(ScrollMetrics metrics, BuildContext context, bool hasImages) {
    if (_isSnapping) return;

    // Disable snapping when no images
    if (!hasImages) return;

    final heroHeight = _getHeroHeight(hasImages);
    // Use viewPadding.top for consistent snap timing regardless of global status bar
    final fadeHeaderHeight = MediaQuery.viewPaddingOf(context).top + 60;
    final snapStart = heroHeight * 0.5;
    final snapEnd = heroHeight - (fadeHeaderHeight / 2);
    final currentOffset = metrics.pixels;

    // Only snap if we're in the snap zone
    if (currentOffset > snapStart && currentOffset < snapEnd) {
      final fadeDuration = snapEnd - snapStart;
      final progress = ((currentOffset - snapStart) / fadeDuration).clamp(0.0, 1.0);

      // Add small buffer to snapEnd to ensure image is fully hidden
      final target = progress > 0.5 ? snapEnd + 2.0 : snapStart;

      // Only animate if we're not already at target
      if ((currentOffset - target).abs() > 1.0) {
        _isSnapping = true;
        _scrollController
            .animateTo(
          target,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        )
            .then((_) {
          _isSnapping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(recipe_provider.recipeByIdStreamProvider(widget.recipeId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.of(context).background,
      body: recipeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading recipe: $error')),
        data: (recipe) {
          if (recipe == null) {
            return const Center(child: Text('Recipe not found'));
          }

          // Check if this recipe is locked BEFORE building content
          final isLocked = ref.watch(recipe_provider.isRecipeLockedProvider(recipe.id));
          if (isLocked) {
            return LockedRecipePage(recipe: recipe);
          }

          // Determine if recipe has images
          final hasImages = recipe.images != null && recipe.images!.isNotEmpty;
          final heroHeight = _getHeroHeight(hasImages);

          // Calculate snap offsets based on fade zone
          // Use viewPadding.top for consistent timing regardless of global status bar
          final fadeHeaderHeight = MediaQuery.viewPaddingOf(context).top + 60;
          final snapStart = heroHeight * 0.5;
          final snapEnd = heroHeight - (fadeHeaderHeight / 2);

          return Stack(
            children: [
              // Main scrollable content with notification listener for snap
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // Listen for when user stops scrolling (includes momentum)
                  if (notification is ScrollEndNotification &&
                      notification.metrics.axis == Axis.vertical) {
                    // Use a small delay to ensure scroll has truly settled
                    Future.delayed(const Duration(milliseconds: 50), () {
                      if (mounted && !_isSnapping) {
                        _handleScrollEnd(notification.metrics, context, hasImages);
                      }
                    });
                  }
                  return false;
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                  // Hero image header
                  SliverAppBar(
                    expandedHeight: heroHeight,
                    pinned: false,
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.transparent,
                    flexibleSpace: Stack(
                      children: [
                        // Hero image or placeholder
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _scrollController,
                            builder: (context, child) {
                              final offset = _scrollController.hasClients ? _scrollController.offset : 0;
                              // Use viewPadding.top for consistent fade timing regardless of global status bar
                              final fadeHeaderHeight = MediaQuery.viewPaddingOf(context).top + 60;

                              // Header fade timing (unchanged)
                              final headerFadeStartOffset = heroHeight * 0.5;
                              final headerFadeEndOffset = heroHeight - (fadeHeaderHeight/2);
                              final headerFadeDuration = headerFadeEndOffset - headerFadeStartOffset;
                              final headerOpacity = ((offset - headerFadeStartOffset) / headerFadeDuration).clamp(0.0, 1.0);

                              // Pin button fade timing (conditional based on images)
                              final pinButtonFadeStartOffset = hasImages
                                ? heroHeight * 0.3  // 90px for 300px hero
                                : heroHeight * 0.1; // 15px for 150px hero
                              final pinButtonFadeEndOffset = hasImages
                                ? heroHeight * 0.6  // 180px for 300px hero
                                : heroHeight * 0.4; // 60px for 150px hero
                              final pinButtonFadeDuration = pinButtonFadeEndOffset - pinButtonFadeStartOffset;
                              final pinButtonOpacity = 1.0 - ((offset - pinButtonFadeStartOffset) / pinButtonFadeDuration).clamp(0.0, 1.0);

                              return RecipeHeroImage(
                                images: recipe.images ?? [],
                                recipeId: recipe.id,
                                pinButtonOpacity: pinButtonOpacity,
                              );
                            },
                          ),
                        ),
                        // Rounded white overlay at bottom of hero with animated radius
                        AnimatedBuilder(
                          animation: _scrollController,
                          builder: (context, child) {
                            final offset = _scrollController.hasClients ? _scrollController.offset : 0;
                            // Use viewPadding.top for consistent fade timing regardless of global status bar
                            final fadeHeaderHeight = MediaQuery.viewPaddingOf(context).top + 60;

                            // Using the fade end offset approach (which was close in attempt 3)
                            // but adjusting for the 16px rounded overlay height
                            // The fadeEndOffset = heroHeight - (fadeHeaderHeight/2) was ending when
                            // content meets header, so subtract 16px to end when rounded rect meets header
                            final fadeEndOffset = heroHeight - (fadeHeaderHeight / 2);
                            final meetingPoint = fadeEndOffset - 16;

                            // Start animation at 90% of the way to meeting point
                            final animStart = meetingPoint * 0.90;
                            // End animation when rounded rect top meets header bottom
                            final animEnd = meetingPoint;

                            // Calculate current radius
                            double radius;
                            if (offset < animStart) {
                              radius = 16.0; // Full radius
                            } else if (offset >= animEnd) {
                              radius = 0.0; // Straight corners
                            } else {
                              // Tween from 16 to 0 as we approach meeting point
                              final progress = (offset - animStart) / (animEnd - animStart);
                              radius = 16.0 * (1.0 - progress);
                            }

                            // Clamp to ensure no negative values
                            radius = radius.clamp(0.0, 16.0);

                            return Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 16,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.of(context).background,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(radius),
                                    topRight: Radius.circular(radius),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Recipe content
                  SliverToBoxAdapter(
                    child: _buildRecipeContent(context, recipe),
                  ),
                ],
                ),
              ),
              // Sticky navigation overlay (outside the scroll view)
              _buildStickyNavigationOverlay(context, hasImages),
              // Sticky navigation buttons (outside the scroll view)
              _buildStickyNavigationButtons(context, hasImages),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStickyNavigationOverlay(BuildContext context, bool hasImages) {
    final heroHeight = _getHeroHeight(hasImages);

    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        final offset = _scrollController.hasClients ? _scrollController.offset : 0;

        // Use viewPadding.top for consistent fade timing regardless of global status bar
        final fadeHeaderHeight = MediaQuery.viewPaddingOf(context).top + 60;
        // Use padding.top for overlay sizing (adapts to current layout context)
        final overlayHeaderHeight = MediaQuery.paddingOf(context).top + 60;

        // For images: start fade at 50% of hero
        // For no images: start at 0 (shorter hero needs earlier fade start for smooth animation)
        // End offset uses same formula - when rounded rect top reaches header middle
        final fadeStartOffset = hasImages ? heroHeight * 0.5 : 0.0;
        final fadeEndOffset = heroHeight - (fadeHeaderHeight / 2) - 16;
        final fadeDuration = (fadeEndOffset - fadeStartOffset).clamp(1.0, double.infinity);

        final opacity = ((offset - fadeStartOffset) / fadeDuration).clamp(0.0, 1.0);

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: overlayHeaderHeight,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.of(context).background.withValues(alpha: opacity),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.of(context).border.withValues(alpha: opacity),
                  width: 0.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStickyNavigationButtons(BuildContext context, bool hasImages) {
    final heroHeight = _getHeroHeight(hasImages);

    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        final offset = _scrollController.hasClients ? _scrollController.offset : 0;

        // Use viewPadding.top for consistent fade timing regardless of global status bar
        final fadeHeaderHeight = MediaQuery.viewPaddingOf(context).top + 60;

        // For images: start fade at 50% of hero
        // For no images: start at 0 (shorter hero needs earlier fade start for smooth animation)
        // End offset uses same formula - when rounded rect top reaches header middle
        final fadeStartOffset = hasImages ? heroHeight * 0.5 : 0.0;
        final fadeEndOffset = heroHeight - (fadeHeaderHeight / 2) - 16;
        final fadeDuration = (fadeEndOffset - fadeStartOffset).clamp(1.0, double.infinity);

        final opacity = ((offset - fadeStartOffset) / fadeDuration).clamp(0.0, 1.0);

        // Smoothly transition button colors from overlay (light) to neutral (theme-aware)
        // as header becomes opaque during scroll
        // Use padding.top for button positioning (adapts to current layout context)
        return Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              AppCircleButton(
                icon: AppCircleButtonIcon.close,
                variant: AppCircleButtonVariant.overlay,
                colorTransitionProgress: opacity,
                size: 40,
                onPressed: () => Navigator.of(context).pop(),
              ),
              // Menu button
              AdaptivePullDownButton(
                items: [
                  AdaptiveMenuItem(
                    title: context.l10n.recipePageEditRecipe,
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit01),
                    onTap: () {
                      final recipeAsync = ref.read(recipe_provider.recipeByIdStreamProvider(widget.recipeId));
                      recipeAsync.whenOrNull(
                        data: (recipe) {
                          if (recipe != null) {
                            showRecipeEditorModal(context, recipe: recipe, isEditing: true);
                          }
                        },
                      );
                    },
                  ),
                  AdaptiveMenuItem.divider(),
                  AdaptiveMenuItem(
                    title: context.l10n.recipePageCheckPantryStock,
                    icon: const Icon(CupertinoIcons.checkmark_alt_circle),
                    onTap: () {
                      // Read the matches when the menu item is tapped (not during build)
                      final matchesAsync = ref.read(recipe_provider.recipeIngredientMatchesProvider(widget.recipeId));
                      matchesAsync.whenOrNull(
                        data: (matches) {
                          showIngredientMatchesBottomSheet(
                            context,
                            matches: matches,
                          );
                        },
                      );
                    },
                  ),
                ],
                child: AppCircleButton(
                  icon: AppCircleButtonIcon.ellipsis,
                  variant: AppCircleButtonVariant.overlay,
                  colorTransitionProgress: opacity,
                  size: 40,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecipeContent(BuildContext context, recipe) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).background,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40), // Extra bottom padding prevents scroll oscillation on iPad
        child: RecipeView(
          recipeId: widget.recipeId,
          showHeroImage: false, // Tell RecipeView not to show image gallery
          key: ValueKey('RecipeView-${widget.recipeId}-${DateTime.now().millisecondsSinceEpoch}'),
        ),
      ),
    );
  }
}


