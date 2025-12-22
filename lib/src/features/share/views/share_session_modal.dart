import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../mobile/adaptive_app.dart' show globalRootNavigatorKey;
import 'package:intl/intl.dart';
import 'package:nanoid/nanoid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../providers/clippings_provider.dart';
import '../../../providers/household_provider.dart';

import '../../../../database/database.dart';
import '../../../../database/models/ingredients.dart';
import '../../../../database/models/recipe_images.dart';
import '../../../../database/models/steps.dart' as db;
import '../../../providers/subscription_provider.dart';
import '../../../services/content_extraction/content_extractor.dart';
import '../../../services/logging/app_logger.dart';
import '../../../services/share_extraction_service.dart';
import '../../../services/share_session_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_circle_button.dart';
import '../../clippings/models/extracted_recipe.dart';
import '../../clippings/models/recipe_preview.dart';
import '../../clippings/providers/preview_usage_provider.dart';
import '../../recipes/views/add_recipe_modal.dart';
import '../models/og_extracted_content.dart';
import '../widgets/share_recipe_preview_result.dart';

/// Shows the share session modal for a given session ID
Future<void> showShareSessionModal(
  BuildContext context,
  WidgetRef ref,
  String sessionId,
) async {
  if (!context.mounted) return;

  WoltModalSheet.show<void>(
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
        child: _ShareSessionContent(
          sessionId: sessionId,
          onClose: () => Navigator.of(modalContext, rootNavigator: true).pop(),
        ),
      ),
    ],
  );
}

/// Content widget that displays the share session
class _ShareSessionContent extends ConsumerWidget {
  final String sessionId;
  final VoidCallback onClose;

  const _ShareSessionContent({
    required this.sessionId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(shareSessionServiceProvider);

    return serviceAsync.when(
      data: (service) => _ShareSessionLoaded(
        sessionId: sessionId,
        service: service,
        onClose: onClose,
      ),
      loading: () => _LoadingState(onClose: onClose),
      error: (error, stack) => _ErrorState(
        error: error,
        onClose: onClose,
      ),
    );
  }
}

/// Loading state while fetching the share session service
class _LoadingState extends StatelessWidget {
  final VoidCallback onClose;

  const _LoadingState({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Loading...',
                style: AppTypography.h4.copyWith(
                  color: AppColors.of(context).textPrimary,
                ),
              ),
              AppCircleButton(
                icon: AppCircleButtonIcon.close,
                variant: AppCircleButtonVariant.neutral,
                size: 32,
                onPressed: onClose,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          const CupertinoActivityIndicator(radius: 16),
        ],
      ),
    );
  }
}

/// Error state if something went wrong
class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onClose;

  const _ErrorState({
    required this.error,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
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
                'Error',
                style: AppTypography.h4.copyWith(
                  color: AppColors.of(context).textPrimary,
                ),
              ),
              AppCircleButton(
                icon: AppCircleButtonIcon.close,
                variant: AppCircleButtonVariant.neutral,
                size: 32,
                onPressed: onClose,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Failed to load shared content. Please try again.',
            style: AppTypography.body.copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal state machine states
enum _ModalState {
  choosingAction,
  extractingContent,
  showingPreview,
  extractionError,
  // Recipe extraction states
  extractingRecipe, // Calling backend AI to structure recipe
  showingRecipePreview, // Non-Plus users see preview with paywall
  // Clipping states
  savingClipping, // Saving clipping to database
}

/// Helper class for gathered clipping content
class _ClippingContent {
  final String? title;
  final String? bodyText;
  final String? sourceUrl;
  final String? sourcePlatform;

  const _ClippingContent({
    this.title,
    this.bodyText,
    this.sourceUrl,
    this.sourcePlatform,
  });

  bool get hasContent =>
      (title != null && title!.isNotEmpty) ||
      (bodyText != null && bodyText!.isNotEmpty) ||
      (sourceUrl != null && sourceUrl!.isNotEmpty);
}

/// The action the user chose
enum _ModalAction {
  importRecipe,
  saveAsClipping,
}

/// Main content when session is loaded
class _ShareSessionLoaded extends ConsumerStatefulWidget {
  final String sessionId;
  final ShareSessionService service;
  final VoidCallback onClose;

  const _ShareSessionLoaded({
    required this.sessionId,
    required this.service,
    required this.onClose,
  });

  @override
  ConsumerState<_ShareSessionLoaded> createState() =>
      _ShareSessionLoadedState();
}

class _ShareSessionLoadedState extends ConsumerState<_ShareSessionLoaded>
    with WidgetsBindingObserver {
  ShareSession? _session;
  bool _isLoadingSession = true;

  // State machine
  _ModalState _modalState = _ModalState.choosingAction;
  _ModalAction? _chosenAction;
  OGExtractedContent? _extractedContent;
  String? _extractionError;

  // Extractor instance
  final _extractor = ContentExtractor();

  // Preemptive extraction future - started when session loads if Instagram URL found
  Future<OGExtractedContent?>? _extractionFuture;

  // Completer to signal when OG extraction is done (allows early button tap)
  Completer<void>? _ogExtractionCompleter;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final session = await widget.service.readSession(widget.sessionId);
      if (session != null) {
        _logSessionData(session);
      }
      if (mounted) {
        setState(() {
          _session = session;
          _isLoadingSession = false;
        });

        // Start preemptive extraction if we have an extractable URL
        _startPreemptiveExtraction();
      }
    } catch (e, stack) {
      AppLogger.error('Failed to load share session', e, stack);
      if (mounted) {
        setState(() {
          _isLoadingSession = false;
        });
      }
    }
  }

  /// Start OG extraction in the background (preemptive)
  void _startPreemptiveExtraction() {
    final extractableUrl = _findExtractableUrl();
    if (extractableUrl != null) {
      AppLogger.info('Starting preemptive OG extraction for: $extractableUrl');
      _ogExtractionCompleter = Completer<void>();
      _extractionFuture = _extractor.extract(extractableUrl).then((content) {
        _extractedContent = content;
        if (!_ogExtractionCompleter!.isCompleted) {
          _ogExtractionCompleter!.complete();
        }
        return content;
      }).catchError((error) {
        AppLogger.error('OG extraction failed', error);
        if (!_ogExtractionCompleter!.isCompleted) {
          _ogExtractionCompleter!.complete();
        }
        return null;
      });
    } else {
      // No extractable URL - complete immediately
      _ogExtractionCompleter = Completer<void>()..complete();
    }
  }

  void _logSessionData(ShareSession session) {
    AppLogger.info('=== SHARE SESSION DATA ===');
    AppLogger.info('Session ID: ${session.sessionId}');
    AppLogger.info('Created At: ${session.createdAt}');
    AppLogger.info('Source App: ${session.sourceApp}');
    AppLogger.info('Item Count: ${session.items.length}');
    AppLogger.info('Session Path: ${session.sessionPath}');
    if (session.attributedContentText != null) {
      AppLogger.info('Attributed Content Text: ${session.attributedContentText}');
    }
    if (session.attributedTitle != null) {
      AppLogger.info('Attributed Title: ${session.attributedTitle}');
    }

    for (var i = 0; i < session.items.length; i++) {
      final item = session.items[i];
      AppLogger.info('--- Item $i ---');
      AppLogger.info('  Type: ${item.type}');
      if (item.url != null) AppLogger.info('  URL: ${item.url}');
      if (item.title != null) AppLogger.info('  Title: ${item.title}');
      if (item.text != null) {
        final preview = item.text!.length > 200
            ? '${item.text!.substring(0, 200)}...'
            : item.text!;
        AppLogger.info('  Text: $preview');
      }
      if (item.fileName != null) AppLogger.info('  File Name: ${item.fileName}');
      if (item.originalFileName != null) {
        AppLogger.info('  Original File Name: ${item.originalFileName}');
      }
      if (item.mimeType != null) AppLogger.info('  MIME Type: ${item.mimeType}');
      if (item.sizeBytes != null) AppLogger.info('  Size: ${item.sizeBytes} bytes');
      if (item.uniformTypeIdentifier != null) {
        AppLogger.info('  UTI: ${item.uniformTypeIdentifier}');
      }
    }
    AppLogger.info('=== END SHARE SESSION ===');
  }

  /// Returns true if clipping option should be shown.
  /// Hidden when only images or videos (files) are shared.
  /// Optimistically shows the option while session is loading.
  bool get _showClippingOption {
    if (_session == null) return true; // Optimistic: show while loading
    // Show clipping option if there's at least one item that's not an image/movie file
    return _session!.items.any((item) => !item.isImage && !item.isMovie);
  }

  /// Find a URL in the session that we can extract content from
  Uri? _findExtractableUrl() {
    if (_session == null) return null;

    for (final item in _session!.items) {
      if (item.isUrl && item.url != null) {
        final uri = Uri.tryParse(item.url!);
        if (uri != null && _extractor.isSupported(uri)) {
          return uri;
        }
      }
    }
    return null;
  }

  /// Handle action button tap
  Future<void> _onActionTap(_ModalAction action) async {
    setState(() {
      _chosenAction = action;
      // Show appropriate spinner based on action
      if (action == _ModalAction.importRecipe) {
        _modalState = _ModalState.extractingRecipe;
      } else if (action == _ModalAction.saveAsClipping) {
        _modalState = _ModalState.savingClipping;
      } else {
        _modalState = _ModalState.extractingContent;
      }
    });

    await _processContent();
  }

  /// Process content after user taps an action button.
  /// Awaits preemptive extraction (instant if already done) and handles result.
  /// This method is designed to be extended with additional async steps (e.g., OpenAI).
  Future<void> _processContent() async {
    try {
      // Step 0: Wait for session to load if user tapped before it was ready
      if (_isLoadingSession) {
        // Poll until session is loaded (should be very fast - just a file read)
        while (_isLoadingSession && mounted) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
        if (!mounted) return;
      }

      // Check if session failed to load
      if (_session == null) {
        setState(() {
          _extractionError = 'Failed to load shared content.';
          _modalState = _ModalState.extractionError;
        });
        return;
      }

      // Step 1: Wait for OG extraction to complete (if started)
      // This uses the completer which is more reliable than awaiting the future
      // The completer is always created (either with extraction or completed immediately)
      if (_ogExtractionCompleter != null &&
          !_ogExtractionCompleter!.isCompleted) {
        await _ogExtractionCompleter!.future;
      }

      if (!mounted) return;

      // Step 2: Handle result based on chosen action
      // _extractedContent is set by the extraction future's .then() callback
      if (_chosenAction == _ModalAction.saveAsClipping) {
        // For clippings, save directly with whatever content we have
        // (OG extraction is optional - we can save just the URL if that's all we got)
        await _saveAsClipping();
      } else if (_extractedContent != null && _extractedContent!.hasContent) {
        AppLogger.info('OG extraction successful');

        // For Import Recipe, proceed to API call (spinner already showing)
        if (_chosenAction == _ModalAction.importRecipe) {
          await _handleImportRecipe();
        } else {
          // Other actions - show the preview state
          setState(() {
            _modalState = _ModalState.showingPreview;
          });
        }
      } else if (_extractionFuture != null) {
        // Had an extractable URL but extraction failed/returned empty
        AppLogger.warning('OG extraction returned no content');
        setState(() {
          _extractionError = 'No content could be extracted from this link.';
          _modalState = _ModalState.extractionError;
        });
      } else {
        // No extractable URL, proceed directly
        await _proceedWithAction();
      }
    } catch (e, stack) {
      AppLogger.error('Content processing failed', e, stack);
      if (!mounted) return;
      setState(() {
        _extractionError = 'Failed to extract content. Please try again.';
        _modalState = _ModalState.extractionError;
      });
    }
  }

  /// Go back to action selection
  void _goBack() {
    setState(() {
      _modalState = _ModalState.choosingAction;
      _chosenAction = null;
      _extractedContent = null;
      _extractionError = null;
    });
  }

  /// Proceed with the chosen action
  Future<void> _proceedWithAction() async {
    if (_chosenAction == _ModalAction.importRecipe) {
      await _handleImportRecipe();
    } else if (_chosenAction == _ModalAction.saveAsClipping) {
      await _saveAsClipping();
    } else {
      widget.onClose();
    }
  }

  /// Handle "Import Recipe" action with subscription check
  Future<void> _handleImportRecipe() async {
    // Check connectivity first
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) {
        setState(() {
          _extractionError =
              'No internet connection. Please check your network and try again.';
          _modalState = _ModalState.extractionError;
        });
      }
      return;
    }

    if (!mounted) return;

    // Check subscription status
    final hasPlus = ref.read(effectiveHasPlusProvider);

    if (hasPlus) {
      // Entitled user - full extraction
      await _performFullRecipeExtraction();
    } else {
      // Non-entitled user - check preview limit first
      final usageService = await ref.read(previewUsageServiceProvider.future);

      if (!usageService.hasShareRecipePreviewsRemaining()) {
        // Limit exceeded - go straight to paywall
        if (!mounted) return;
        final purchased =
            await ref.read(subscriptionProvider.notifier).presentPaywall(context);
        if (purchased && mounted) {
          // User subscribed - now do full extraction
          await _performFullRecipeExtraction();
        }
        return;
      }

      // Show preview extraction
      await _performRecipePreviewExtraction();
    }
  }

  /// Perform full recipe extraction for Plus users
  Future<void> _performFullRecipeExtraction() async {
    if (_extractedContent == null || !_extractedContent!.hasContent) {
      setState(() {
        _extractionError =
            'No content available to extract. Please try again.';
        _modalState = _ModalState.extractionError;
      });
      return;
    }

    // Note: We're already showing the extractingRecipe spinner from _onActionTap

    try {
      final service = ref.read(shareExtractionServiceProvider);
      final extractableUrl = _findExtractableUrl();
      final sourcePlatform = _detectPlatform(extractableUrl);

      // Skip og:description for Instagram - often AI-generated or duplicated
      final isInstagram = sourcePlatform == 'instagram';

      final recipe = await service.extractRecipe(
        ogTitle: _extractedContent!.title,
        ogDescription: isInstagram ? null : _extractedContent!.description,
        sourceUrl: extractableUrl?.toString(),
        sourcePlatform: sourcePlatform,
      );

      if (!mounted) return;

      if (recipe == null) {
        setState(() {
          _extractionError =
              'Unable to extract a recipe from this post. It may not contain recipe information.';
          _modalState = _ModalState.extractionError;
        });
        return;
      }

      // Download OG image if available (non-blocking - recipe still created on failure)
      RecipeImage? coverImage;
      final imageUrl = _extractedContent?.imageUrl;
      AppLogger.info(
        'OG image URL from extracted content: '
        '${imageUrl != null ? "${imageUrl.substring(0, imageUrl.length.clamp(0, 100))}..." : "null"}',
      );

      if (imageUrl != null && imageUrl.isNotEmpty) {
        coverImage = await _downloadAndSaveImage(imageUrl);
        AppLogger.info(
          'Cover image download result: '
          '${coverImage != null ? "success (${coverImage.fileName})" : "failed"}',
        );
      } else {
        AppLogger.info('No OG image URL available to download');
      }

      if (!mounted) return;

      // Success - close modal and open recipe editor
      widget.onClose();

      if (context.mounted) {
        final recipeEntry = _convertToRecipeEntry(recipe, coverImage: coverImage);
        AppLogger.info(
          'Recipe entry created with ${recipeEntry.images?.length ?? 0} images',
        );
        showRecipeEditorModal(
          context,
          ref: ref,
          recipe: recipeEntry,
          isEditing: false,
        );
      }
    } on ShareExtractionException catch (e) {
      if (!mounted) return;
      setState(() {
        _extractionError = e.message;
        _modalState = _ModalState.extractionError;
      });
    } catch (e) {
      AppLogger.error('Recipe extraction failed', e);
      if (!mounted) return;
      setState(() {
        _extractionError = 'Failed to process. Please try again.';
        _modalState = _ModalState.extractionError;
      });
    }
  }

  /// Perform preview extraction for non-Plus users
  Future<void> _performRecipePreviewExtraction() async {
    if (_extractedContent == null || !_extractedContent!.hasContent) {
      setState(() {
        _extractionError =
            'No content available to extract. Please try again.';
        _modalState = _ModalState.extractionError;
      });
      return;
    }

    // Note: We're already showing the extractingRecipe spinner from _onActionTap

    try {
      final service = ref.read(shareExtractionServiceProvider);
      final extractableUrl = _findExtractableUrl();
      final sourcePlatform = _detectPlatform(extractableUrl);

      // Skip og:description for Instagram - often AI-generated or duplicated
      final isInstagram = sourcePlatform == 'instagram';

      final preview = await service.previewRecipe(
        ogTitle: _extractedContent!.title,
        ogDescription: isInstagram ? null : _extractedContent!.description,
        sourceUrl: extractableUrl?.toString(),
        sourcePlatform: sourcePlatform,
      );

      if (!mounted) return;

      if (preview == null) {
        setState(() {
          _extractionError =
              'Unable to detect a recipe in this post.';
          _modalState = _ModalState.extractionError;
        });
        return;
      }

      // Increment usage counter
      final usageService = await ref.read(previewUsageServiceProvider.future);
      await usageService.incrementShareRecipeUsage();

      // Close modal and show preview as bottom sheet (more screen space)
      widget.onClose();

      if (mounted) {
        _showPreviewBottomSheet(context, preview);
      }
    } on ShareExtractionException catch (e) {
      if (!mounted) return;
      setState(() {
        _extractionError = e.message;
        _modalState = _ModalState.extractionError;
      });
    } catch (e) {
      AppLogger.error('Recipe preview failed', e);
      if (!mounted) return;
      setState(() {
        _extractionError = 'Failed to process. Please try again.';
        _modalState = _ModalState.extractionError;
      });
    }
  }

  /// Detect the platform from the URL
  String? _detectPlatform(Uri? uri) {
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (host.contains('instagram')) return 'instagram';
    if (host.contains('tiktok')) return 'tiktok';
    return 'other';
  }

  /// Show the preview as a bottom sheet (more horizontal space than modal)
  void _showPreviewBottomSheet(BuildContext context, RecipePreview preview) {
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
              onPressed: () =>
                  Navigator.of(sheetContext, rootNavigator: true).pop(),
            ),
          ),
          child: ShareRecipePreviewResultContent(
            preview: preview,
            onSubscribe: () async {
              Navigator.of(sheetContext, rootNavigator: true).pop();
              if (!context.mounted) return;
              await ref
                  .read(subscriptionProvider.notifier)
                  .presentPaywall(context);
            },
          ),
        ),
      ],
    );
  }

  /// Compress an image file to the specified size
  Future<File> _compressImage(File file, String fileName, {int size = 1280}) async {
    final directory = await getTemporaryDirectory();
    // Use 'compressed_' prefix to avoid source/target path conflict
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

  /// Download an image from URL, compress it, and save locally
  /// Returns a RecipeImage ready to be added to upload queue, or null on failure
  Future<RecipeImage?> _downloadAndSaveImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      AppLogger.info('Downloading OG image from ${uri.host}');

      // 1. Download image from URL with timeout
      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Image download timed out');
        },
      );
      if (response.statusCode != 200) {
        AppLogger.warning(
          'Failed to download OG image: HTTP ${response.statusCode}',
        );
        return null;
      }

      AppLogger.info(
        'OG image download: HTTP ${response.statusCode}, '
        '${response.bodyBytes.length} bytes',
      );

      // Validate we got image data
      final contentType = response.headers['content-type'] ?? '';
      AppLogger.info('OG image content-type: $contentType');
      if (!contentType.startsWith('image/')) {
        AppLogger.warning('OG image URL returned non-image content: $contentType');
        return null;
      }

      // Validate response has content
      if (response.bodyBytes.isEmpty) {
        AppLogger.warning('OG image URL returned empty response');
        return null;
      }

      // 2. Save to temp file
      final tempDir = await getTemporaryDirectory();
      final imageUuid = const Uuid().v4();
      final tempFile = File('${tempDir.path}/$imageUuid.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);

      AppLogger.info('OG image saved to temp: ${tempFile.path}');

      // 3. Compress (full size + small thumbnail)
      final fullFileName = '$imageUuid.jpg';
      final smallFileName = '${imageUuid}_small.jpg';

      final compressedFull = await _compressImage(tempFile, fullFileName);
      final compressedSmall = await _compressImage(
        tempFile,
        smallFileName,
        size: 512,
      );
      AppLogger.info('OG image compressed: full=${compressedFull.path}, small=${compressedSmall.path}');

      // 4. Save to documents directory
      final docsDir = await getApplicationDocumentsDirectory();
      final fullPath = '${docsDir.path}/$fullFileName';
      final smallPath = '${docsDir.path}/$smallFileName';
      await compressedFull.copy(fullPath);
      await compressedSmall.copy(smallPath);
      AppLogger.info('OG image copied to docs: $fullPath');

      // Verify files exist
      final fullExists = await File(fullPath).exists();
      final smallExists = await File(smallPath).exists();
      AppLogger.info('OG image files exist: full=$fullExists, small=$smallExists');

      // 5. Clean up temp files
      try {
        if (await tempFile.exists()) await tempFile.delete();
        if (await compressedFull.exists()) await compressedFull.delete();
        if (await compressedSmall.exists()) await compressedSmall.delete();
      } catch (e) {
        // Ignore cleanup errors
      }

      AppLogger.info('OG image saved locally: $fullFileName');

      // 6. Return RecipeImage (no publicUrl - will be uploaded by queue)
      return RecipeImage(
        id: nanoid(10),
        fileName: fullFileName,
        isCover: true,
      );
    } catch (e, stack) {
      AppLogger.warning('Failed to download OG image: $e', e, stack);
      return null;
    }
  }

  /// Convert ExtractedRecipe to RecipeEntry for the editor
  RecipeEntry _convertToRecipeEntry(
    ExtractedRecipe extracted, {
    RecipeImage? coverImage,
  }) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    const uuid = Uuid();

    // Convert ingredients
    final ingredients = extracted.ingredients.map((e) {
      return Ingredient(
        id: uuid.v4(),
        type: e.type,
        name: e.name,
        isCanonicalised: false,
      );
    }).toList();

    // Convert steps
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
      userId: userId,
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

  /// Gather content from share session and OG extraction for clipping creation.
  /// Concatenates title and description if different, then extracts a short title
  /// (first line, max 50 chars) with the remainder in the body.
  _ClippingContent? _gatherClippingContent() {
    if (_session == null) return null;

    String? sourceUrl;
    String? sourcePlatform;

    // 1. Get URL from share session items
    for (final item in _session!.items) {
      if (item.isUrl && item.url != null && item.url!.isNotEmpty) {
        sourceUrl = item.url;
        break;
      }
    }

    // 2. Detect platform from URL
    if (sourceUrl != null) {
      final uri = Uri.tryParse(sourceUrl);
      if (uri != null) {
        final host = uri.host.toLowerCase();
        if (host.contains('instagram')) {
          sourcePlatform = 'Instagram';
        } else if (host.contains('tiktok')) {
          sourcePlatform = 'TikTok';
        } else if (host.contains('youtube')) {
          sourcePlatform = 'YouTube';
        } else if (host.contains('facebook')) {
          sourcePlatform = 'Facebook';
        } else if (host.contains('twitter') || host.contains('x.com')) {
          sourcePlatform = 'X';
        }
      }
    }

    // 3. Gather all text content
    String fullText = '';

    // Get OG title and description
    String? ogTitle = _extractedContent?.title?.trim();
    final ogDescription = _extractedContent?.description?.trim();

    // Strip Instagram attribution prefix (e.g., "John Doe on Instagram: \"...")
    if (ogTitle != null && ogTitle.contains(' on Instagram:')) {
      final parts = ogTitle.split(' on Instagram:');
      if (parts.length > 1) {
        String remainder = parts.sublist(1).join(' on Instagram:').trim();
        // Strip surrounding quotes
        if (remainder.startsWith('"') && remainder.endsWith('"')) {
          remainder = remainder.substring(1, remainder.length - 1).trim();
        }
        ogTitle = remainder.isNotEmpty ? remainder : null;
      }
    }

    if (ogTitle != null && ogTitle.isNotEmpty) {
      fullText = ogTitle;
    }

    // Concat description if different from title
    // Skip for Instagram - og:description is often AI-generated or duplicated
    if (sourcePlatform != 'Instagram' &&
        ogDescription != null &&
        ogDescription.isNotEmpty &&
        ogDescription.toLowerCase() != ogTitle?.toLowerCase() &&
        ogDescription != sourceUrl) {
      if (fullText.isNotEmpty) {
        fullText = '$fullText\n\n$ogDescription';
      } else {
        fullText = ogDescription;
      }
    }

    // Fallback to session metadata if no OG content
    if (fullText.isEmpty) {
      final attributed = _session!.attributedTitle?.trim();
      if (attributed != null && attributed.isNotEmpty) {
        fullText = attributed;
      }
    }

    // Add text from session items if still empty
    if (fullText.isEmpty) {
      for (final item in _session!.items) {
        if (item.isText && item.text != null && item.text!.isNotEmpty) {
          final text = item.text!.trim();
          if (text != sourceUrl) {
            fullText = text;
            break;
          }
        }
      }
    }

    // Fallback to attributedContentText
    if (fullText.isEmpty) {
      final attributed = _session!.attributedContentText?.trim();
      if (attributed != null && attributed.isNotEmpty && attributed != sourceUrl) {
        fullText = attributed;
      }
    }

    // 4. Split into title (first line, max 50 chars) and body
    String? title;
    String? bodyText;

    if (fullText.isNotEmpty) {
      // Find first line break
      final firstLineBreak = fullText.indexOf('\n');
      String firstLine;
      String remainder;

      if (firstLineBreak != -1) {
        firstLine = fullText.substring(0, firstLineBreak).trim();
        remainder = fullText.substring(firstLineBreak + 1).trim();
      } else {
        firstLine = fullText;
        remainder = '';
      }

      // Limit title to 50 chars
      const maxTitleLength = 50;
      if (firstLine.length > maxTitleLength) {
        title = firstLine.substring(0, maxTitleLength);
        // Body starts with continuation of truncated title
        final truncatedPart = firstLine.substring(maxTitleLength);
        if (remainder.isNotEmpty) {
          bodyText = '...$truncatedPart\n\n$remainder';
        } else {
          bodyText = '...$truncatedPart';
        }
      } else {
        title = firstLine.isNotEmpty ? firstLine : null;
        bodyText = remainder.isNotEmpty ? remainder : null;
      }
    }

    return _ClippingContent(
      title: title,
      bodyText: bodyText,
      sourceUrl: sourceUrl,
      sourcePlatform: sourcePlatform,
    );
  }

  /// Build Quill Delta JSON from clipping content
  String _buildQuillDelta(_ClippingContent content) {
    final ops = <Map<String, dynamic>>[];

    // Body text (if any)
    if (content.bodyText != null && content.bodyText!.isNotEmpty) {
      ops.add({'insert': '${content.bodyText}\n\n'});
    }

    // Source URL as clickable link
    if (content.sourceUrl != null && content.sourceUrl!.isNotEmpty) {
      ops.add({
        'insert': content.sourceUrl,
        'attributes': {'link': content.sourceUrl},
      });
      ops.add({'insert': '\n\n'});
    }

    // Import metadata
    final platform = content.sourcePlatform ?? 'shared content';
    final date = DateFormat.yMMMd().format(DateTime.now());
    ops.add({'insert': 'Imported from $platform on $date\n'});

    return jsonEncode(ops);
  }

  /// Save content as a clipping
  Future<void> _saveAsClipping() async {
    final content = _gatherClippingContent();

    // Check if we have any content to save
    if (content == null || !content.hasContent) {
      AppLogger.info('No clippable content found, closing modal');
      widget.onClose();
      return;
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final householdState = ref.read(householdNotifierProvider);
      final householdId = householdState.currentHousehold?.id;

      final quillContent = _buildQuillDelta(content);

      final newClippingId = await ref.read(clippingsProvider.notifier).addClipping(
        userId: userId,
        householdId: householdId,
        title: content.title,
        content: quillContent,
      );

      AppLogger.info(
        'Clipping saved: id=$newClippingId, title=${content.title}, '
        'hasBody=${content.bodyText != null}, '
        'hasUrl=${content.sourceUrl != null}',
      );

      if (!mounted) return;

      // Capture ID for closure before closing modal
      final clippingId = newClippingId;

      // Close modal first
      widget.onClose();

      // Navigate in next frame from stable context (modal context is being disposed)
      // Use go() instead of push() so GoRouter builds the proper page stack
      // with /clippings as parent - this enables the back button
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navContext = globalRootNavigatorKey.currentContext;
        if (navContext != null) {
          GoRouter.of(navContext).go('/clippings/$clippingId');
        }
      });
    } catch (e, stack) {
      AppLogger.error('Failed to save clipping', e, stack);
      if (mounted) {
        setState(() {
          _extractionError = 'Failed to save clipping. Please try again.';
          _modalState = _ModalState.extractionError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show buttons immediately - don't wait for session to load
    // If session fails to load after user taps, we'll show error then
    switch (_modalState) {
      case _ModalState.choosingAction:
        return _buildChoosingActionState(context);
      case _ModalState.extractingContent:
        return _buildExtractingState(context);
      case _ModalState.showingPreview:
        return _buildPreviewState(context);
      case _ModalState.extractionError:
        return _buildExtractionErrorState(context);
      case _ModalState.extractingRecipe:
        return _buildExtractingRecipeState(context);
      case _ModalState.showingRecipePreview:
        // This state is no longer used - we show a bottom sheet instead
        // Keep case to satisfy exhaustiveness check
        return const SizedBox.shrink();
      case _ModalState.savingClipping:
        return _buildSavingClippingState(context);
    }
  }

  Widget _buildChoosingActionState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Shared Content',
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
          SizedBox(height: AppSpacing.xl),

          // Import Recipe button
          _ActionButton(
            icon: Icons.restaurant_menu,
            title: 'Import Recipe',
            description: 'Extract ingredients and steps to create a new recipe',
            emphasized: true,
            onTap: () => _onActionTap(_ModalAction.importRecipe),
          ),

          // Save as Clipping button (hidden for image/video only shares)
          if (_showClippingOption) ...[
            SizedBox(height: AppSpacing.md),
            _ActionButton(
              icon: Icons.note_add_outlined,
              title: 'Save as Clipping',
              description: 'Save for later and convert to a recipe when ready',
              onTap: () => _onActionTap(_ModalAction.saveAsClipping),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExtractingState(BuildContext context) {
    final extractableUrl = _findExtractableUrl();
    final domainName = extractableUrl != null
        ? _extractor.getDisplayName(extractableUrl) ?? 'website'
        : 'website';

    return Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Extracting Content',
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
            'Fetching from $domainName...',
            style: AppTypography.body.copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildPreviewState(BuildContext context) {
    final preview = _extractedContent?.getPreview(maxLength: 300) ?? '';
    final actionLabel = _chosenAction == _ModalAction.importRecipe
        ? 'Import Recipe'
        : 'Save as Clipping';

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
                'Extracted Content',
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

          // Content preview
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.of(context).surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.of(context).border,
                width: 1,
              ),
            ),
            child: Text(
              preview.isNotEmpty ? preview : 'No preview available',
              style: AppTypography.body.copyWith(
                color: AppColors.of(context).textPrimary,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: AppSpacing.xl),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  label: 'Back',
                  onTap: _goBack,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: _PrimaryButton(
                  label: actionLabel,
                  onTap: _proceedWithAction,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtractionErrorState(BuildContext context) {
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
            _extractionError ?? 'An error occurred while extracting content.',
            style: AppTypography.body.copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.xl),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  label: 'Back',
                  onTap: _goBack,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: _PrimaryButton(
                  label: 'Continue Anyway',
                  onTap: _proceedWithAction,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtractingRecipeState(BuildContext context) {
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
          _AnimatedLoadingText(
            messages: const [
              'Extracting recipe...',
              'Finding ingredients...',
              'Organizing steps...',
            ],
          ),
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildSavingClippingState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saving Clipping',
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
            'Saving to clippings...',
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

/// Animated loading text that cycles through messages with sequential fade animation
class _AnimatedLoadingText extends StatefulWidget {
  final List<String> messages;

  const _AnimatedLoadingText({required this.messages});

  @override
  State<_AnimatedLoadingText> createState() => _AnimatedLoadingTextState();
}

class _AnimatedLoadingTextState extends State<_AnimatedLoadingText>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _timer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
      value: 1.0,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentIndex < widget.messages.length - 1) {
        _transitionToNext();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _transitionToNext() async {
    await _fadeController.reverse();
    if (mounted) {
      setState(() {
        _currentIndex++;
      });
      await _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        widget.messages[_currentIndex],
        style: AppTypography.body.copyWith(
          color: AppColors.of(context).textSecondary,
          fontFamily: Platform.isIOS ? 'SF Pro Rounded' : null,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Action button with icon, title, and description
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool emphasized;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isLight = colors.brightness == Brightness.light;

    // Emphasized style: subtle glow effect
    final boxShadow = emphasized
        ? [
            BoxShadow(
              color: colors.primary.withValues(alpha: isLight ? 0.15 : 0.25),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
          ]
        : <BoxShadow>[];

    final borderColor = emphasized
        ? colors.primary.withValues(alpha: isLight ? 0.2 : 0.3)
        : colors.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md, // Less padding on right so chevron is closer to edge
            AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            boxShadow: boxShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: colors.primary,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary action button
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary action button
class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colors.border,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
