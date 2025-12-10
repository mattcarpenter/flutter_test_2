import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../database/database.dart';
import '../../../../database/models/ingredient_terms.dart';
import '../../../../database/models/ingredients.dart';
import '../../../../database/models/recipe_images.dart';
import '../../../../database/models/steps.dart';
import '../../../managers/upload_queue_manager.dart';
import '../../../repositories/recipe_repository.dart';
import '../../../repositories/recipe_tag_repository.dart';
import '../../../repositories/recipe_folder_repository.dart';
import '../../../services/logging/app_logger.dart';
import '../models/export_recipe.dart';

/// Source of the import
enum ImportSource {
  stockpot,
  paprika,
  crouton,
}

/// Represents a recipe ready for import with resolved dependencies
class ImportedRecipe {
  final ExportRecipe recipe;
  final List<String> tagNames;
  final List<String> folderNames;
  final List<ImageData> images;

  ImportedRecipe({
    required this.recipe,
    required this.tagNames,
    required this.folderNames,
    required this.images,
  });
}

/// Image data to be saved during import
class ImageData {
  final String base64Data;
  final bool isCover;
  final String? publicUrl;

  ImageData({
    required this.base64Data,
    required this.isCover,
    this.publicUrl,
  });
}

/// Preview data shown before import
class ImportPreview {
  final int recipeCount;
  final List<String> tagNames;
  final List<String> folderNames;
  final List<String> existingTagNames;
  final List<String> newTagNames;
  final List<String> existingFolderNames;
  final List<String> newFolderNames;
  final List<ImportedRecipe> recipes;
  final bool hasPaprikaCategories;

  ImportPreview({
    required this.recipeCount,
    required this.tagNames,
    required this.folderNames,
    required this.existingTagNames,
    required this.newTagNames,
    required this.existingFolderNames,
    required this.newFolderNames,
    required this.recipes,
    this.hasPaprikaCategories = false,
  });
}

/// Result after import completes
class ImportResult {
  final int successCount;
  final int failureCount;
  final List<String> errors;

  ImportResult({
    required this.successCount,
    required this.failureCount,
    required this.errors,
  });
}

/// Service for importing recipes from various formats
class ImportService {
  final RecipeRepository _recipeRepository;
  final RecipeTagRepository _tagRepository;
  final RecipeFolderRepository _folderRepository;

  ImportService({
    required RecipeRepository recipeRepository,
    required RecipeTagRepository tagRepository,
    required RecipeFolderRepository folderRepository,
  })  : _recipeRepository = recipeRepository,
        _tagRepository = tagRepository,
        _folderRepository = folderRepository;

  /// Preview import without saving (returns parsed data for confirmation screen)
  Future<ImportPreview> previewImport({
    required List<ExportRecipe> recipes,
    required ImportSource source,
  }) async {
    AppLogger.info('Previewing import of ${recipes.length} recipes from $source');

    // Convert ExportRecipe to ImportedRecipe
    final importedRecipes = <ImportedRecipe>[];
    for (final recipe in recipes) {
      final imported = await _convertToImportedRecipe(recipe);
      importedRecipes.add(imported);
    }

    // Collect unique tag and folder names
    final allTagNames = <String>{};
    final allFolderNames = <String>{};

    for (final imported in importedRecipes) {
      allTagNames.addAll(imported.tagNames);
      allFolderNames.addAll(imported.folderNames);
    }

    // Get existing tags and folders to determine which are new
    final existingTags = await _tagRepository.watchTags().first;
    final existingFolders = await _folderRepository.watchFolders().first;

    final existingTagNames = existingTags.map((t) => t.name.toLowerCase()).toSet();
    final existingFolderNames = existingFolders.map((f) => f.name.toLowerCase()).toSet();

    final newTagNames = allTagNames.where((name) => !existingTagNames.contains(name.toLowerCase())).toList();
    final newFolderNames = allFolderNames.where((name) => !existingFolderNames.contains(name.toLowerCase())).toList();

    final existingTagNamesList = allTagNames.where((name) => existingTagNames.contains(name.toLowerCase())).toList();
    final existingFolderNamesList = allFolderNames.where((name) => existingFolderNames.contains(name.toLowerCase())).toList();

    // Check if this is a Paprika import with categories
    final hasPaprikaCategories = source == ImportSource.paprika && allTagNames.isNotEmpty;

    return ImportPreview(
      recipeCount: recipes.length,
      tagNames: allTagNames.toList(),
      folderNames: allFolderNames.toList(),
      existingTagNames: existingTagNamesList,
      newTagNames: newTagNames,
      existingFolderNames: existingFolderNamesList,
      newFolderNames: newFolderNames,
      recipes: importedRecipes,
      hasPaprikaCategories: hasPaprikaCategories,
    );
  }

  /// Execute import after user confirmation
  Future<ImportResult> executeImport({
    required List<ImportedRecipe> recipes,
    required Map<String, String> tagNameToId,
    required Map<String, String> folderNameToId,
    String? userId,
    String? householdId,
    UploadQueueManager? uploadQueueManager,
    void Function(int current, int total)? onProgress,
  }) async {
    AppLogger.info('Starting import of ${recipes.length} recipes');

    int successCount = 0;
    int failureCount = 0;
    final errors = <String>[];

    for (int i = 0; i < recipes.length; i++) {
      try {
        final importedRecipe = recipes[i];
        await _importSingleRecipe(
          importedRecipe,
          tagNameToId,
          folderNameToId,
          userId: userId,
          householdId: householdId,
          uploadQueueManager: uploadQueueManager,
        );
        successCount++;
        AppLogger.debug('Successfully imported: ${importedRecipe.recipe.title}');
      } catch (e, stackTrace) {
        failureCount++;
        final errorMsg = 'Failed to import "${recipes[i].recipe.title}": $e';
        errors.add(errorMsg);
        AppLogger.error(errorMsg, e, stackTrace);
      }

      onProgress?.call(i + 1, recipes.length);
    }

    AppLogger.info('Import complete: $successCount succeeded, $failureCount failed');
    return ImportResult(
      successCount: successCount,
      failureCount: failureCount,
      errors: errors,
    );
  }

  /// Convert ExportRecipe to ImportedRecipe
  Future<ImportedRecipe> _convertToImportedRecipe(ExportRecipe recipe) async {
    final tagNames = recipe.tagNames ?? [];
    final folderNames = recipe.folderNames ?? [];

    // Process images
    final images = <ImageData>[];
    if (recipe.images != null) {
      for (final img in recipe.images!) {
        // If we have base64 data or public URL, add it
        if (img.data != null || img.publicUrl != null) {
          images.add(ImageData(
            base64Data: img.data ?? '',
            isCover: img.isCover ?? false,
            publicUrl: img.publicUrl,
          ));
        }
      }
    }

    return ImportedRecipe(
      recipe: recipe,
      tagNames: tagNames,
      folderNames: folderNames,
      images: images,
    );
  }

  /// Import a single recipe into the database
  Future<void> _importSingleRecipe(
    ImportedRecipe importedRecipe,
    Map<String, String> tagNameToId,
    Map<String, String> folderNameToId, {
    String? userId,
    String? householdId,
    UploadQueueManager? uploadQueueManager,
  }) async {
    final recipe = importedRecipe.recipe;
    final newRecipeId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Convert tag names to IDs
    final tagIds = importedRecipe.tagNames
        .map((name) => tagNameToId[name.toLowerCase()])
        .where((id) => id != null)
        .cast<String>()
        .toList();

    // Convert folder names to IDs
    final folderIds = importedRecipe.folderNames
        .map((name) => folderNameToId[name.toLowerCase()])
        .where((id) => id != null)
        .cast<String>()
        .toList();

    // Convert ExportIngredients to Ingredients with new IDs
    final ingredients = recipe.ingredients?.map((exportIng) {
      return Ingredient(
        id: const Uuid().v4(),
        type: exportIng.type,
        name: exportIng.name,
        note: exportIng.note,
        terms: exportIng.terms?.map((term) {
          return IngredientTerm(
            value: term.value,
            source: term.source,
            sort: term.sort,
          );
        }).toList(),
        isCanonicalised: exportIng.isCanonicalised ?? false,
        category: exportIng.category,
      );
    }).toList();

    // Convert ExportSteps to Steps with new IDs
    final steps = recipe.steps?.map((exportStep) {
      return Step(
        id: const Uuid().v4(),
        type: exportStep.type,
        text: exportStep.text,
        note: exportStep.note,
        timerDurationSeconds: exportStep.timerDurationSeconds,
      );
    }).toList();

    // Handle images
    final recipeImages = await _processImages(newRecipeId, importedRecipe.images);

    // Create the recipe entry
    final recipeEntry = RecipesCompanion(
      id: Value(newRecipeId),
      title: Value(recipe.title),
      description: Value(recipe.description),
      rating: Value(recipe.rating),
      language: Value(recipe.language),
      servings: Value(recipe.servings),
      prepTime: Value(recipe.prepTime),
      cookTime: Value(recipe.cookTime),
      totalTime: Value(recipe.totalTime),
      source: Value(recipe.source),
      nutrition: Value(recipe.nutrition),
      generalNotes: Value(recipe.generalNotes),
      createdAt: Value(recipe.createdAt ?? now),
      updatedAt: Value(recipe.updatedAt ?? now),
      pinned: Value(recipe.pinned == true ? 1 : 0),
      ingredients: Value(ingredients),
      steps: Value(steps),
      tagIds: Value(tagIds),
      folderIds: Value(folderIds),
      images: Value(recipeImages),
      userId: Value(userId),
      householdId: Value(householdId),
    );

    await _recipeRepository.addRecipe(recipeEntry);

    // Queue images for upload if user is authenticated and upload manager is provided
    if (uploadQueueManager != null && userId != null) {
      for (final image in recipeImages) {
        if (image.publicUrl == null) {
          await uploadQueueManager.addToQueue(
            fileName: image.fileName,
            recipeId: newRecipeId,
          );
          AppLogger.debug('Queued image for upload: ${image.fileName}');
        }
      }
    }
  }

  /// Process and save images, returning list of RecipeImage objects
  /// Creates both large (1280px) and small (512px) versions for each image
  Future<List<RecipeImage>> _processImages(String recipeId, List<ImageData> imageDataList) async {
    final recipeImages = <RecipeImage>[];

    for (int i = 0; i < imageDataList.length; i++) {
      final imageData = imageDataList[i];
      final imageId = const Uuid().v4();

      // If we have a public URL and no base64 data, we can just reference the URL
      if (imageData.publicUrl != null && imageData.publicUrl!.isNotEmpty) {
        // Extract filename from URL or generate one
        final uri = Uri.parse(imageData.publicUrl!);
        final filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'image_$i.jpg';

        recipeImages.add(RecipeImage(
          id: imageId,
          fileName: filename,
          publicUrl: imageData.publicUrl,
          isCover: imageData.isCover,
        ));
      } else if (imageData.base64Data.isNotEmpty) {
        // We have base64 data, need to decode, compress, and save locally
        try {
          final bytes = _base64ToBytes(imageData.base64Data);

          // Generate filenames for both sizes
          final baseFilename = '${recipeId}_$i';
          final fullFilename = '$baseFilename.jpg';
          final smallFilename = '${baseFilename}_small.jpg';

          // Save raw bytes to a temp file for compression
          final tempDir = await getTemporaryDirectory();
          final tempFile = File(p.join(tempDir.path, 'import_temp_$i.jpg'));
          await tempFile.writeAsBytes(bytes);

          // Compress to both sizes and save to documents directory
          final documentsDir = await getApplicationDocumentsDirectory();

          // Create large version (1280px)
          final largeFile = await _compressImage(
            tempFile,
            p.join(documentsDir.path, fullFilename),
            size: 1280,
          );

          // Create small version (512px)
          final smallFile = await _compressImage(
            tempFile,
            p.join(documentsDir.path, smallFilename),
            size: 512,
          );

          // Clean up temp file
          try {
            await tempFile.delete();
          } catch (_) {
            // Ignore temp file cleanup errors
          }

          if (largeFile != null && smallFile != null) {
            recipeImages.add(RecipeImage(
              id: imageId,
              fileName: fullFilename,
              isCover: imageData.isCover,
            ));
            AppLogger.debug('Saved compressed images: $fullFilename and $smallFilename');
          } else {
            // Fallback: save raw bytes if compression fails
            final fallbackPath = p.join(documentsDir.path, fullFilename);
            await File(fallbackPath).writeAsBytes(bytes);

            // Also save as small (same file, no compression)
            final smallFallbackPath = p.join(documentsDir.path, smallFilename);
            await File(smallFallbackPath).writeAsBytes(bytes);

            recipeImages.add(RecipeImage(
              id: imageId,
              fileName: fullFilename,
              isCover: imageData.isCover,
            ));
            AppLogger.warning('Compression failed, saved raw images for recipe $recipeId');
          }
        } catch (e, stackTrace) {
          AppLogger.error('Failed to save image $i for recipe $recipeId', e, stackTrace);
          // Continue with other images even if one fails
        }
      }
    }

    return recipeImages;
  }

  /// Compress an image to the specified size
  Future<File?> _compressImage(File sourceFile, String targetPath, {required int size}) async {
    try {
      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        sourceFile.absolute.path,
        targetPath,
        quality: 90,
        minWidth: size,
        minHeight: size,
        format: CompressFormat.jpeg,
      );

      if (compressedXFile == null) {
        return null;
      }
      return File(compressedXFile.path);
    } catch (e) {
      AppLogger.error('Image compression failed', e);
      return null;
    }
  }

  /// Decode base64 string to bytes
  List<int> _base64ToBytes(String base64String) {
    // Remove data URL prefix if present (e.g., "data:image/jpeg;base64,")
    String cleanBase64 = base64String;
    if (base64String.contains(',')) {
      cleanBase64 = base64String.split(',').last;
    }

    return base64Decode(cleanBase64);
  }

  /// Create tags from a list of names, returning a map of name -> ID
  Future<Map<String, String>> createTagsFromNames(
    List<String> tagNames, {
    String? userId,
  }) async {
    AppLogger.info('Creating ${tagNames.length} tags');
    final tagNameToId = <String, String>{};

    // Get existing tags
    final existingTags = await _tagRepository.watchTags().first;
    final existingTagMap = <String, RecipeTagEntry>{};
    for (final tag in existingTags) {
      existingTagMap[tag.name.toLowerCase()] = tag;
    }

    // Create or reuse tags
    for (final name in tagNames) {
      final lowerName = name.toLowerCase();
      if (existingTagMap.containsKey(lowerName)) {
        // Tag already exists, use its ID
        tagNameToId[lowerName] = existingTagMap[lowerName]!.id;
        AppLogger.debug('Reusing existing tag: $name');
      } else {
        // Create new tag with default color
        final newTag = await _tagRepository.addTag(
          name: name,
          color: '#4285F4', // Default blue color
          userId: userId,
        );
        tagNameToId[lowerName] = newTag.id;
        AppLogger.debug('Created new tag: $name');
      }
    }

    return tagNameToId;
  }

  /// Create folders from a list of names, returning a map of name -> ID
  Future<Map<String, String>> createFoldersFromNames(
    List<String> folderNames, {
    String? userId,
    String? householdId,
  }) async {
    AppLogger.info('Creating ${folderNames.length} folders');
    final folderNameToId = <String, String>{};

    // Get existing folders
    final existingFolders = await _folderRepository.watchFolders().first;
    final existingFolderMap = <String, RecipeFolderEntry>{};
    for (final folder in existingFolders) {
      existingFolderMap[folder.name.toLowerCase()] = folder;
    }

    // Create or reuse folders
    for (final name in folderNames) {
      final lowerName = name.toLowerCase();
      if (existingFolderMap.containsKey(lowerName)) {
        // Folder already exists, use its ID
        folderNameToId[lowerName] = existingFolderMap[lowerName]!.id;
        AppLogger.debug('Reusing existing folder: $name');
      } else {
        // Create new folder
        final newFolder = await _folderRepository.addFolder(
          name: name,
          userId: userId,
          householdId: householdId,
        );
        folderNameToId[lowerName] = newFolder.id;
        AppLogger.debug('Created new folder: $name');
      }
    }

    return folderNameToId;
  }
}
