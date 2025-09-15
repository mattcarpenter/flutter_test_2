import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../../../widgets/app_circle_button.dart';
import '../widgets/recipe_view/recipe_view.dart';
import '../widgets/recipe_view/recipe_hero_image.dart';

class RecipePage extends ConsumerStatefulWidget {
  final String recipeId;
  final String previousPageTitle;

  const RecipePage({super.key, required this.recipeId, required this.previousPageTitle});

  @override
  ConsumerState<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends ConsumerState<RecipePage> {
  late ScrollController _scrollController;
  static const double _heroHeight = 300.0;

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

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(recipeByIdStreamProvider(widget.recipeId));

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
              // Main scrollable content
              CustomScrollView(
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
          // Edit button
          AppCircleButton(
            icon: AppCircleButtonIcon.pencil,
            variant: AppCircleButtonVariant.neutral,
            size: 40,
            onPressed: () {
              // TODO: Implement edit functionality
            },
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


