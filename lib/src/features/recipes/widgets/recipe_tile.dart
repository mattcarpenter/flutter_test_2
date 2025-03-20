import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../../../database/database.dart';
import '../../../../database/models/recipe_images.dart';
import '../../../widgets/local_or_network_image.dart';

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
        const double bottomSpacing = 8.0;
        const double detailsHeightSingleRow = 28.0;
        const double detailsHeightDoubleRow = 48.0;

        // Check if we have enough space for the time & difficulty on one row
        final isWideEnoughForOneRow = tileWidth > 140;

        // Determine actual content height based on layout
        final detailsHeight = isWideEnoughForOneRow ? detailsHeightSingleRow : detailsHeightDoubleRow;
        final fixedContentHeight = spacingAboveName + recipeNameHeight + spacingBetweenNameAndDetails + detailsHeight + bottomSpacing;

        // Compute the dynamic image height
        final imageHeight = tileHeight - fixedContentHeight;

        // Format time display
        String timeDisplay = 'N/A';
        if (widget.recipe.totalTime != null) {
          timeDisplay = '${widget.recipe.totalTime} mins';
        } else if (widget.recipe.prepTime != null && widget.recipe.cookTime != null) {
          timeDisplay = '${(widget.recipe.prepTime ?? 0) + (widget.recipe.cookTime ?? 0)} mins';
        } else if (widget.recipe.prepTime != null) {
          timeDisplay = '${widget.recipe.prepTime} mins';
        } else if (widget.recipe.cookTime != null) {
          timeDisplay = '${widget.recipe.cookTime} mins';
        }

        // Determine difficulty
        String difficulty = 'Medium';
        if (widget.recipe.rating != null) {
          if (widget.recipe.rating! <= 2) difficulty = 'Easy';
          else if (widget.recipe.rating! >= 4) difficulty = 'Hard';
        }

        // Get the cover image
        final coverImage = RecipeImage.getCoverImage(widget.recipe.images);
        final coverImageUrl = coverImage?.getPublicUrlForSize(RecipeImageSize.small) ?? '';

        return Container(
          // Add a solid background color to fix the transparency issue
          decoration: BoxDecoration(
            color: Colors.white, // Add background color to ensure opacity
            border: Border.all(color: Colors.grey.shade300, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Use FutureBuilder to wait for the file path
              FutureBuilder<String>(
                future: coverImage?.getFullPath() ?? Future.value(''),
                builder: (context, snapshot) {
                  final coverImageFilePath = snapshot.data ?? '';
                  return LocalOrNetworkImage(
                    filePath: coverImageFilePath,
                    url: coverImageUrl,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
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
              // Details area (time + difficulty chip)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: isWideEnoughForOneRow
                    ? _buildSingleRowDetails(context, timeDisplay, difficulty)
                    : _buildDoubleRowDetails(context, timeDisplay, difficulty),
              ),
              const SizedBox(height: bottomSpacing),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSingleRowDetails(BuildContext context, String timeDisplay, String difficulty) {
    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(timeDisplay, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(difficulty, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }

  Widget _buildDoubleRowDetails(BuildContext context, String timeDisplay, String difficulty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(timeDisplay, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(difficulty, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
