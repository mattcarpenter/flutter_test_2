import 'package:flutter/material.dart';
import '../../../../../database/models/recipe_images.dart';
import '../../../../widgets/local_or_network_image.dart';
import '../pin_button.dart';

class RecipeHeroImage extends StatefulWidget {
  final List<RecipeImage> images;
  final String recipeId;
  final double pinButtonOpacity;

  const RecipeHeroImage({
    Key? key,
    required this.images,
    required this.recipeId,
    this.pinButtonOpacity = 1.0,
  }) : super(key: key);

  @override
  State<RecipeHeroImage> createState() => _RecipeHeroImageState();
}

class _RecipeHeroImageState extends State<RecipeHeroImage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Set the selected index to the cover image if it exists
    final coverImageIndex = widget.images.indexWhere((img) => img.isCover == true);
    if (coverImageIndex != -1) {
      _selectedIndex = coverImageIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.restaurant,
            size: 80,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Main hero image - edge to edge
        Positioned.fill(
          child: _buildMainImage(),
        ),

        // Pin button at bottom-right with fade animation
        Positioned(
          bottom: 16,
          right: 16,
          child: Opacity(
            opacity: widget.pinButtonOpacity,
            child: PinButton(recipeId: widget.recipeId),
          ),
        ),

        // Image indicator dots if multiple images
        if (widget.images.length > 1)
          Positioned(
            bottom: 60, // Above the pin button
            left: 0,
            right: 0,
            child: _buildImageIndicators(),
          ),
      ],
    );
  }

  Widget _buildMainImage() {
    final selectedImage = widget.images[_selectedIndex];
    final imageUrl = selectedImage.getPublicUrlForSize(RecipeImageSize.large) ??
        selectedImage.publicUrl ?? '';

    return FutureBuilder<String>(
      future: selectedImage.getFullPath(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        return GestureDetector(
          onTap: widget.images.length > 1 ? _showImageGallery : null,
          child: LocalOrNetworkImage(
            filePath: snapshot.data ?? '',
            url: imageUrl,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Widget _buildImageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.images.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _selectedIndex == index
                ? Colors.white
                : Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  void _showImageGallery() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildImageGalleryModal(),
    );
  }

  Widget _buildImageGalleryModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Image gallery
          Expanded(
            child: PageView.builder(
              itemCount: widget.images.length,
              controller: PageController(initialPage: _selectedIndex),
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final image = widget.images[index];
                final imageUrl = image.getPublicUrlForSize(RecipeImageSize.large) ??
                    image.publicUrl ?? '';

                return FutureBuilder<String>(
                  future: image.getFullPath(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return InteractiveViewer(
                      child: LocalOrNetworkImage(
                        filePath: snapshot.data ?? '',
                        url: imageUrl,
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Thumbnail strip
          Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                final image = widget.images[index];
                final imageUrl = image.getPublicUrlForSize(RecipeImageSize.small) ?? '';

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedIndex == index
                            ? Colors.white
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: FutureBuilder<String>(
                        future: image.getFullPath(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          return LocalOrNetworkImage(
                            filePath: snapshot.data ?? '',
                            url: imageUrl,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}