import 'package:flutter/material.dart';
import '../../../../../database/models/recipe_images.dart';
import '../../../../widgets/local_or_network_image.dart';
import '../pin_button.dart';

class RecipeImageGallery extends StatefulWidget {
  final List<RecipeImage> images;
  final String recipeId;

  const RecipeImageGallery({Key? key, required this.images, required this.recipeId}) : super(key: key);

  @override
  State<RecipeImageGallery> createState() => _RecipeImageGalleryState();
}

class _RecipeImageGalleryState extends State<RecipeImageGallery> {
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
    if (widget.images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main image
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildMainImage(),
          ),
        ),

        // Thumbnails (if more than one image)
        if (widget.images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
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
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    margin: const EdgeInsets.only(right: 8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedIndex == index
                            ? Theme.of(context).primaryColor
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
                            return const SizedBox(
                              width: 70,
                              height: 70,
                              child: Center(child: CircularProgressIndicator()),
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
          return const SizedBox(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            LocalOrNetworkImage(
              filePath: snapshot.data ?? '',
              url: imageUrl,
              fit: BoxFit.cover,
            ),
            // Pin button overlay
            Positioned(
              top: 12,
              right: 12,
              child: PinButton(recipeId: widget.recipeId),
            ),
          ],
        );
      },
    );
  }
}
