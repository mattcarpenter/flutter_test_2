import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
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
import '../../../services/content_extraction/generic_web_extractor.dart';
import '../../../services/logging/app_logger.dart';
import '../../../services/web_extraction_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/app_text_field_simple.dart';
import '../../clippings/models/extracted_recipe.dart';
import '../../clippings/models/recipe_preview.dart';
import '../../clippings/providers/preview_usage_provider.dart';
import '../../share/widgets/share_recipe_preview_result.dart';
import 'add_recipe_modal.dart';

/// Shows a URL import modal to extract recipes from web pages.
///
/// Entry point for importing recipes from URLs (from "Import from URL" menu item).
/// Handles URL input, extraction, subscription checks, and recipe creation.
Future<void> showUrlImportModal(
  BuildContext context, {
  required WidgetRef ref,
  String? folderId,
}) async {
  await WoltModalSheet.show<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    modalTypeBuilder: (_) => WoltModalType.alertDialog(),
    pageListBuilder: (modalContext) => [
      WoltModalSheetPage(
        navBarHeight: 0,
        hasTopBarLayer: false,
        backgroundColor: AppColors.of(modalContext).background,
        surfaceTintColor: Colors.transparent,
        child: _UrlImportContent(
          folderId: folderId,
          onClose: () => Navigator.of(modalContext, rootNavigator: true).pop(),
        ),
      ),
    ],
  );
}

/// Content widget for the URL import modal
class _UrlImportContent extends ConsumerStatefulWidget {
  final String? folderId;
  final VoidCallback onClose;

  const _UrlImportContent({
    required this.folderId,
    required this.onClose,
  });

  @override
  ConsumerState<_UrlImportContent> createState() => _UrlImportContentState();
}

enum _ModalState {
  inputting,
  extracting,
  error,
  showingPreview,
}

class _UrlImportContentState extends ConsumerState<_UrlImportContent> {
  _ModalState _modalState = _ModalState.inputting;
  String? _errorMessage;
  bool _isRateLimitError = false;
  bool _isUpgradeLoading = false;
  String _statusMessage = 'Fetching recipe...';
  bool _isTransitioningOut = false;

  late TextEditingController _urlController;
  late FocusNode _urlFocusNode;

  // Stored extraction result for use after preview/paywall
  WebExtractionResult? _extractionResult;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _urlFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  /// Parse and validate URL input
  Uri? _parseUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return null;

    // Auto-prepend https:// if missing
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // Check if it looks like a URL (has a dot and no spaces)
      if (url.contains('.') && !url.contains(' ')) {
        url = 'https://$url';
      } else {
        return null;
      }
    }

    try {
      final uri = Uri.parse(url);
      // Validate it has a host
      if (uri.host.isEmpty) return null;
      return uri;
    } catch (_) {
      return null;
    }
  }

  /// Transition to a new state with animation
  Future<void> _transitionToState(_ModalState newState) async {
    if (_isTransitioningOut || _modalState == newState) return;

    setState(() {
      _isTransitioningOut = true;
    });

    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    setState(() {
      _modalState = newState;
      _isTransitioningOut = false;
    });
  }

  /// Start the extraction process
  Future<void> _startExtraction() async {
    // Check connectivity first
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() {
        _modalState = _ModalState.error;
        _errorMessage = "You're offline. Please check your internet connection.";
      });
      return;
    }

    // Parse URL
    final url = _parseUrl(_urlController.text);
    if (url == null) {
      setState(() {
        _modalState = _ModalState.error;
        _errorMessage = 'Please enter a valid URL.';
      });
      return;
    }

    // Transition to extracting state
    await _transitionToState(_ModalState.extracting);

    try {
      // Check subscription status
      final hasPlus = ref.read(effectiveHasPlusProvider);

      // Fetch and try JSON-LD first
      final extractor = ref.read(genericWebExtractorProvider);
      final result = await extractor.extractFromUrl(url);

      if (!mounted) return;

      // Check for fetch error
      if (result.error != null && result.html == null) {
        setState(() {
          _modalState = _ModalState.error;
          _errorMessage = result.error;
        });
        return;
      }

      // Store result for later use
      _extractionResult = result;

      // If we got a JSON-LD recipe, handle based on subscription
      if (result.recipe != null) {
        if (hasPlus) {
          // Plus user - go straight to editor
          await _openRecipeEditor(result.recipe!, result.imageUrl);
        } else {
          // Free user - show preview
          final preview = result.recipe!.toPreview();
          _showPreviewSheet(context, preview, result);
        }
        return;
      }

      // No JSON-LD - need backend extraction
      if (!result.hasHtml) {
        setState(() {
          _modalState = _ModalState.error;
          _errorMessage = "This page doesn't appear to contain recipe information.";
        });
        return;
      }

      if (hasPlus) {
        // Plus user - full backend extraction
        await _performFullExtraction(result);
      } else {
        // Free user - check preview limit
        final usageService = await ref.read(previewUsageServiceProvider.future);

        if (!usageService.hasShareRecipePreviewsRemaining()) {
          // Limit exceeded - show paywall directly
          widget.onClose();

          await Future.delayed(const Duration(milliseconds: 100));
          final rootContext = globalRootNavigatorKey.currentContext;
          if (rootContext != null && rootContext.mounted) {
            final purchased = await ref
                .read(subscriptionProvider.notifier)
                .presentPaywall(rootContext);
            if (purchased && rootContext.mounted) {
              await _showPostSubscriptionModal(rootContext, result);
            }
          }
          return;
        }

        // Show preview extraction
        await _performPreviewExtraction(result);
      }
    } catch (e, stack) {
      AppLogger.error('URL import failed', e, stack);
      if (mounted) {
        setState(() {
          _modalState = _ModalState.error;
          _errorMessage = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  /// Perform full backend extraction for Plus users
  Future<void> _performFullExtraction(WebExtractionResult result) async {
    if (!result.hasHtml) {
      setState(() {
        _modalState = _ModalState.error;
        _errorMessage = "This page doesn't appear to contain recipe information.";
      });
      return;
    }

    setState(() {
      _statusMessage = 'Extracting recipe...';
    });

    try {
      final service = ref.read(webExtractionServiceProvider);
      final recipe = await service.extractRecipe(
        html: result.html!,
        sourceUrl: result.sourceUrl,
      );

      if (!mounted) return;

      if (recipe == null) {
        setState(() {
          _modalState = _ModalState.error;
          _errorMessage = "This page doesn't appear to contain recipe information.";
        });
        return;
      }

      await _openRecipeEditor(recipe, result.imageUrl);
    } on WebExtractionException catch (e) {
      if (mounted) {
        setState(() {
          _modalState = _ModalState.error;
          _errorMessage = e.statusCode == 429
              ? 'Recipe previews are limited for free users. Upgrade to Plus for unlimited imports.'
              : e.message;
          _isRateLimitError = e.statusCode == 429;
        });
      }
    }
  }

  /// Perform preview extraction for non-Plus users
  Future<void> _performPreviewExtraction(WebExtractionResult result) async {
    if (!result.hasHtml) {
      setState(() {
        _modalState = _ModalState.error;
        _errorMessage = 'This page requires Plus subscription for recipe extraction.';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Extracting recipe...';
    });

    try {
      final service = ref.read(webExtractionServiceProvider);
      final preview = await service.previewRecipe(
        html: result.html!,
        sourceUrl: result.sourceUrl,
      );

      if (!mounted) return;

      if (preview == null) {
        setState(() {
          _modalState = _ModalState.error;
          _errorMessage = "This page doesn't appear to contain recipe information.";
        });
        return;
      }

      // Increment usage counter
      final usageService = await ref.read(previewUsageServiceProvider.future);
      await usageService.incrementShareRecipeUsage();

      if (mounted) {
        _showPreviewSheet(context, preview, result);
      }
    } on WebExtractionException catch (e) {
      if (mounted) {
        setState(() {
          _modalState = _ModalState.error;
          _errorMessage = e.statusCode == 429
              ? 'Recipe previews are limited for free users. Upgrade to Plus for unlimited imports.'
              : e.message;
          _isRateLimitError = e.statusCode == 429;
        });
      }
    }
  }

  /// Show preview sheet for non-Plus users
  void _showPreviewSheet(
    BuildContext context,
    RecipePreview preview,
    WebExtractionResult result,
  ) {
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
                  await _showPostSubscriptionModal(rootContext, result);
                }
              }
            },
          ),
        ),
      ],
    );
  }

  /// Show post-subscription extraction modal
  Future<void> _showPostSubscriptionModal(
    BuildContext context,
    WebExtractionResult originalResult,
  ) async {
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
                    ExtractedRecipe? recipe;

                    // If we already have a JSON-LD recipe, use it directly
                    if (originalResult.recipe != null) {
                      recipe = originalResult.recipe;
                    } else if (originalResult.hasHtml) {
                      // Otherwise, do backend extraction
                      final service = ref.read(webExtractionServiceProvider);
                      recipe = await service.extractRecipe(
                        html: originalResult.html!,
                        sourceUrl: originalResult.sourceUrl,
                      );
                    }

                    if (!modalContext.mounted) return;

                    if (recipe == null) {
                      setModalState(() {
                        isExtracting = false;
                        errorMessage = 'No recipe found on this page.';
                      });
                      return;
                    }

                    // Download image if available
                    RecipeImage? coverImage;
                    final imageUrl = originalResult.imageUrl;
                    if (imageUrl != null && imageUrl.isNotEmpty) {
                      coverImage = await _downloadAndSaveImage(imageUrl);
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
                  } on WebExtractionException catch (e) {
                    if (modalContext.mounted) {
                      setModalState(() {
                        isExtracting = false;
                        errorMessage = e.message;
                      });
                    }
                  } catch (e) {
                    AppLogger.error('Post-subscription URL extraction failed', e);
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
                        'Extracting recipe...',
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

  /// Open the recipe editor with the extracted recipe
  Future<void> _openRecipeEditor(ExtractedRecipe recipe, String? imageUrl) async {
    // Download image if available
    RecipeImage? coverImage;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      AppLogger.info('URL Import: Downloading image from $imageUrl');
      coverImage = await _downloadAndSaveImage(imageUrl);
    }

    if (!mounted) return;

    final recipeEntry = _convertToRecipeEntry(recipe, coverImage: coverImage);

    // Close modal and open editor
    widget.onClose();

    final rootContext = globalRootNavigatorKey.currentContext;
    if (rootContext != null && rootContext.mounted) {
      showRecipeEditorModal(
        rootContext,
        ref: ref,
        recipe: recipeEntry,
        isEditing: false,
        folderId: widget.folderId,
      );
    }
  }

  /// Download an image from URL, compress it, and save locally
  Future<RecipeImage?> _downloadAndSaveImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      AppLogger.info('Downloading image from ${uri.host}');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Image download timed out');
        },
      );
      if (response.statusCode != 200) {
        AppLogger.warning('Failed to download image: HTTP ${response.statusCode}');
        return null;
      }

      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.startsWith('image/')) {
        AppLogger.warning('URL returned non-image content: $contentType');
        return null;
      }

      if (response.bodyBytes.isEmpty) {
        AppLogger.warning('URL returned empty response');
        return null;
      }

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final imageUuid = const Uuid().v4();
      final tempFile = File('${tempDir.path}/$imageUuid.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);

      // Compress
      final fullFileName = '$imageUuid.jpg';
      final smallFileName = '${imageUuid}_small.jpg';

      final compressedFull = await _compressImage(tempFile, fullFileName);
      final compressedSmall = await _compressImage(tempFile, smallFileName, size: 512);

      // Save to documents directory
      final docsDir = await getApplicationDocumentsDirectory();
      final fullPath = '${docsDir.path}/$fullFileName';
      final smallPath = '${docsDir.path}/$smallFileName';
      await compressedFull.copy(fullPath);
      await compressedSmall.copy(smallPath);

      // Clean up temp files
      try {
        if (await tempFile.exists()) await tempFile.delete();
        if (await compressedFull.exists()) await compressedFull.delete();
        if (await compressedSmall.exists()) await compressedSmall.delete();
      } catch (_) {}

      AppLogger.info('Image saved locally: $fullFileName');

      return RecipeImage(
        id: nanoid(10),
        fileName: fullFileName,
        isCover: true,
      );
    } catch (e, stack) {
      AppLogger.warning('Failed to download image: $e', e, stack);
      return null;
    }
  }

  /// Compress an image file
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

  /// Convert ExtractedRecipe to RecipeEntry for the editor
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
      case _ModalState.inputting:
        return _buildInputState(context);
      case _ModalState.extracting:
        return _buildExtractingState(context);
      case _ModalState.error:
        return _buildErrorState(context);
      case _ModalState.showingPreview:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInputState(BuildContext context) {
    final colors = AppColors.of(context);

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
                'Import from URL',
                style: AppTypography.h4.copyWith(
                  color: colors.textPrimary,
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
          SizedBox(height: AppSpacing.sm),
          Text(
            'Paste a recipe URL to import',
            style: AppTypography.body.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          AppTextFieldSimple(
            controller: _urlController,
            placeholder: 'https://example.com/recipe',
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            focusNode: _urlFocusNode,
            autofocus: true,
            autocorrect: false,
            onSubmitted: (_) => _startExtraction(),
          ),
          SizedBox(height: AppSpacing.lg),
          ListenableBuilder(
            listenable: _urlController,
            builder: (context, _) {
              final hasText = _urlController.text.trim().isNotEmpty;
              return AppButton(
                text: 'Import Recipe',
                onPressed: hasText ? _startExtraction : null,
                style: AppButtonStyle.fill,
                theme: AppButtonTheme.primary,
                size: AppButtonSize.large,
                shape: AppButtonShape.square,
                fullWidth: true,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExtractingState(BuildContext context) {
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
              Expanded(
                child: Text(
                  _isRateLimitError ? 'Preview Limit Reached' : 'Import Failed',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.of(context).textPrimary,
                  ),
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

                if (purchased && mounted && _extractionResult != null) {
                  // User subscribed - close modal and retry with full extraction
                  widget.onClose();
                  if (rootContext.mounted) {
                    await _showPostSubscriptionModal(rootContext, _extractionResult!);
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
              text: 'Close',
              onPressed: widget.onClose,
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
}
