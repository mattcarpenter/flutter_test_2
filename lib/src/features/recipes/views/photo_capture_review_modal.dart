import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
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
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../clippings/models/extracted_recipe.dart';
import '../../clippings/models/recipe_preview.dart';
import '../../clippings/providers/preview_usage_provider.dart';
import '../../share/widgets/share_recipe_preview_result.dart';
import 'add_recipe_modal.dart';

/// Shows a photo capture and review flow for importing recipes from camera.
///
/// This modal allows users to:
/// 1. Take a photo (camera opens immediately)
/// 2. Review the photo with option to take another (max 2)
/// 3. Import the recipe with a smooth transition to loading state
Future<void> showPhotoCaptureReviewModal(
  BuildContext context, {
  required WidgetRef ref,
  String? folderId,
}) async {
  // Check connectivity first
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult.contains(ConnectivityResult.none)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You\'re offline. Please check your internet connection.')),
      );
    }
    return;
  }

  // Take first photo immediately
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.camera);

  if (image == null) {
    return; // User cancelled
  }

  if (!context.mounted) return;

  // Show the review modal with the captured photo
  await WoltModalSheet.show<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    pageListBuilder: (modalContext) => [
      WoltModalSheetPage(
        navBarHeight: 0,
        hasTopBarLayer: false,
        backgroundColor: AppColors.of(modalContext).background,
        surfaceTintColor: Colors.transparent,
        child: _PhotoCaptureReviewContent(
          initialPhotoPath: image.path,
          folderId: folderId,
          onClose: () => Navigator.of(modalContext, rootNavigator: true).pop(),
        ),
      ),
    ],
  );
}

/// Content widget for the photo capture review modal
class _PhotoCaptureReviewContent extends ConsumerStatefulWidget {
  final String initialPhotoPath;
  final String? folderId;
  final VoidCallback onClose;

  const _PhotoCaptureReviewContent({
    required this.initialPhotoPath,
    required this.folderId,
    required this.onClose,
  });

  @override
  ConsumerState<_PhotoCaptureReviewContent> createState() => _PhotoCaptureReviewContentState();
}

enum _ModalState {
  reviewing,
  processing,
  error,
}

class _PhotoCaptureReviewContentState extends ConsumerState<_PhotoCaptureReviewContent> {
  _ModalState _modalState = _ModalState.reviewing;
  bool _isTransitioningOut = false;

  late List<String> _capturedPhotoPaths;
  String? _errorMessage;
  bool _isRateLimitError = false;
  bool _isUpgradeLoading = false;
  String _processingMessage = 'Reading photos...';

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _capturedPhotoPaths = [widget.initialPhotoPath];
  }

  /// Smoothly transition to a new modal state with staged animation
  Future<void> _transitionToState(_ModalState newState) async {
    if (_isTransitioningOut || _modalState == newState) return;

    // Start fade-out
    setState(() {
      _isTransitioningOut = true;
    });

    // Wait for fade-out to complete
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    // Change state and start fade-in
    setState(() {
      _modalState = newState;
      _isTransitioningOut = false;
    });
  }

  Future<void> _takeAnotherPhoto() async {
    if (_capturedPhotoPaths.length >= 2) return;

    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    if (mounted) {
      setState(() {
        _capturedPhotoPaths.add(image.path);
      });
    }
  }

  void _removePhoto(int index) {
    if (_capturedPhotoPaths.length <= 1) return; // Must have at least one

    setState(() {
      _capturedPhotoPaths.removeAt(index);
    });
  }

  Future<void> _onImportTap() async {
    // Smooth transition to processing state
    await _transitionToState(_ModalState.processing);

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
            await _showPostSubscriptionModal(rootContext);
          }
        }
        return;
      }

      // Show preview
      await _performPreviewExtraction();
    }
  }

  Future<void> _performFullExtraction() async {
    try {
      setState(() {
        _processingMessage = 'Processing photos...';
      });

      final images = await ImageUtils.prepareImagesFromPaths(
        _capturedPhotoPaths,
        maxImages: 2,
      );

      if (images.isEmpty) {
        await _transitionToState(_ModalState.error);
        setState(() {
          _errorMessage = 'Failed to process the photo(s). Please try again.';
        });
        return;
      }

      setState(() {
        _processingMessage = 'Extracting recipe...';
      });

      final service = ref.read(photoExtractionServiceProvider);
      final recipe = await service.extractRecipe(images: images);

      if (!mounted) return;

      if (recipe == null) {
        await _transitionToState(_ModalState.error);
        setState(() {
          _errorMessage = 'No recipe found in the photo.\n\nTry a photo of a recipe card or cookbook page.';
        });
        return;
      }

      // Save first image as cover
      RecipeImage? coverImage;
      if (_capturedPhotoPaths.isNotEmpty) {
        coverImage = await _savePhotoAsCover(_capturedPhotoPaths.first);
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
        await _transitionToState(_ModalState.error);
        setState(() {
          _errorMessage = e.message;
          _isRateLimitError = e.statusCode == 429;
        });
      }
    } catch (e) {
      AppLogger.error('Photo extraction failed', e);
      if (mounted) {
        await _transitionToState(_ModalState.error);
        setState(() {
          _errorMessage = 'Something went wrong. Please try again.';
          _isRateLimitError = false;
        });
      }
    }
  }

  Future<void> _performPreviewExtraction() async {
    try {
      setState(() {
        _processingMessage = 'Processing photos...';
      });

      final images = await ImageUtils.prepareImagesFromPaths(
        _capturedPhotoPaths,
        maxImages: 2,
      );

      if (images.isEmpty) {
        await _transitionToState(_ModalState.error);
        setState(() {
          _errorMessage = 'Failed to process the photo(s). Please try again.';
        });
        return;
      }

      setState(() {
        _processingMessage = 'Extracting recipe...';
      });

      final service = ref.read(photoExtractionServiceProvider);
      final preview = await service.previewRecipe(images: images);

      if (!mounted) return;

      if (preview == null) {
        await _transitionToState(_ModalState.error);
        setState(() {
          _errorMessage = 'No recipe found in the photo.\n\nTry a photo of a recipe card or cookbook page.';
        });
        return;
      }

      // Increment usage counter
      final usageService = await ref.read(previewUsageServiceProvider.future);
      await usageService.incrementPhotoRecipeUsage();

      if (!mounted) return;

      // Show preview sheet on top (don't close this modal yet)
      _showPreviewSheet(context, preview);
    } on PhotoExtractionException catch (e) {
      if (mounted) {
        await _transitionToState(_ModalState.error);
        setState(() {
          _errorMessage = e.message;
          _isRateLimitError = e.statusCode == 429;
        });
      }
    } catch (e) {
      AppLogger.error('Photo preview extraction failed', e);
      if (mounted) {
        await _transitionToState(_ModalState.error);
        setState(() {
          _errorMessage = 'Something went wrong. Please try again.';
          _isRateLimitError = false;
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
                widget.onClose(); // Close underlying modal too
              },
            ),
          ),
          child: ShareRecipePreviewResultContent(
            preview: preview,
            source: RecipePreviewSource.photoImport,
            onSubscribe: () async {
              if (!context.mounted) return;

              final purchased = await ref
                  .read(subscriptionProvider.notifier)
                  .presentPaywall(context);

              if (purchased && context.mounted) {
                // Close preview sheet and underlying modal
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext, rootNavigator: true).pop();
                }
                widget.onClose();

                // Perform full extraction
                final rootContext = globalRootNavigatorKey.currentContext;
                if (rootContext != null && rootContext.mounted) {
                  await _showPostSubscriptionModal(rootContext);
                }
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
                      _capturedPhotoPaths,
                      maxImages: 2,
                    );

                    if (images.isEmpty) {
                      setModalState(() {
                        isExtracting = false;
                        errorMessage = 'Failed to process the photo(s).';
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
                    if (_capturedPhotoPaths.isNotEmpty) {
                      coverImage = await _savePhotoAsCover(_capturedPhotoPaths.first);
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
    // Staged animation approach:
    // 1. AnimatedOpacity handles fade out/in (controlled by _isTransitioningOut)
    // 2. AnimatedSize handles modal size changes (triggered when _modalState changes)
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        opacity: _isTransitioningOut ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: _buildStateContent(context),
      ),
    );
  }

  Widget _buildStateContent(BuildContext context) {
    switch (_modalState) {
      case _ModalState.reviewing:
        return _buildReviewingState(context);
      case _ModalState.processing:
        return _buildProcessingState(context);
      case _ModalState.error:
        return _buildErrorState(context);
    }
  }

  Widget _buildReviewingState(BuildContext context) {
    final canAddMore = _capturedPhotoPaths.length < 2;

    return Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recipe Photos',
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
          SizedBox(height: AppSpacing.xl),

          // Photo thumbnails row
          SizedBox(
            height: 120,
            child: Row(
              children: [
                // Captured photos
                ..._capturedPhotoPaths.asMap().entries.map((entry) {
                  final index = entry.key;
                  final path = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(right: AppSpacing.md),
                    child: _buildPhotoThumbnail(context, path, index),
                  );
                }),

                // Add photo button (if can add more)
                if (canAddMore)
                  _buildAddPhotoButton(context),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Tip text
          if (canAddMore)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.lg),
              child: Text(
                'Tip: Add another photo for multi-page recipes',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.of(context).textSecondary,
                ),
              ),
            ),

          // Import button
          AppButton(
            text: 'Import Recipe',
            onPressed: _onImportTap,
            style: AppButtonStyle.fill,
            theme: AppButtonTheme.primary,
            size: AppButtonSize.large,
            shape: AppButtonShape.square,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail(BuildContext context, String path, int index) {
    final canRemove = _capturedPhotoPaths.length > 1;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(path),
            width: 100,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
        // Remove button
        if (canRemove)
          Positioned(
            top: -8,
            right: -8,
            child: GestureDetector(
              onTap: () => _removePhoto(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.of(context).background,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.of(context).textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddPhotoButton(BuildContext context) {
    return GestureDetector(
      onTap: _takeAnotherPhoto,
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.of(context).border,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCamera01,
              size: 28,
              color: AppColors.of(context).textSecondary,
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Add Photo',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.of(context).textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
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
                'Importing Recipe',
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
            _processingMessage,
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
                _isRateLimitError ? 'Preview Limit Reached' : 'Import Failed',
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
          SizedBox(height: AppSpacing.xl),
          if (_isRateLimitError)
            AppButton(
              text: 'Upgrade to Plus',
              onPressed: _isUpgradeLoading ? null : () async {
                setState(() {
                  _isUpgradeLoading = true;
                });

                // Use root navigator context to avoid modal context issues
                final rootContext = globalRootNavigatorKey.currentContext;
                if (rootContext == null || !rootContext.mounted) {
                  if (mounted) {
                    setState(() {
                      _isUpgradeLoading = false;
                    });
                  }
                  return;
                }

                final purchased = await ref
                    .read(subscriptionProvider.notifier)
                    .presentPaywall(rootContext);

                // Always reset loading state after paywall returns
                if (mounted) {
                  setState(() {
                    _isUpgradeLoading = false;
                  });
                }

                if (purchased && mounted) {
                  // User subscribed - close modal and retry with full extraction
                  widget.onClose();
                  if (rootContext.mounted) {
                    await _showPostSubscriptionModal(rootContext);
                  }
                }
              },
              style: AppButtonStyle.fill,
              theme: AppButtonTheme.primary,
              size: AppButtonSize.large,
              shape: AppButtonShape.square,
              fullWidth: true,
              loading: _isUpgradeLoading,
            )
          else
            AppButton(
              text: 'Try Again',
              onPressed: () async {
                await _transitionToState(_ModalState.reviewing);
              },
              style: AppButtonStyle.outline,
              theme: AppButtonTheme.secondary,
              size: AppButtonSize.large,
              shape: AppButtonShape.square,
              fullWidth: true,
            ),
        ],
      ),
    );
  }
}
