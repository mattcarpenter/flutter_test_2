import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nanoid/nanoid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../database/models/recipe_images.dart';
import 'package:recipe_app/src/managers/upload_queue_manager.dart';

import '../../../../../widgets/local_or_network_image.dart'; // import your manager file

/// Represents the state of an image in the picker, tracking whether it's fresh or persisted
class ImageState {
  final RecipeImage recipeImage;
  final File? cachedFile;  // For fresh images, we cache the File to skip async operations
  final bool isFresh;      // Whether this image was just picked vs loaded from database
  
  const ImageState({
    required this.recipeImage,
    this.cachedFile,
    this.isFresh = false,
  });
  
  /// Create a fresh image state with cached file info
  ImageState.fresh({
    required this.recipeImage,
    required this.cachedFile,
  }) : isFresh = true;
  
  /// Create a persisted image state (from database)
  ImageState.persisted({
    required this.recipeImage,
  }) : cachedFile = null, isFresh = false;
  
  /// Convert to persisted state (after saving to database)
  ImageState toPersisted() {
    return ImageState.persisted(recipeImage: recipeImage);
  }
}

class ImagePickerSection extends ConsumerStatefulWidget {
  final List<RecipeImage> images;
  final Function(List<RecipeImage>) onImagesUpdated;

  const ImagePickerSection({
    Key? key,
    required this.images,
    required this.onImagesUpdated,
  }) : super(key: key);

  @override
  _ImagePickerSectionState createState() => _ImagePickerSectionState();
}

class _ImagePickerSectionState extends ConsumerState<ImagePickerSection> {
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<ImageState> _imageStates = [];

  @override
  void initState() {
    super.initState();
    _syncImageStates();
  }

  @override
  void didUpdateWidget(ImagePickerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images != widget.images) {
      _syncImageStates();
    }
  }

  @override
  void dispose() {
    // Clear any cached file references to prevent memory leaks
    _imageStates.clear();
    super.dispose();
  }

  /// Synchronizes the internal _imageStates with the external widget.images
  /// Preserves fresh state for images that haven't changed
  void _syncImageStates() {
    final newStates = <ImageState>[];
    final oldStates = List<ImageState>.from(_imageStates);
    
    for (final image in widget.images) {
      // Try to find existing state to preserve fresh status and cached files
      final existingState = oldStates.firstWhere(
        (state) => state.recipeImage.fileName == image.fileName,
        orElse: () => ImageState.persisted(recipeImage: image),
      );
      
      // Update the recipe image but preserve the state info
      newStates.add(ImageState(
        recipeImage: image,
        cachedFile: existingState.cachedFile,
        isFresh: existingState.isFresh,
      ));
    }
    
    // For external updates (not from our own _pickImage/_deleteImage), 
    // we need to handle AnimatedList state changes
    if (mounted && _listKey.currentState != null) {
      // Handle removals (items in old but not in new)
      for (int i = oldStates.length - 1; i >= 0; i--) {
        final oldState = oldStates[i];
        if (!newStates.any((s) => s.recipeImage.fileName == oldState.recipeImage.fileName)) {
          _listKey.currentState!.removeItem(
            i,
            (context, animation) => _buildAnimatedThumbnail(oldState, i, animation),
            duration: const Duration(milliseconds: 300),
          );
        }
      }
      
      // Handle additions (items in new but not in old)
      for (int i = 0; i < newStates.length; i++) {
        final newState = newStates[i];
        if (!oldStates.any((s) => s.recipeImage.fileName == newState.recipeImage.fileName)) {
          _listKey.currentState!.insertItem(
            i,
            duration: const Duration(milliseconds: 300),
          );
        }
      }
    }
    
    setState(() {
      _imageStates = newStates;
    });
  }

  /// Converts internal _imageStates to List<RecipeImage> for the callback
  List<RecipeImage> _getRecipeImages() {
    return _imageStates.map((state) => state.recipeImage).toList();
  }

  Future<void> _showImagePickerDialog(BuildContext context) async {
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              child: const Text("Take Photo"),
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            CupertinoActionSheetAction(
              child: const Text("Choose from Gallery"),
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (context) => Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take Photo"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    final uuid = const Uuid().v4();
    final fullFileName = '${uuid}.jpg';
    final smallFileName = '${uuid}_small.jpg';

    final File compressedImage = await _compressImage(File(image.path), fullFileName);
    final File compressedImageSmall = await _compressImage(File(image.path), smallFileName, size: 512);

    final String savedFileName = await _saveImageLocally(compressedImage, fullFileName);
    await _saveImageLocally(compressedImageSmall, smallFileName);

    final newImage = RecipeImage(
      id: nanoid(10),
      fileName: savedFileName,
    );

    // Create fresh image state with cached file info for immediate rendering
    final newImageState = ImageState.fresh(
      recipeImage: newImage,
      cachedFile: compressedImageSmall, // Use small version for thumbnails
    );

    // Update internal state and trigger animation
    setState(() {
      _imageStates.add(newImageState);
    });

    // Trigger animated list insertion
    _listKey.currentState?.insertItem(
      _imageStates.length - 1,
      duration: const Duration(milliseconds: 300),
    );

    // Update parent with new images list
    widget.onImagesUpdated(_getRecipeImages());
  }

  Future<File> _compressImage(File file, String fileName, {int size = 1280}) async {
    final directory = await getTemporaryDirectory();
    final String targetPath = '${directory.path}/${fileName}.jpg';

    final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 90,
      minWidth: size,
      minHeight: size,
      format: CompressFormat.jpeg,
    );

    if (compressedXFile == null) {
      return file;
    }
    return File(compressedXFile.path);
  }

  Future<String> _saveImageLocally(File imageFile, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final String newPath = '${directory.path}/$fileName';

    await imageFile.copy(newPath);
    return fileName;
  }

  Future<void> _confirmDeleteImage(int index) async {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text("Delete Image"),
          content: const Text("Are you sure you want to remove this image?"),
          actions: [
            CupertinoDialogAction(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text("Delete"),
              onPressed: () {
                Navigator.pop(context);
                _deleteImage(index);
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Delete Image"),
          content: const Text("Are you sure you want to remove this image?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.pop(context);
                _deleteImage(index);
              },
            ),
          ],
        ),
      );
    }
  }

  void _deleteImage(int index) async {
    final imageState = _imageStates[index];
    final recipeImage = imageState.recipeImage;
    
    // For fresh images, we can delete the cached file directly
    if (imageState.isFresh && imageState.cachedFile != null) {
      try {
        if (await imageState.cachedFile!.exists()) {
          await imageState.cachedFile!.delete();
        }
      } catch (e) {
        debugPrint('Error deleting cached file: $e');
      }
      
      // Also delete the full-size version
      try {
        final fullPath = await recipeImage.getFullPath();
        final file = File(fullPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting full-size file: $e');
      }
    } else {
      // For persisted images, use the original logic
      final fullPath = await recipeImage.getFullPath();
      final file = File(fullPath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // Remove filename from the upload queue.
    final uploadQueueManager = ref.read(uploadQueueManagerProvider);
    try {
      await uploadQueueManager.removeFromQueue(recipeImage.fileName);
    } catch (e) {
      debugPrint('Error removing image from upload queue: $e');
    }

    // Remove from internal state with animation
    final removedImageState = _imageStates[index];
    setState(() {
      _imageStates.removeAt(index);
    });

    // Trigger animated list removal
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildAnimatedThumbnail(removedImageState, index, animation),
      duration: const Duration(milliseconds: 300),
    );

    // Update parent with new images list
    widget.onImagesUpdated(_getRecipeImages());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Photos",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _imageStates.isEmpty
            ? const Text("No photos added")
            : SizedBox(
          height: 100,
          child: AnimatedList(
            key: _listKey,
            scrollDirection: Axis.horizontal,
            initialItemCount: _imageStates.length,
            itemBuilder: (context, index, animation) {
              return _buildAnimatedThumbnail(_imageStates[index], index, animation);
            },
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _showImagePickerDialog(context),
          icon: const Icon(Icons.add_a_photo),
          label: const Text("Add Photo"),
        ),
      ],
    );
  }

  /// Builds an animated thumbnail with smooth entry/exit animations
  Widget _buildAnimatedThumbnail(ImageState imageState, int index, Animation<double> animation) {
    // Use SizeTransition to smoothly allocate horizontal space
    return SizeTransition(
      sizeFactor: animation.drive(
        CurveTween(curve: Curves.easeOutCubic),
      ),
      axis: Axis.horizontal,
      child: Center(
        // Center ensures the scale animation happens from the true center
        child: ScaleTransition(
          scale: animation.drive(
            Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)),
          ),
          child: FadeTransition(
            opacity: animation.drive(
              Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
            ),
            child: _buildThumbnail(imageState, index),
          ),
        ),
      ),
    );
  }

  /// Builds a thumbnail with conditional rendering based on image state
  Widget _buildThumbnail(ImageState imageState, int index) {
    if (imageState.isFresh && imageState.cachedFile != null) {
      // Fresh image: Use cached file directly, no async operations needed
      return _buildFreshThumbnail(imageState.cachedFile!, index);
    } else {
      // Persisted image: Use existing async loading logic
      return _buildPersistedThumbnail(imageState.recipeImage, index);
    }
  }

  /// Builds a thumbnail for a fresh image using the cached file
  Widget _buildFreshThumbnail(File cachedFile, int index) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              cachedFile,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => _confirmDeleteImage(index),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.7),
              ),
              child: const Icon(Icons.close, size: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a thumbnail for a persisted image using the existing async logic
  Widget _buildPersistedThumbnail(RecipeImage recipeImage, int index) {
    final imageUrl = recipeImage.getPublicUrlForSize(RecipeImageSize.small) ?? '';
    
    return FutureBuilder<String>(
      future: recipeImage.getFullPath(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            width: 80,
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LocalOrNetworkImage(
                  filePath: snapshot.data ?? '',
                  url: imageUrl,
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: () => _confirmDeleteImage(index),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.7),
                  ),
                  child: const Icon(Icons.close, size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
