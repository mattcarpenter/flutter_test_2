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
import 'package:recipe_app/src/managers/upload_queue_manager.dart'; // import your manager file

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

    // Optionally, if you want to add this image to the upload queue immediately:
    final uploadQueueManager = ref.read(uploadQueueManagerProvider);
    // For example, if you need the recipe ID, pass it accordingly.
    // uploadQueueManager.addToQueue(fileName: savedFileName, recipeId: 'your_recipe_id');

    setState(() {
      widget.onImagesUpdated([...widget.images, newImage]);
    });
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
    final recipeImage = widget.images[index];
    final fullPath = await recipeImage.getFullPath();

    // Delete file from storage.
    final file = File(fullPath);
    if (await file.exists()) {
      await file.delete();
    }

    // Remove filename from the upload queue.
    final uploadQueueManager = ref.read(uploadQueueManagerProvider);
    try {
      await uploadQueueManager.removeFromQueue(recipeImage.fileName);
    } catch (e) {
      debugPrint('Error removing image from upload queue: $e');
    }

    // Update UI.
    setState(() {
      final updatedImages = List<RecipeImage>.from(widget.images);
      updatedImages.removeAt(index);
      widget.onImagesUpdated(updatedImages);
    });
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
        widget.images.isEmpty
            ? const Text("No photos added")
            : SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return FutureBuilder<String>(
                future: widget.images[index].getFullPath(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                        width: 80,
                        height: 80,
                        child: Center(child: CircularProgressIndicator()));
                  }
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(snapshot.data!),
                            width: 80,
                            height: 80,
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
                            child: const Icon(Icons.close,
                                size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
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
}
