import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../../../database/database.dart';
import '../../../../database/models/recipe_images.dart';
import '../../../widgets/local_or_network_image.dart';
import '../views/add_recipe_modal.dart';

class RecipeTile extends StatefulWidget {
  final RecipeEntry recipe;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const RecipeTile({
    Key? key,
    required this.recipe,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  _RecipeTileState createState() => _RecipeTileState();
}

class _RecipeTileState extends State<RecipeTile> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutExpo,
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(curve);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(curve);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onDelete != null) {
        widget.onDelete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startDeletionAnimation() {
    if (!_isDeleting) {
      setState(() {
        _isDeleting = true;
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: ContextMenuWidget(
            menuProvider: (_) {
              return Menu(
                children: [
                  // menu action for editing:
                  MenuAction(
                    title: 'Edit Recipe',
                    image: MenuImage.icon(Icons.edit),
                    callback: () {
                      // Show the recipe editor modal
                      Future.delayed(const Duration(milliseconds: 250), () {
                        if (mounted) {
                          showRecipeEditorModal(context, recipe: widget.recipe, isEditing: true);
                        }
                      });
                    },
                  ),
                  MenuAction(
                    title: 'Delete Recipe',
                    image: MenuImage.icon(Icons.delete),
                    attributes: const MenuActionAttributes(destructive: true),
                    callback: _startDeletionAnimation,
                  ),
                ],
              );
            },
            child: _buildRecipeContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = constraints.maxWidth;
        final tileHeight = constraints.maxHeight;

        // Constants for spacing and text height
        const double spacingAboveName = 8.0;
        const double recipeNameHeight = 20.0;
        const double spacingBetweenNameAndDetails = 4.0;
        const double subtitleHeight = 16.0;
        const double bottomSpacing = 8.0;

        // Calculate fixed content height
        final fixedContentHeight = spacingAboveName + recipeNameHeight +
                                  spacingBetweenNameAndDetails + subtitleHeight + bottomSpacing;

        // Compute the dynamic image height
        final imageHeight = tileHeight - fixedContentHeight;

        // Format time display
        String timeDisplay = '';
        if (widget.recipe.totalTime != null) {
          timeDisplay = '${widget.recipe.totalTime} min';
        } else if (widget.recipe.prepTime != null && widget.recipe.cookTime != null) {
          final totalTime = (widget.recipe.prepTime ?? 0) + (widget.recipe.cookTime ?? 0);
          if (totalTime > 0) {
            timeDisplay = '$totalTime min';
          }
        } else if (widget.recipe.prepTime != null && widget.recipe.prepTime! > 0) {
          timeDisplay = '${widget.recipe.prepTime} min';
        } else if (widget.recipe.cookTime != null && widget.recipe.cookTime! > 0) {
          timeDisplay = '${widget.recipe.cookTime} min';
        }

        // Format servings display
        String servingsDisplay = '';
        if (widget.recipe.servings != null && widget.recipe.servings! > 0) {
          servingsDisplay = '${widget.recipe.servings} serving${widget.recipe.servings! > 1 ? 's' : ''}';
        }

        // Combine time and servings with bullet separator
        String subtitleText = '';
        if (timeDisplay.isNotEmpty && servingsDisplay.isNotEmpty) {
          subtitleText = '$timeDisplay • $servingsDisplay';
        } else if (timeDisplay.isNotEmpty) {
          subtitleText = timeDisplay;
        } else if (servingsDisplay.isNotEmpty) {
          subtitleText = servingsDisplay;
        }

        // Get the cover image
        final coverImage = RecipeImage.getCoverImage(widget.recipe.images);
        final coverImageUrl = coverImage?.getPublicUrlForSize(RecipeImageSize.small) ?? '';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Use FutureBuilder to wait for the file path
              FutureBuilder<String>(
                future: coverImage?.getFullPath() ?? Future.value(''),
                builder: (context, snapshot) {
                  final coverImageFilePath = snapshot.data ?? '';
                  // Apply racetrack-style rounding to the image
                  // Top: sharper sides (x=6), gentler top curve (y=12)
                  // Bottom: gentler sides (x=12), sharper bottom curve (y=6) - inverted for racetrack
                  return ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.elliptical(10, 10),      // x=6 (sharper), y=12 (gentler)
                      topRight: Radius.elliptical(10, 10),     // x=6 (sharper), y=12 (gentler)
                      bottomLeft: Radius.elliptical(10, 10),   // x=12 (gentler), y=6 (sharper) - inverted
                      bottomRight: Radius.elliptical(10, 10),  // x=12 (gentler), y=6 (sharper) - inverted
                    ),
                    child: LocalOrNetworkImage(
                      filePath: coverImageFilePath,
                      url: coverImageUrl,
                      height: imageHeight,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
              const SizedBox(height: spacingAboveName),
              // Recipe name (fixed height)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  height: recipeNameHeight,
                  child: Text(
                    widget.recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              const SizedBox(height: spacingBetweenNameAndDetails),
              // Subtitle with time and servings
              if (subtitleText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    subtitleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              const SizedBox(height: bottomSpacing),
            ],
          ),
        );
      },
    );
  }

}
