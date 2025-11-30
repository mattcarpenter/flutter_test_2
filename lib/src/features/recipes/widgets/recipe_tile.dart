import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../../../database/database.dart';
import '../../../../database/models/recipe_images.dart';
import '../../../widgets/local_or_network_image.dart';
import '../../../widgets/recipe_placeholder_image.dart';
import '../../../theme/colors.dart';
import '../../../utils/duration_formatter.dart';
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

        // Constants for spacing and text area height
        const double spacingAboveName = 8.0;
        const double spacingBetweenNameAndDetails = 4.0;
        const double bottomSpacing = 8.0;

        // Reserve fixed space for text content (2 lines title + 1 line subtitle + spacing)
        const double reservedTextHeight = 80.0;

        // Format time display
        String timeDisplay = '';
        if (widget.recipe.totalTime != null) {
          timeDisplay = DurationFormatter.formatMinutes(widget.recipe.totalTime!);
        } else if (widget.recipe.prepTime != null && widget.recipe.cookTime != null) {
          final totalTime = (widget.recipe.prepTime ?? 0) + (widget.recipe.cookTime ?? 0);
          if (totalTime > 0) {
            timeDisplay = DurationFormatter.formatMinutes(totalTime);
          }
        } else if (widget.recipe.prepTime != null && widget.recipe.prepTime! > 0) {
          timeDisplay = DurationFormatter.formatMinutes(widget.recipe.prepTime!);
        } else if (widget.recipe.cookTime != null && widget.recipe.cookTime! > 0) {
          timeDisplay = DurationFormatter.formatMinutes(widget.recipe.cookTime!);
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
            color: AppColors.of(context).scaffoldBackground,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image takes up calculated space, leaving room for text
              Container(
                height: tileHeight - reservedTextHeight,
                width: double.infinity,
                child: FutureBuilder<String>(
                  future: coverImage?.getFullPath() ?? Future.value(''),
                  builder: (context, snapshot) {
                    final coverImageFilePath = snapshot.data ?? '';
                    
                    // Check if we have an image to display
                    final hasImage = coverImageFilePath.isNotEmpty || coverImageUrl.isNotEmpty;
                    
                    // Apply racetrack-style rounding to the image or placeholder
                    return ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.elliptical(10, 10),      
                        topRight: Radius.elliptical(10, 10),     
                        bottomLeft: Radius.elliptical(10, 10),   
                        bottomRight: Radius.elliptical(10, 10),  
                      ),
                      child: hasImage
                          ? LocalOrNetworkImage(
                              filePath: coverImageFilePath,
                              url: coverImageUrl,
                              height: double.infinity,  // Fill container space
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : RecipePlaceholderImage(
                              height: double.infinity,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    );
                  },
                ),
              ),
              const SizedBox(height: spacingAboveName),
              // Recipe name - dynamic height (1-2 lines)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.recipe.title,
                  maxLines: 2,  // Allow wrapping to 2 lines
                  overflow: TextOverflow.ellipsis,  // Ellipsis at end of 2nd line
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.of(context).textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: spacingBetweenNameAndDetails),
              // Subtitle with time and servings - positioned right under title
              if (subtitleText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    subtitleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.of(context).textSecondary,
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
