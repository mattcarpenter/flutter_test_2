import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nanoid/nanoid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../database/database.dart';
import '../../../../database/models/ingredients.dart';
import '../../../../database/models/recipe_images.dart';
import '../../../../database/models/steps.dart' as db;
import '../../../mobile/adaptive_app.dart' show globalRootNavigatorKey;
import '../../../providers/subscription_provider.dart';
import '../../../services/logging/app_logger.dart';
import '../../../services/photo_extraction_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../utils/image_utils.dart';
import '../../../widgets/app_circle_button.dart';
import '../../clippings/models/extracted_recipe.dart';
import '../../clippings/models/recipe_preview.dart';
import '../../clippings/providers/preview_usage_provider.dart';
import '../../share/widgets/share_recipe_preview_result.dart';
import 'add_recipe_modal.dart';

/// Shows a photo import flow to extract recipes from photos.
///
/// Entry point for in-app photo import (from "Choose Photo" or "Take Photo" menu items).
/// Handles image selection, processing, subscription checks, and extraction.
Future<void> showPhotoImportModal(
  BuildContext context, {
  required WidgetRef ref,
  required ImageSource source,
  String? folderId,
}) async {
  // Check connectivity first
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult.contains(ConnectivityResult.none)) {
    if (context.mounted) {
      _showError(context, 'You\'re offline. Please check your internet connection and try again.');
    }
    return;
  }

  // Pick image(s)
  final picker = ImagePicker();
  List<XFile> pickedImages = [];

  if (source == ImageSource.camera) {
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      pickedImages = [image];
    }
  } else {
    // Gallery - allow multiple selection (up to 2)
    pickedImages = await picker.pickMultiImage(limit: 2);
  }

  if (pickedImages.isEmpty) {
    return; // User cancelled
  }

  if (!context.mounted) return;

  // Show processing modal
  await _showProcessingModal(
    context,
    ref: ref,
    imagePaths: pickedImages.map((x) => x.path).toList(),
    folderId: folderId,
  );
}

/// Shows a simple error snackbar
void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

/// Shows the processing modal and handles extraction
Future<void> _showProcessingModal(
  BuildContext context, {
  required WidgetRef ref,
  required List<String> imagePaths,
  String? folderId,
}) async {
  await WoltModalSheet.show<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    modalTypeBuilder: (_) => WoltModalType.alertDialog(),
    pageListBuilder: (modalContext) => [
      WoltModalSheetPage(
        navBarHeight: 0,
        hasTopBarLayer: false,
        backgroundColor: AppColors.of(modalContext).background,
        surfaceTintColor: Colors.transparent,
        child: _PhotoImportContent(
          imagePaths: imagePaths,
          folderId: folderId,
          onClose: () => Navigator.of(modalContext, rootNavigator: true).pop(),
        ),
      ),
    ],
  );
}

/// Content widget for the photo import modal
class _PhotoImportContent extends ConsumerStatefulWidget {
  final List<String> imagePaths;
  final String? folderId;
  final VoidCallback onClose;

  const _PhotoImportContent({
    required this.imagePaths,
    required this.folderId,
    required this.onClose,
  });

  @override
  ConsumerState<_PhotoImportContent> createState() => _PhotoImportContentState();
}

enum _ModalState {
  processing,
  error,
  showingPreview,
}

class _PhotoImportContentState extends ConsumerState<_PhotoImportContent> {
  _ModalState _modalState = _ModalState.processing;
  String? _errorMessage;
  String _statusMessage = 'Reading photo...';

  @override
  void initState() {
    super.initState();
    _startExtraction();
  }

  Future<void> _startExtraction() async {
    try {
      // Check subscription status
      final hasPlus = ref.read(effectiveHasPlusProvider);

      if (hasPlus) {
        await _performFullExtraction();
      } else {
        // Check preview limit
        final usageService = await ref.read(previewUsageServiceProvider.future);

        if (!usageService.hasPhotoRecipePreviewsRemaining()) {
          // Limit exceeded - show paywall
          if (!mounted) return;
          widget.onClose();

          await Future.delayed(const Duration(milliseconds: 100));
          final rootContext = globalRootNavigatorKey.currentContext;
          if (rootContext != null && rootContext.mounted) {
            final purchased = await ref.read(subscriptionProvider.notifier).presentPaywall(rootContext);
            if (purchased && rootContext.mounted) {
              // Re-start extraction as Plus user
              await _showPostSubscriptionModal(rootContext);
            }
          }
          return;
        }

        // Show preview
        await _performPreviewExtraction();
      }
    } catch (e) {
      AppLogger.error('Photo import failed', e);
      if (mounted) {
        setState(() {
          _modalState = _ModalState.error;
          _errorMessage = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  Future<void> _performFullExtraction() async {
    try {
      setState(() {
        _statusMessage = 'Processing photo...';
      });

      // Prepare images
      final images = await ImageUtils.prepareImagesFromPaths(
        widget.imagePaths,
        maxImages: 2,
      );

      if (images.isEmpty) {
        setState(() {
          _modalState = _ModalState.error;
          _errorMessage = 'Failed to process the image(s). Please try again.';
        });
        return;
      }

      setState(() {
        _statusMessage = 'Extracting recipe...';
      });

      // Call extraction API
      final service = ref.read(photoExtractionServiceProvider);
      final recipe = await service.extractRecipe(images: images);

      if (!mounted) return;

      if (recipe == null) {
        setState(() {
          _modalState = _ModalState.error;
          _errorMessage = 'No recipe found in the photo.\n\nTry a photo of a recipe card or cookbook page.';
        });
        return;
      }

      // Save first image as cover
      RecipeImage? coverImage;
      if (widget.imagePaths.isNotEmpty) {
        coverImage = await _savePhotoAsCover(widget.imagePaths.first);
      }

      if (!mounted) return;

      // Success - close modal and open editor
      widget.onClose();

      final rootContext = globalRootNavigatorKey.currentContext;
      if (rootContext != null && rootContext.mounted) {
        final recipeEntry = _convertToRecipeEntry(recipe, coverImage: coverImage);
        showRecipeEditorModal(
          rootContext,
          ref: ref,
          recipe: recipeEntry,
          isEditing: false,
          folderId: widget.folderId,
        );
      }
    } on PhotoExtractionException catch (e) {
      if (mounted) {
        setState(() {
          _modalState = _ModalState.error;
          _errorMessage = e.message;
        });
      }
    }
  }

  Future<void> _performPreviewExtraction() async {
    try {
      setState(() {
        _statusMessage = 'Processing photo...';
      });

      // Prepare images
      final images = await ImageUtils.prepareImagesFromPaths(
        widget.imagePaths,
        maxImages: 2,
      );

      if (images.isEmpty) {
        setState(() {
          _modalState = _ModalState.error;
          _errorMessage = 'Failed to process the image(s). Please try again.';
        });
        return;
      }

      setState(() {
        _statusMessage = 'Extracting recipe...';
      });

      // Call preview API
      final service = ref.read(photoExtractionServiceProvider);
      final preview = await service.previewRecipe(images: images);

      if (!mounted) return;

      if (preview == null) {
        setState(() {
          _modalState = _ModalState.error;
          _errorMessage = 'No recipe found in the photo.\n\nTry a photo of a recipe card or cookbook page.';
        });
        return;
      }

      // Increment usage counter
      final usageService = await ref.read(previewUsageServiceProvider.future);
      await usageService.incrementPhotoRecipeUsage();

      // Close this modal and show preview sheet
      if (!mounted) return;
      widget.onClose();

      await Future.delayed(const Duration(milliseconds: 100));
      final rootContext = globalRootNavigatorKey.currentContext;
      if (rootContext != null && rootContext.mounted) {
        _showPreviewSheet(rootContext, preview);
      }
    } on PhotoExtractionException catch (e) {
      if (mounted) {
        setState(() {
          _modalState = _ModalState.error;
          _errorMessage = e.message;
        });
      }
    }
  }

  void _showPreviewSheet(BuildContext context, RecipePreview preview) {
    WoltModalSheet.show<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: false,
      pageListBuilder: (sheetContext) => [
        WoltModalSheetPage(
          navBarHeight: 55,
          backgroundColor: AppColors.of(sheetContext).background,
          surfaceTintColor: Colors.transparent,
          hasTopBarLayer: false,
          isTopBarLayerAlwaysVisible: false,
          trailingNavBarWidget: Padding(
            padding: EdgeInsets.only(right: AppSpacing.lg),
            child: AppCircleButton(
              icon: AppCircleButtonIcon.close,
              variant: AppCircleButtonVariant.neutral,
              size: 32,
              onPressed: () {
                Navigator.of(sheetContext, rootNavigator: true).pop();
              },
            ),
          ),
          child: ShareRecipePreviewResultContent(
            preview: preview,
            onSubscribe: () async {
              if (!context.mounted) return;

              final purchased = await ref
                  .read(subscriptionProvider.notifier)
                  .presentPaywall(context);

              if (purchased && context.mounted) {
                // Close preview sheet
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext, rootNavigator: true).pop();
                }

                // Perform full extraction
                await _showPostSubscriptionModal(context);
              }
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showPostSubscriptionModal(BuildContext context) async {
    var isExtracting = true;
    String? errorMessage;

    await WoltModalSheet.show<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      modalTypeBuilder: (_) => WoltModalType.alertDialog(),
      pageListBuilder: (modalContext) => [
        WoltModalSheetPage(
          navBarHeight: 0,
          hasTopBarLayer: false,
          backgroundColor: AppColors.of(modalContext).background,
          surfaceTintColor: Colors.transparent,
          child: StatefulBuilder(
            builder: (builderContext, setModalState) {
              if (isExtracting && errorMessage == null) {
                Future.microtask(() async {
                  try {
                    final images = await ImageUtils.prepareImagesFromPaths(
                      widget.imagePaths,
                      maxImages: 2,
                    );

                    if (images.isEmpty) {
                      setModalState(() {
                        isExtracting = false;
                        errorMessage = 'Failed to process the image(s).';
                      });
                      return;
                    }

                    final service = ref.read(photoExtractionServiceProvider);
                    final recipe = await service.extractRecipe(images: images);

                    if (!modalContext.mounted) return;

                    if (recipe == null) {
                      setModalState(() {
                        isExtracting = false;
                        errorMessage = 'No recipe found in the photo.';
                      });
                      return;
                    }

                    RecipeImage? coverImage;
                    if (widget.imagePaths.isNotEmpty) {
                      coverImage = await _savePhotoAsCover(widget.imagePaths.first);
                    }

                    if (!modalContext.mounted) return;

                    Navigator.of(modalContext, rootNavigator: true).pop();

                    if (context.mounted) {
                      final recipeEntry = _convertToRecipeEntry(
                        recipe,
                        coverImage: coverImage,
                      );
                      showRecipeEditorModal(
                        context,
                        ref: ref,
                        recipe: recipeEntry,
                        isEditing: false,
                        folderId: widget.folderId,
                      );
                    }
                  } on PhotoExtractionException catch (e) {
                    if (modalContext.mounted) {
                      setModalState(() {
                        isExtracting = false;
                        errorMessage = e.message;
                      });
                    }
                  } catch (e) {
                    AppLogger.error('Post-subscription photo extraction failed', e);
                    if (modalContext.mounted) {
                      setModalState(() {
                        isExtracting = false;
                        errorMessage = 'Failed to extract recipe. Please try again.';
                      });
                    }
                  }
                });
              }

              if (isExtracting && errorMessage == null) {
                return Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Importing Recipe',
                            style: AppTypography.h4.copyWith(
                              color: AppColors.of(builderContext).textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.xxl),
                      const CupertinoActivityIndicator(radius: 16),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        'Processing photo...',
                        style: AppTypography.body.copyWith(
                          color: AppColors.of(builderContext).textSecondary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                );
              } else {
                return Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Extraction Failed',
                            style: AppTypography.h4.copyWith(
                              color: AppColors.of(builderContext).textPrimary,
                            ),
                          ),
                          AppCircleButton(
                            icon: AppCircleButtonIcon.close,
                            variant: AppCircleButtonVariant.neutral,
                            size: 32,
                            onPressed: () => Navigator.of(
                              modalContext,
                              rootNavigator: true,
                            ).pop(),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        errorMessage ?? 'An error occurred.',
                        style: AppTypography.body.copyWith(
                          color: AppColors.of(builderContext).textSecondary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Future<RecipeImage?> _savePhotoAsCover(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        AppLogger.warning('Photo file does not exist: $imagePath');
        return null;
      }

      final imageUuid = const Uuid().v4();
      final fullFileName = '$imageUuid.jpg';
      final smallFileName = '${imageUuid}_small.jpg';

      final compressedFull = await _compressImage(file, fullFileName);
      final compressedSmall = await _compressImage(file, smallFileName, size: 512);

      final docsDir = await getApplicationDocumentsDirectory();
      final fullPath = '${docsDir.path}/$fullFileName';
      final smallPath = '${docsDir.path}/$smallFileName';
      await compressedFull.copy(fullPath);
      await compressedSmall.copy(smallPath);

      try {
        if (await compressedFull.exists()) await compressedFull.delete();
        if (await compressedSmall.exists()) await compressedSmall.delete();
      } catch (_) {}

      AppLogger.info('Photo saved as cover: $fullFileName');

      return RecipeImage(
        id: nanoid(10),
        fileName: fullFileName,
        isCover: true,
      );
    } catch (e, stack) {
      AppLogger.warning('Failed to save photo as cover', e, stack);
      return null;
    }
  }

  Future<File> _compressImage(File file, String fileName, {int size = 1280}) async {
    final directory = await getTemporaryDirectory();
    final targetPath = '${directory.path}/compressed_$fileName';

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 90,
      minWidth: size,
      minHeight: size,
      format: CompressFormat.jpeg,
    );

    return compressedFile != null ? File(compressedFile.path) : file;
  }

  RecipeEntry _convertToRecipeEntry(
    ExtractedRecipe extracted, {
    RecipeImage? coverImage,
  }) {
    const uuid = Uuid();

    final ingredients = extracted.ingredients.map((e) {
      return Ingredient(
        id: uuid.v4(),
        type: e.type,
        name: e.name,
        isCanonicalised: false,
      );
    }).toList();

    final steps = extracted.steps.map((e) {
      return db.Step(
        id: uuid.v4(),
        type: e.type,
        text: e.text,
      );
    }).toList();

    return RecipeEntry(
      id: uuid.v4(),
      title: extracted.title,
      description: extracted.description,
      language: 'en',
      userId: '',
      servings: extracted.servings,
      prepTime: extracted.prepTime,
      cookTime: extracted.cookTime,
      source: extracted.source,
      ingredients: ingredients,
      steps: steps,
      images: coverImage != null ? [coverImage] : null,
      folderIds: [],
      pinned: 0,
      pinnedAt: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_modalState) {
      case _ModalState.processing:
        return _buildProcessingState(context);
      case _ModalState.error:
        return _buildErrorState(context);
      case _ModalState.showingPreview:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProcessingState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Processing Photo',
                style: AppTypography.h4.copyWith(
                  color: AppColors.of(context).textPrimary,
                ),
              ),
              AppCircleButton(
                icon: AppCircleButtonIcon.close,
                variant: AppCircleButtonVariant.neutral,
                size: 32,
                onPressed: widget.onClose,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xxl),
          const CupertinoActivityIndicator(radius: 16),
          SizedBox(height: AppSpacing.lg),
          Text(
            _statusMessage,
            style: AppTypography.body.copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Import Failed',
                style: AppTypography.h4.copyWith(
                  color: AppColors.of(context).textPrimary,
                ),
              ),
              AppCircleButton(
                icon: AppCircleButtonIcon.close,
                variant: AppCircleButtonVariant.neutral,
                size: 32,
                onPressed: widget.onClose,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            _errorMessage ?? 'Something went wrong.',
            style: AppTypography.body.copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
