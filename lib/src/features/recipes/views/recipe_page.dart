import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../providers/recipe_provider.dart' as recipe_provider;
import '../widgets/recipe_view/recipe_view.dart';
import '../widgets/recipe_view/recipe_hero_image.dart';
import '../widgets/recipe_view/ingredient_matches_bottom_sheet.dart';

class RecipePage extends ConsumerStatefulWidget {
  final String recipeId;
  final String previousPageTitle;

  const RecipePage({super.key, required this.recipeId, required this.previousPageTitle});

  @override
  ConsumerState<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends ConsumerState<RecipePage> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _snapAnimationController;
  Animation<double>? _snapAnimation;
  static const double _heroHeight = 300.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _snapAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  bool _isSnapping = false;

  bool _onScrollNotification(ScrollNotification notification) {
    if (_isSnapping) return false;

    // Detect when scrolling ends
    if (notification is ScrollEndNotification) {
      final offset = _scrollController.offset;
      final headerHeight = MediaQuery.of(context).padding.top + 60;
      final headerFadeStartOffset = _heroHeight * 0.5;
      final headerFadeEndOffset = _heroHeight - (headerHeight/2);
      final headerFadeDuration = headerFadeEndOffset - headerFadeStartOffset;
      final headerOpacity = ((offset - headerFadeStartOffset) / headerFadeDuration).clamp(0.0, 1.0);

      // If we're in the fade zone, snap based on opacity
      if (offset > headerFadeStartOffset && offset < headerFadeEndOffset) {
        if (headerOpacity > 0.5) {
          _snapToComplete(headerFadeEndOffset + 2.0); // Add 2px buffer to ensure complete hiding
        } else {
          _snapToStart(headerFadeStartOffset);
        }
      }
    }
    return false;
  }

  void _snapToComplete(double targetOffset) async {
    _isSnapping = true;

    try {
      if (_scrollController.hasClients) {
        // Try animateTo first - it may get partway there
        await _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );

        // If we're not close enough to the target, finish with custom animation
        if ((_scrollController.offset - targetOffset).abs() > 2) {
          await _smoothScrollTo(targetOffset);
        }
      }
    } catch (e) {
      // Fallback to custom animation if animateTo fails completely
      await _smoothScrollTo(targetOffset);
    }

    _isSnapping = false;
  }

  void _snapToStart(double targetOffset) async {
    _isSnapping = true;

    try {
      if (_scrollController.hasClients) {
        // For snapping back, animateTo usually works better
        await _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );

        // Custom animation fallback if needed
        if ((_scrollController.offset - targetOffset).abs() > 2) {
          await _smoothScrollTo(targetOffset);
        }
      }
    } catch (e) {
      await _smoothScrollTo(targetOffset);
    }

    _isSnapping = false;
  }

  Future<void> _smoothScrollTo(double targetOffset) async {
    final startOffset = _scrollController.offset;

    _snapAnimation = Tween<double>(
      begin: startOffset,
      end: targetOffset,
    ).animate(CurvedAnimation(
      parent: _snapAnimationController,
      curve: Curves.easeOutCubic,
    ));

    void animationListener() {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_snapAnimation!.value);
      }
    }

    _snapAnimation!.addListener(animationListener);
    _snapAnimationController.reset();

    try {
      await _snapAnimationController.forward();
    } finally {
      _snapAnimation!.removeListener(animationListener);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _snapAnimationController.dispose();
    super.dispose();
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

          return Stack(
            children: [
              // Main scrollable content with scroll notification listener
              NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: CustomScrollView(
                  controller: _scrollController,
                slivers: [
                  // Hero image header
                  SliverAppBar(
                    expandedHeight: _heroHeight,
                    pinned: false,
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.transparent,
                    flexibleSpace: Stack(
                      children: [
                        // Hero image
                        Positioned.fill(
                          child: recipe.images != null && recipe.images!.isNotEmpty
                              ? AnimatedBuilder(
                                  animation: _scrollController,
                                  builder: (context, child) {
                                    final offset = _scrollController.hasClients ? _scrollController.offset : 0;
                                    final headerHeight = MediaQuery.of(context).padding.top + 60;

                                    // Header fade timing (unchanged)
                                    final headerFadeStartOffset = _heroHeight * 0.5;
                                    final headerFadeEndOffset = _heroHeight - (headerHeight/2);
                                    final headerFadeDuration = headerFadeEndOffset - headerFadeStartOffset;
                                    final headerOpacity = ((offset - headerFadeStartOffset) / headerFadeDuration).clamp(0.0, 1.0);

                                    // Pin button fade timing (earlier)
                                    final pinButtonFadeStartOffset = _heroHeight * 0.3;  // Start earlier (90px)
                                    final pinButtonFadeEndOffset = _heroHeight * 0.6;    // End earlier (180px)
                                    final pinButtonFadeDuration = pinButtonFadeEndOffset - pinButtonFadeStartOffset;
                                    final pinButtonOpacity = 1.0 - ((offset - pinButtonFadeStartOffset) / pinButtonFadeDuration).clamp(0.0, 1.0);

                                    return RecipeHeroImage(
                                      images: recipe.images!,
                                      recipeId: recipe.id,
                                      pinButtonOpacity: pinButtonOpacity,
                                    );
                                  },
                                )
                              : Container(
                                  color: AppColors.of(context).surfaceVariant,
                                  child: Center(
                                    child: Icon(
                                      Icons.restaurant,
                                      size: 80,
                                      color: AppColors.of(context).textSecondary,
                                    ),
                                  ),
                                ),
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
              _buildStickyNavigationOverlay(context),
              // Sticky navigation buttons (outside the scroll view)
              _buildStickyNavigationButtons(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStickyNavigationOverlay(BuildContext context) {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        final offset = _scrollController.hasClients ? _scrollController.offset : 0;

        // Calculate fade timing based on SliverAppBar collapse behavior
        final headerHeight = MediaQuery.of(context).padding.top + 60;
        final fadeStartOffset = _heroHeight * 0.5;                    // Start at 50% (150px)
        final fadeEndOffset = _heroHeight - (headerHeight/2);             // End when image bottom touches header bottom
        final fadeDuration = fadeEndOffset - fadeStartOffset;         // Fade duration

        final opacity = ((offset - fadeStartOffset) / fadeDuration).clamp(0.0, 1.0);

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: headerHeight,
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

  Widget _buildStickyNavigationButtons(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          AppCircleButton(
            icon: AppCircleButtonIcon.close,
            variant: AppCircleButtonVariant.neutral,
            size: 40,
            onPressed: () => Navigator.of(context).pop(),
          ),
          // Menu button
          AdaptivePullDownButton(
            items: [
              AdaptiveMenuItem(
                title: 'Check Pantry Stock',
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
              AdaptiveMenuItem(
                title: 'Edit Recipe',
                icon: const Icon(CupertinoIcons.pencil),
                onTap: () {
                  // TODO: Implement edit functionality
                },
              ),
            ],
            child: const AppCircleButton(
              icon: AppCircleButtonIcon.ellipsis,
              variant: AppCircleButtonVariant.neutral,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeContent(BuildContext context, recipe) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: RecipeView(
          recipeId: widget.recipeId,
          showHeroImage: false, // Tell RecipeView not to show image gallery
          key: ValueKey('RecipeView-${widget.recipeId}-${DateTime.now().millisecondsSinceEpoch}'),
        ),
      ),
    );
  }
}


