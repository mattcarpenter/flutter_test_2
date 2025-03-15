import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../../../database/models/recipe_images.dart';

class ImagePickerSection extends StatefulWidget {
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

class _ImagePickerSectionState extends State<ImagePickerSection> {
  final ImagePicker _picker = ImagePicker();

  /// Opens a platform-adaptive picker for Camera/Gallery
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

  /// Handles picking an image from Camera/Gallery
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return; // User canceled

    final String savedFileName = await _saveImageLocally(File(image.path));

    final newImage = RecipeImage(
      id: const Uuid().v4(),
      fileName: savedFileName, // Only store filename
      uploadStatus: 'pending',
    );

    setState(() {
      widget.onImagesUpdated([...widget.images, newImage]);
    });
  }

  /// Saves image to local storage and stores only the filename
  Future<String> _saveImageLocally(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final String newFileName = '${const Uuid().v4()}.jpg';
    final String newPath = '${directory.path}/$newFileName';

    await imageFile.copy(newPath);

    // Save filename (not full path) in shared preferences
    final prefs = await SharedPreferences.getInstance();
    List<String> storedFiles = prefs.getStringList('local_images') ?? [];
    storedFiles.add(newFileName);
    await prefs.setStringList('local_images', storedFiles);

    return newFileName; // Return only the filename
  }

  /// Shows a confirmation prompt before deleting an image
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

  /// Deletes an image from local storage and updates the list
  void _deleteImage(int index) async {
    final recipeImage = widget.images[index];
    final fullPath = await recipeImage.getFullPath();

    // Delete file from storage
    final file = File(fullPath);
    if (await file.exists()) {
      await file.delete();
    }

    // Remove from list and update UI
    setState(() {
      final updatedImages = List<RecipeImage>.from(widget.images);
      updatedImages.removeAt(index);
      widget.onImagesUpdated(updatedImages);
    });

    // Also remove from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final storedFiles = prefs.getStringList('local_images') ?? [];
    storedFiles.remove(recipeImage.fileName);
    await prefs.setStringList('local_images', storedFiles);
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

        // Horizontally scrolling list of images
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
                    return const SizedBox(width: 80, height: 80, child: Center(child: CircularProgressIndicator()));
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
                            child: const Icon(Icons.close, size: 18, color: Colors.white),
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

        // Add Photo Button
        ElevatedButton.icon(
          onPressed: () => _showImagePickerDialog(context),
          icon: const Icon(Icons.add_a_photo),
          label: const Text("Add Photo"),
        ),
      ],
    );
  }
}
