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
import '../../../services/content_extraction/generic_web_extractor.dart';
import '../../../services/logging/app_logger.dart';
import '../../../services/photo_extraction_service.dart';
import '../../../services/share_extraction_service.dart';
import '../../../services/web_extraction_service.dart';
import '../../../services/share_session_service.dart';
import '../../../utils/image_utils.dart';
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
  extractionError,
  // Recipe extraction states
  extractingRecipe, // Calling backend AI to structure recipe
  showingRecipePreview, // Non-Plus users see preview with paywall
  // Photo extraction states
  extractingPhotoRecipe, // Processing photo(s) with AI vision
  // Clipping states
  savingClipping, // Saving clipping to database
}

/// Types of extraction errors for context-aware error messages
enum _ExtractionErrorType {
  noRecipeDetected, // AI couldn't find recipe content in the post
  noContentExtracted, // URL extraction failed or returned empty
  noConnectivity, // User is offline
  sessionFailed, // Share session load failed
  clippingSaveFailed, // Clipping save failed - don't offer to save again
  generic, // Catch-all for other errors
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
  _ExtractionErrorType _errorType = _ExtractionErrorType.generic;

  // Animation state for smooth transitions
  bool _isTransitioningOut = false;

  // Extractor instances
  final _extractor = ContentExtractor();
  final _genericWebExtractor = GenericWebExtractor();

  // Preemptive extraction future - started when session loads if Instagram URL found
  Future<OGExtractedContent?>? _extractionFuture;

  // Completer to signal when OG extraction is done (allows early button tap)
  Completer<void>? _ogExtractionCompleter;

  // Generic web extraction result (for non-platform URLs)
  WebExtractionResult? _webExtractionResult;
  Future<WebExtractionResult?>? _webExtractionFuture;
  Completer<void>? _webExtractionCompleter;

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
      // Known platform (Instagram, TikTok, YouTube) - use OG extraction
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
      // No web extraction for known platforms
      _webExtractionCompleter = Completer<void>()..complete();
    } else {
      // No known platform URL - check for generic URL
      _ogExtractionCompleter = Completer<void>()..complete();

      final genericUrl = _findGenericUrl();
      if (genericUrl != null) {
        // Generic website - start web extraction (JSON-LD parsing)
        AppLogger.info('Starting preemptive web extraction for: $genericUrl');
        _webExtractionCompleter = Completer<void>();
        _webExtractionFuture = _genericWebExtractor.extractFromUrl(genericUrl).then((result) {
          _webExtractionResult = result;
          AppLogger.info(
            'Web extraction completed: '
            'success=${result.success}, '
            'isFromJsonLd=${result.isFromJsonLd}, '
            'hasHtml=${result.hasHtml}, '
            'error=${result.error}',
          );
          if (!_webExtractionCompleter!.isCompleted) {
            _webExtractionCompleter!.complete();
          }
          return result;
        }).catchError((Object error) {
          AppLogger.error('Web extraction failed', error);
          // Store the error result so we can show an appropriate message
          _webExtractionResult = WebExtractionResult(
            error: 'Could not load the page. Please try again.',
            sourceUrl: genericUrl.toString(),
          );
          if (!_webExtractionCompleter!.isCompleted) {
            _webExtractionCompleter!.complete();
          }
          return _webExtractionResult!;
        });
      } else {
        // No URL at all
        _webExtractionCompleter = Completer<void>()..complete();
      }
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

  /// Find a URL in the session that we can extract content from (known platforms)
  Uri? _findExtractableUrl() {
    if (_session == null) return null;

    for (final item in _session!.items) {
      // Check explicit URL items (existing behavior)
      if (item.isUrl && item.url != null) {
        final uri = Uri.tryParse(item.url!);
        if (uri != null && _extractor.isSupported(uri)) {
          return uri;
        }
      }

      // Check text items that contain URLs (YouTube shares come as text)
      if (item.isText && item.text != null) {
        final text = item.text!.trim();
        if (text.startsWith('http://') || text.startsWith('https://')) {
          final uri = Uri.tryParse(text);
          if (uri != null && _extractor.isSupported(uri)) {
            return uri;
          }
        }
      }
    }
    return null;
  }

  /// Find a generic URL in the session (not supported by known platform extractors)
  Uri? _findGenericUrl() {
    if (_session == null) return null;

    for (final item in _session!.items) {
      // Check explicit URL items
      if (item.isUrl && item.url != null) {
        final uri = Uri.tryParse(item.url!);
        if (uri != null && !_extractor.isSupported(uri)) {
          // Ensure it's a valid HTTP(S) URL
          if (uri.scheme == 'http' || uri.scheme == 'https') {
            return uri;
          }
        }
      }

      // Check text items that contain URLs
      if (item.isText && item.text != null) {
        final text = item.text!.trim();
        if (text.startsWith('http://') || text.startsWith('https://')) {
          final uri = Uri.tryParse(text);
          if (uri != null && !_extractor.isSupported(uri)) {
            return uri;
          }
        }
      }
    }
    return null;
  }

  /// Find image file paths in the session (for photo import).
  /// Returns up to 2 image paths (max allowed for photo extraction).
  List<String> _findImagePaths() {
    if (_session == null) return [];

    final paths = <String>[];
    final sessionPath = _session!.sessionPath;

    for (final item in _session!.items) {
      if (item.isImage && item.fileName != null) {
        // Build full path from session path + file name
        final fullPath = '$sessionPath/${item.fileName}';
        paths.add(fullPath);
        if (paths.length >= 2) break; // Max 2 images
      }
    }

    return paths;
  }

  /// Returns true if session contains images that can be processed for photo import.
  bool get _hasImagesForPhotoImport {
    if (_session == null) return false;
    return _session!.items.any((item) => item.isImage && item.fileName != null);
  }

  /// Handle action button tap
  /// Smoothly transition to a new modal state with staged animation:
  /// 1. Fade out current content (200ms)
  /// 2. Change state (triggers size animation + fade in)
  Future<void> _transitionToState(_ModalState newState) async {
    // Prevent double-transitions or no-op transitions
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

  Future<void> _onActionTap(_ModalAction action) async {
    setState(() {
      _chosenAction = action;
    });

    // Determine target state based on action
    final newState = switch (action) {
      _ModalAction.importRecipe => _ModalState.extractingRecipe,
      _ModalAction.saveAsClipping => _ModalState.savingClipping,
    };

    // Animate to new state
    await _transitionToState(newState);

    // Process the content
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
          _extractionError = 'We couldn\'t load the shared content. Please try sharing again.';
          _errorType = _ExtractionErrorType.sessionFailed;
          _modalState = _ModalState.extractionError;
        });
        return;
      }

      // Step 1: Wait for extractions to complete (if started)
      // Wait for both OG extraction and web extraction completers
      if (_ogExtractionCompleter != null &&
          !_ogExtractionCompleter!.isCompleted) {
        await _ogExtractionCompleter!.future;
      }
      if (_webExtractionCompleter != null &&
          !_webExtractionCompleter!.isCompleted) {
        await _webExtractionCompleter!.future;
      }

      if (!mounted) return;

      // Step 2: Handle result based on chosen action
      if (_chosenAction == _ModalAction.saveAsClipping) {
        // For clippings, save directly with whatever content we have
        // (OG extraction is optional - we can save just the URL if that's all we got)
        await _saveAsClipping();
      } else if (_extractedContent != null && _extractedContent!.hasContent) {
        // Known platform with OG content (Instagram, TikTok, YouTube)
        AppLogger.info('OG extraction successful, proceeding with recipe import');
        await _handleImportRecipe();
      } else if (_webExtractionResult != null) {
        // Generic website - handle web extraction result
        await _handleGenericWebImport();
      } else if (_extractionFuture != null) {
        // Had an extractable URL but extraction failed/returned empty
        AppLogger.warning('OG extraction returned no content');
        setState(() {
          _extractionError = 'We couldn\'t read this post. It may be private or unavailable.';
          _errorType = _ExtractionErrorType.noContentExtracted;
          _modalState = _ModalState.extractionError;
        });
      } else if (_webExtractionFuture != null) {
        // Had a generic URL but web extraction failed
        AppLogger.warning('Web extraction returned no result');
        setState(() {
          _extractionError = 'We couldn\'t read this page. Please try again.';
          _errorType = _ExtractionErrorType.noContentExtracted;
          _modalState = _ModalState.extractionError;
        });
      } else {
        // No URL at all - this shouldn't happen for recipe import
        // but handle gracefully
        await _proceedWithAction();
      }
    } catch (e, stack) {
      AppLogger.error('Content processing failed', e, stack);
      if (!mounted) return;
      setState(() {
        _extractionError = 'Something went wrong while processing.';
        _errorType = _ExtractionErrorType.generic;
        _modalState = _ModalState.extractionError;
      });
    }
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
          _extractionError = 'You\'re offline. Please check your internet connection and try again.';
          _errorType = _ExtractionErrorType.noConnectivity;
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

  /// Handle "Import from Photo" action with subscription check
  Future<void> _handlePhotoImport() async {
    // Check connectivity first
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) {
        setState(() {
          _extractionError = 'You\'re offline. Please check your internet connection and try again.';
          _errorType = _ExtractionErrorType.noConnectivity;
          _modalState = _ModalState.extractionError;
        });
      }
      return;
    }

    if (!mounted) return;

    // Get image paths
    final imagePaths = _findImagePaths();
    if (imagePaths.isEmpty) {
      setState(() {
        _extractionError = 'No images found to process.';
        _errorType = _ExtractionErrorType.noContentExtracted;
        _modalState = _ModalState.extractionError;
      });
      return;
    }

    // Check subscription status
    final hasPlus = ref.read(effectiveHasPlusProvider);

    if (hasPlus) {
      // Entitled user - full extraction
      await _performFullPhotoExtraction(imagePaths);
    } else {
      // Non-entitled user - check preview limit first
      final usageService = await ref.read(previewUsageServiceProvider.future);

      if (!usageService.hasPhotoRecipePreviewsRemaining()) {
        // Limit exceeded - go straight to paywall
        if (!mounted) return;
        final purchased =
            await ref.read(subscriptionProvider.notifier).presentPaywall(context);
        if (purchased && mounted) {
          // User subscribed - now do full extraction
          await _performFullPhotoExtraction(imagePaths);
        }
        return;
      }

      // Show preview extraction
      await _performPhotoPreviewExtraction(imagePaths);
    }
  }

  /// Perform full photo recipe extraction for Plus users
  Future<void> _performFullPhotoExtraction(List<String> imagePaths) async {
    try {
      // Prepare images for upload (compress and convert to bytes)
      final images = await ImageUtils.prepareImagesFromPaths(imagePaths, maxImages: 2);

      if (images.isEmpty) {
        setState(() {
          _extractionError = 'Failed to process the image(s). Please try again.';
          _errorType = _ExtractionErrorType.noContentExtracted;
          _modalState = _ModalState.extractionError;
        });
        return;
      }

      // Call photo extraction API
      final service = ref.read(photoExtractionServiceProvider);
      final recipe = await service.extractRecipe(images: images);

      if (!mounted) return;

      if (recipe == null) {
        setState(() {
          _extractionError = 'No recipe found in the photo.\n\nTry sharing a photo of a recipe card or cookbook page.';
          _errorType = _ExtractionErrorType.noRecipeDetected;
          _modalState = _ModalState.extractionError;
        });
        return;
      }

      // Save first image as cover if available
      RecipeImage? coverImage;
      if (imagePaths.isNotEmpty) {
        coverImage = await _savePhotoAsCover(imagePaths.first);
      }

      if (!mounted) return;

      // Success - close modal and open recipe editor
      widget.onClose();

      if (context.mounted) {
        final recipeEntry = _convertToRecipeEntry(recipe, coverImage: coverImage);
        showRecipeEditorModal(
          context,
          ref: ref,
          recipe: recipeEntry,
          isEditing: false,
        );
      }
    } on PhotoExtractionException catch (e) {
      if (!mounted) return;
      setState(() {
        _extractionError = e.message;
        _errorType = _ExtractionErrorType.generic;
        _modalState = _ModalState.extractionError;
      });
    } catch (e) {
      AppLogger.error('Photo recipe extraction failed', e);
      if (!mounted) return;
      setState(() {
        _extractionError = 'Something went wrong while processing the photo.';
        _errorType = _ExtractionErrorType.generic;
        _modalState = _ModalState.extractionError;
      });
    }
  }

  /// Perform photo preview extraction for non-Plus users
  Future<void> _performPhotoPreviewExtraction(List<String> imagePaths) async {
    try {
      // Prepare images for upload
      final images = await ImageUtils.prepareImagesFromPaths(imagePaths, maxImages: 2);

      if (images.isEmpty) {
        setState(() {
          _extractionError = 'Failed to process the image(s). Please try again.';
          _errorType = _ExtractionErrorType.noContentExtracted;
          _modalState = _ModalState.extractionError;
        });
        return;
      }

      // Call photo preview API
      final service = ref.read(photoExtractionServiceProvider);
      final preview = await service.previewRecipe(images: images);

      if (!mounted) return;

      if (preview == null) {
        setState(() {
          _extractionError = 'No recipe found in the photo.\n\nTry sharing a photo of a recipe card or cookbook page.';
          _errorType = _ExtractionErrorType.noRecipeDetected;
          _modalState = _ModalState.extractionError;
        });
        return;
      }

      // Increment usage counter
      final usageService = await ref.read(previewUsageServiceProvider.future);
      await usageService.incrementPhotoRecipeUsage();

      // Update modal state
      if (mounted) {
        setState(() {
          _modalState = _ModalState.showingRecipePreview;
        });
      }

      // Show preview as bottom sheet
      if (mounted) {
        _showPhotoPreviewBottomSheet(context, preview, imagePaths);
      }
    } on PhotoExtractionException catch (e) {
      if (!mounted) return;
      setState(() {
        _extractionError = e.message;
        _errorType = _ExtractionErrorType.generic;
        _modalState = _ModalState.extractionError;
      });
    } catch (e) {
      AppLogger.error('Photo recipe preview failed', e);
      if (!mounted) return;
      setState(() {
        _extractionError = 'Something went wrong while processing the photo.';
        _errorType = _ExtractionErrorType.generic;
        _modalState = _ModalState.extractionError;
      });
    }
  }

  /// Show the photo preview as a bottom sheet
  void _showPhotoPreviewBottomSheet(
    BuildContext context,
    RecipePreview preview,
    List<String> imagePaths,
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
                widget.onClose();
              },
            ),
          ),
          child: ShareRecipePreviewResultContent(
            preview: preview,
            source: RecipePreviewSource.socialShare,
            onSubscribe: () async {
              if (!context.mounted) return;

              final purchased = await ref
                  .read(subscriptionProvider.notifier)
                  .presentPaywall(context);

              if (purchased && context.mounted) {
                // Close preview sheet and share modal
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext, rootNavigator: true).pop();
                }
                widget.onClose();

                // Perform full extraction
                final rootContext = globalRootNavigatorKey.currentContext;
                if (rootContext != null && rootContext.mounted) {
                  await _performPostPhotoSubscriptionExtraction(rootContext, imagePaths);
                }
              }
            },
          ),
        ),
      ],
    );
  }

  /// Perform full photo extraction after user subscribes from preview
  Future<void> _performPostPhotoSubscriptionExtraction(
    BuildContext context,
    List<String> imagePaths,
  ) async {
    // State for the extraction modal
    var isExtracting = true;
    String? errorMessage;

    if (!context.mounted) return;

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
                    // Prepare images
                    final images = await ImageUtils.prepareImagesFromPaths(
                      imagePaths,
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

                    // Save first image as cover
                    RecipeImage? coverImage;
                    if (imagePaths.isNotEmpty) {
                      coverImage = await _savePhotoAsCover(imagePaths.first);
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

              // Build UI based on state
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
                // Error state
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

  /// Save a photo file as recipe cover image
  Future<RecipeImage?> _savePhotoAsCover(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        AppLogger.warning('Photo file does not exist: $imagePath');
        return null;
      }

      // Generate unique file names
      final imageUuid = const Uuid().v4();
      final fullFileName = '$imageUuid.jpg';
      final smallFileName = '${imageUuid}_small.jpg';

      // Compress full size and thumbnail
      final compressedFull = await _compressImage(file, fullFileName);
      final compressedSmall = await _compressImage(file, smallFileName, size: 512);

      // Save to documents directory
      final docsDir = await getApplicationDocumentsDirectory();
      final fullPath = '${docsDir.path}/$fullFileName';
      final smallPath = '${docsDir.path}/$smallFileName';
      await compressedFull.copy(fullPath);
      await compressedSmall.copy(smallPath);

      // Clean up temp files
      try {
        if (await compressedFull.exists()) await compressedFull.delete();
        if (await compressedSmall.exists()) await compressedSmall.delete();
      } catch (_) {
        // Ignore cleanup errors
      }

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

  /// Handle generic web import (non-platform URLs like recipe blogs)
  ///
  /// This handles URLs that aren't from Instagram/TikTok/YouTube.
  /// Uses a two-tier strategy:
  /// 1. JSON-LD schema parsing (free, local) - if the site has structured data
  /// 2. Backend Readability + OpenAI extraction (requires Plus) - fallback
  Future<void> _handleGenericWebImport() async {
    final result = _webExtractionResult;
    if (result == null) {
      setState(() {
        _extractionError = 'No content available to extract.';
        _errorType = _ExtractionErrorType.noContentExtracted;
        _modalState = _ModalState.extractionError;
      });
      return;
    }

    // Check for extraction error
    if (result.error != null && !result.success) {
      setState(() {
        _extractionError = result.error!;
        _errorType = _ExtractionErrorType.noContentExtracted;
        _modalState = _ModalState.extractionError;
      });
      return;
    }

    // Case 1: JSON-LD recipe found - FREE for all users (no API cost)
    if (result.recipe != null && result.isFromJsonLd) {
      AppLogger.info('JSON-LD recipe found - opening editor (free for all users)');

      // JSON-LD extraction is completely free (local parsing, no API call)
      // No subscription check needed - all users can import these directly
      await _performJsonLdFullExtraction(result);
      return;
    }

    // Case 2: No JSON-LD - need backend extraction (requires Plus)
    // Check connectivity first (backend call required)
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) {
        setState(() {
          _extractionError = 'You\'re offline. Please check your internet connection and try again.';
          _errorType = _ExtractionErrorType.noConnectivity;
          _modalState = _ModalState.extractionError;
        });
      }
      return;
    }

    if (!mounted) return;

    // Check Plus subscription
    final hasPlus = ref.read(effectiveHasPlusProvider);

    if (hasPlus) {
      // Plus user - perform backend extraction
      await _performWebBackendExtraction(result);
    } else {
      // Non-Plus user - check preview limit
      final usageService = await ref.read(previewUsageServiceProvider.future);

      if (!usageService.hasShareRecipePreviewsRemaining()) {
        // Limit exceeded - go straight to paywall
        if (!mounted) return;
        final purchased =
            await ref.read(subscriptionProvider.notifier).presentPaywall(context);
        if (purchased && mounted) {
          // User subscribed - now do backend extraction
          await _performWebBackendExtraction(result);
        }
        return;
      }

      // Show preview extraction
      await _performWebPreviewExtraction(result);
    }
  }

  /// Performs full extraction for JSON-LD recipe (free for all users).
  ///
  /// JSON-LD extraction is completely free since it's local parsing with no API cost.
  /// Downloads the image and opens the recipe editor directly.
  Future<void> _performJsonLdFullExtraction(WebExtractionResult result) async {
    if (result.recipe == null) return;

    // Download image if available (JSON-LD image or og:image fallback)
    RecipeImage? coverImage;
    final imageUrl = result.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      AppLogger.info(
        'Downloading recipe image from: '
        '${imageUrl.substring(0, imageUrl.length.clamp(0, 80))}...',
      );
      coverImage = await _downloadAndSaveImage(imageUrl);
      AppLogger.info(
        'Image download result: ${coverImage != null ? "success" : "failed"}',
      );
    }

    if (!mounted) return;

    // Close modal and open recipe editor
    widget.onClose();

    if (context.mounted) {
      final recipeEntry = _convertToRecipeEntry(
        result.recipe!,
        coverImage: coverImage,
      );
      showRecipeEditorModal(
        context,
        ref: ref,
        recipe: recipeEntry,
        isEditing: false,
      );
    }
  }

  /// Perform backend extraction for generic websites (Plus users)
  Future<void> _performWebBackendExtraction(WebExtractionResult webResult) async {
    if (!webResult.hasHtml) {
      setState(() {
        _extractionError = 'No content available to extract.';
        _errorType = _ExtractionErrorType.noContentExtracted;
        _modalState = _ModalState.extractionError;
      });
      return;
    }

    try {
      final service = ref.read(webExtractionServiceProvider);
      final recipe = await service.extractRecipe(
        html: webResult.html!,
        sourceUrl: webResult.sourceUrl,
      );

      if (!mounted) return;

      if (recipe == null) {
        setState(() {
          _extractionError = 'This page doesn\'t appear to contain recipe information.\n\nTry sharing a page that includes a recipe.';
          _errorType = _ExtractionErrorType.noRecipeDetected;
          _modalState = _ModalState.extractionError;
        });
        return;
      }

      // Download image if available (og:image extracted before backend call)
      RecipeImage? coverImage;
      final imageUrl = webResult.imageUrl;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        AppLogger.info('Downloading recipe image from: ${imageUrl.substring(0, imageUrl.length.clamp(0, 80))}...');
        coverImage = await _downloadAndSaveImage(imageUrl);
        AppLogger.info('Image download result: ${coverImage != null ? "success" : "failed"}');
      }

      if (!mounted) return;

      // Success - close modal and open recipe editor
      widget.onClose();

      if (context.mounted) {
        final recipeEntry = _convertToRecipeEntry(recipe, coverImage: coverImage);
        showRecipeEditorModal(
          context,
          ref: ref,
          recipe: recipeEntry,
          isEditing: false,
        );
      }
    } on WebExtractionException catch (e) {
      if (!mounted) return;
      setState(() {
        _extractionError = e.message;
        _errorType = _ExtractionErrorType.generic;
        _modalState = _ModalState.extractionError;
      });
    } catch (e) {
      AppLogger.error('Web backend extraction failed', e);
      if (!mounted) return;
      setState(() {
        _extractionError = 'Something went wrong while importing.';
        _errorType = _ExtractionErrorType.generic;
        _modalState = _ModalState.extractionError;
      });
    }
  }

  /// Perform preview extraction for generic websites (non-Plus users)
  Future<void> _performWebPreviewExtraction(WebExtractionResult webResult) async {
    if (!webResult.hasHtml) {
      setState(() {
        _extractionError = 'This site requires Plus subscription for recipe extraction.';
        _errorType = _ExtractionErrorType.noContentExtracted;
        _modalState = _ModalState.extractionError;
      });
      return;
    }

    try {
      final service = ref.read(webExtractionServiceProvider);
      final preview = await service.previewRecipe(
        html: webResult.html!,
        sourceUrl: webResult.sourceUrl,
      );

      if (!mounted) return;

      if (preview == null) {
        setState(() {
          _extractionError = 'This page doesn\'t appear to contain recipe information.\n\nTry sharing a page that includes a recipe.';
          _errorType = _ExtractionErrorType.noRecipeDetected;
          _modalState = _ModalState.extractionError;
        });
        return;
      }

      // Increment usage counter
      final usageService = await ref.read(previewUsageServiceProvider.future);
      await usageService.incrementShareRecipeUsage();

      // Update modal state
      if (mounted) {
        setState(() {
          _modalState = _ModalState.showingRecipePreview;
        });
      }

      // Show preview as bottom sheet
      if (mounted) {
        _showWebPreviewBottomSheet(context, preview);
      }
    } on WebExtractionException catch (e) {
      if (!mounted) return;
      setState(() {
        _extractionError = e.message;
        _errorType = _ExtractionErrorType.generic;
        _modalState = _ModalState.extractionError;
      });
    } catch (e) {
      AppLogger.error('Web preview extraction failed', e);
      if (!mounted) return;
      setState(() {
        _extractionError = 'Something went wrong while importing.';
        _errorType = _ExtractionErrorType.generic;
        _modalState = _ModalState.extractionError;
      });
    }
  }

  /// Perform full recipe extraction for Plus users
  Future<void> _performFullRecipeExtraction() async {
    if (_extractedContent == null || !_extractedContent!.hasContent) {
      setState(() {
        _extractionError = 'We couldn\'t find any content to extract from this post.';
        _errorType = _ExtractionErrorType.noContentExtracted;
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
          _extractionError = 'This post doesn\'t appear to contain recipe information.\n\nTry sharing a post that includes ingredients or cooking steps in the caption.';
          _errorType = _ExtractionErrorType.noRecipeDetected;
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
        _errorType = _ExtractionErrorType.generic;
        _modalState = _ModalState.extractionError;
      });
    } catch (e) {
      AppLogger.error('Recipe extraction failed', e);
      if (!mounted) return;
      setState(() {
        _extractionError = 'Something went wrong while importing.';
        _errorType = _ExtractionErrorType.generic;
        _modalState = _ModalState.extractionError;
      });
    }
  }

  /// Perform preview extraction for non-Plus users
  Future<void> _performRecipePreviewExtraction() async {
    if (_extractedContent == null || !_extractedContent!.hasContent) {
      setState(() {
        _extractionError = 'We couldn\'t find any content to extract from this post.';
        _errorType = _ExtractionErrorType.noContentExtracted;
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
          _extractionError = 'This post doesn\'t appear to contain recipe information.\n\nTry sharing a post that includes ingredients or cooking steps in the caption.';
          _errorType = _ExtractionErrorType.noRecipeDetected;
          _modalState = _ModalState.extractionError;
        });
        return;
      }

      // Increment usage counter
      final usageService = await ref.read(previewUsageServiceProvider.future);
      await usageService.incrementShareRecipeUsage();

      // Update modal state to empty (preview sheet covers it, but prevents flash of spinner if sheet moves)
      if (mounted) {
        setState(() {
          _modalState = _ModalState.showingRecipePreview;
        });
      }

      // Show preview as bottom sheet (keep original modal open for valid context chain)
      if (mounted) {
        _showPreviewBottomSheet(context, preview);
      }
    } on ShareExtractionException catch (e) {
      if (!mounted) return;
      setState(() {
        _extractionError = e.message;
        _errorType = _ExtractionErrorType.generic;
        _modalState = _ModalState.extractionError;
      });
    } catch (e) {
      AppLogger.error('Recipe preview failed', e);
      if (!mounted) return;
      setState(() {
        _extractionError = 'Something went wrong while importing.';
        _errorType = _ExtractionErrorType.generic;
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
    if (host.contains('youtube') || host.contains('youtu.be')) return 'youtube';
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
              onPressed: () {
                // Close preview sheet
                Navigator.of(sheetContext, rootNavigator: true).pop();
                // Also close the share modal behind it
                widget.onClose();
              },
            ),
          ),
          child: ShareRecipePreviewResultContent(
            preview: preview,
            onSubscribe: () async {
              // Don't close the preview sheet - paywall will cover it
              // Use the widget's context (share modal is still open behind the preview sheet)
              if (!context.mounted) return;

              // Present paywall using the share modal's context
              final purchased = await ref
                  .read(subscriptionProvider.notifier)
                  .presentPaywall(context);

              if (purchased && context.mounted) {
                // Close preview sheet and share modal
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext, rootNavigator: true).pop();
                }
                widget.onClose();

                // Perform full extraction
                final rootContext = globalRootNavigatorKey.currentContext;
                if (rootContext != null && rootContext.mounted) {
                  await _performPostSubscriptionExtraction(rootContext);
                }
              }
              // If not purchased, preview sheet stays visible (user can try again or close)
            },
          ),
        ),
      ],
    );
  }

  /// Shows preview bottom sheet for web extractions (AI-required recipes only).
  ///
  /// When user subscribes, performs backend extraction to get full recipe.
  void _showWebPreviewBottomSheet(
    BuildContext context,
    RecipePreview preview,
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
                // Close preview sheet
                Navigator.of(sheetContext, rootNavigator: true).pop();
                // Also close the share modal behind it
                widget.onClose();
              },
            ),
          ),
          child: ShareRecipePreviewResultContent(
            preview: preview,
            source: RecipePreviewSource.socialShare,
            onSubscribe: () async {
              if (!context.mounted) return;

              final purchased = await ref
                  .read(subscriptionProvider.notifier)
                  .presentPaywall(context);

              if (purchased && context.mounted) {
                // Close modals first, then extract via backend
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext, rootNavigator: true).pop();
                }
                widget.onClose();

                final rootContext = globalRootNavigatorKey.currentContext;
                if (rootContext != null && rootContext.mounted) {
                  await _performPostWebSubscriptionExtraction(rootContext);
                }
              }
              // If not purchased, preview sheet stays visible (user can try again or close)
            },
          ),
        ),
      ],
    );
  }

  /// Perform full recipe extraction after user subscribes from preview sheet.
  ///
  /// Shows its own modal for progress/errors since the original share modal
  /// was already closed when we showed the preview sheet.
  Future<void> _performPostSubscriptionExtraction(BuildContext context) async {
    // Capture the extracted content before showing modal
    final extractedContent = _extractedContent;
    if (extractedContent == null || !extractedContent.hasContent) {
      // No content - show error briefly
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No content available to extract.')),
        );
      }
      return;
    }

    // State for the extraction modal
    var isExtracting = true;
    String? errorMessage;

    // Show extraction progress modal
    if (!context.mounted) return;

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
              // Start extraction on first build
              if (isExtracting && errorMessage == null) {
                // Use Future.microtask to avoid calling setState during build
                Future.microtask(() async {
                  try {
                    final service = ref.read(shareExtractionServiceProvider);
                    final extractableUrl = _findExtractableUrl();
                    final sourcePlatform = _detectPlatform(extractableUrl);

                    final isInstagram = sourcePlatform == 'instagram';

                    final recipe = await service.extractRecipe(
                      ogTitle: extractedContent.title,
                      ogDescription:
                          isInstagram ? null : extractedContent.description,
                      sourceUrl: extractableUrl?.toString(),
                      sourcePlatform: sourcePlatform,
                    );

                    if (!modalContext.mounted) return;

                    if (recipe == null) {
                      setModalState(() {
                        isExtracting = false;
                        errorMessage =
                            'Unable to extract a recipe from this post.';
                      });
                      return;
                    }

                    // Download OG image if available
                    RecipeImage? coverImage;
                    final imageUrl = extractedContent.imageUrl;
                    if (imageUrl != null && imageUrl.isNotEmpty) {
                      coverImage = await _downloadAndSaveImage(imageUrl);
                    }

                    if (!modalContext.mounted) return;

                    // Success - close modal and open recipe editor
                    Navigator.of(modalContext, rootNavigator: true).pop();

                    if (context.mounted) {
                      final recipeEntry =
                          _convertToRecipeEntry(recipe, coverImage: coverImage);
                      showRecipeEditorModal(
                        context,
                        ref: ref,
                        recipe: recipeEntry,
                        isEditing: false,
                      );
                    }
                  } on ShareExtractionException catch (e) {
                    if (modalContext.mounted) {
                      setModalState(() {
                        isExtracting = false;
                        errorMessage = e.message;
                      });
                    }
                  } catch (e) {
                    AppLogger.error('Post-subscription extraction failed', e);
                    if (modalContext.mounted) {
                      setModalState(() {
                        isExtracting = false;
                        errorMessage = 'Failed to extract recipe. Please try again.';
                      });
                    }
                  }
                });
              }

              // Build UI based on state
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
                // Error state
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

  /// Performs full web extraction after user subscribes from preview.
  ///
  /// Shows its own modal for progress/errors since the original share modal
  /// was already closed when we showed the preview sheet.
  Future<void> _performPostWebSubscriptionExtraction(BuildContext context) async {
    final webResult = _webExtractionResult;
    if (webResult == null || !webResult.hasHtml) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No content available to extract.')),
        );
      }
      return;
    }

    // State for the extraction modal
    var isExtracting = true;
    String? errorMessage;

    // Show extraction progress modal
    if (!context.mounted) return;

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
                    final service = ref.read(webExtractionServiceProvider);
                    final recipe = await service.extractRecipe(
                      html: webResult.html!,
                      sourceUrl: webResult.sourceUrl,
                    );

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
                    final imageUrl = webResult.imageUrl;
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
                    AppLogger.error('Post-subscription web extraction failed', e);
                    if (modalContext.mounted) {
                      setModalState(() {
                        isExtracting = false;
                        errorMessage = 'Failed to extract recipe. Please try again.';
                      });
                    }
                  }
                });
              }

              // Build UI based on state
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
                // Error state
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
      // Also check text items for URLs (YouTube shares come as text)
      if (item.isText && item.text != null) {
        final text = item.text!.trim();
        if (text.startsWith('http://') || text.startsWith('https://')) {
          sourceUrl = text;
          break;
        }
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
        } else if (host.contains('youtube') || host.contains('youtu.be')) {
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

      // Limit title to 50 chars, preferring word boundaries when possible
      const maxTitleLength = 50;
      const minTitleLength = 25;

      if (firstLine.length > maxTitleLength) {
        String titleResult;
        String truncatedPart;
        bool truncatedMidWord;

        // Find last space at or before max length position
        final lastSpaceIndex = firstLine.lastIndexOf(' ', maxTitleLength - 1);

        if (lastSpaceIndex >= minTitleLength) {
          // Good word boundary found - truncate there
          titleResult = firstLine.substring(0, lastSpaceIndex).trimRight();
          truncatedPart = firstLine.substring(lastSpaceIndex + 1).trimLeft();
          truncatedMidWord = false;
        } else {
          // No good boundary (CJK text, very long first word, or would be too short)
          // Fall back to character truncation at max length
          titleResult = firstLine.substring(0, maxTitleLength);
          truncatedPart = firstLine.substring(maxTitleLength);
          truncatedMidWord = true;
        }

        title = titleResult.isNotEmpty ? titleResult : null;

        // Build body - ellipsis prefix only if we cut mid-word
        final prefix = truncatedMidWord ? '...' : '';
        if (truncatedPart.isNotEmpty) {
          if (remainder.isNotEmpty) {
            bodyText = '$prefix$truncatedPart\n\n$remainder';
          } else {
            bodyText = '$prefix$truncatedPart';
          }
        } else {
          bodyText = remainder.isNotEmpty ? remainder : null;
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
  ///
  /// If [recipe] is provided (from JSON-LD extraction), formats the
  /// ingredients and steps as readable text in the clipping body.
  String _buildQuillDelta(_ClippingContent content, {ExtractedRecipe? recipe}) {
    final ops = <Map<String, dynamic>>[];

    // Body text (if any)
    if (content.bodyText != null && content.bodyText!.isNotEmpty) {
      ops.add({'insert': '${content.bodyText}\n\n'});
    }

    // If we have JSON-LD recipe data, format ingredients and steps
    if (recipe != null) {
      // Ingredients section
      final ingredients = recipe.ingredients.where((i) => i.isIngredient).toList();
      if (ingredients.isNotEmpty) {
        ops.add({
          'insert': 'Ingredients',
          'attributes': {'bold': true},
        });
        ops.add({'insert': '\n'});
        for (final ingredient in ingredients) {
          ops.add({'insert': '• ${ingredient.name}\n'});
        }
        ops.add({'insert': '\n'});
      }

      // Instructions section
      final steps = recipe.steps.where((s) => s.isStep).toList();
      if (steps.isNotEmpty) {
        ops.add({
          'insert': 'Instructions',
          'attributes': {'bold': true},
        });
        ops.add({'insert': '\n'});
        for (var i = 0; i < steps.length; i++) {
          ops.add({'insert': '${i + 1}. ${steps[i].text}\n'});
        }
        ops.add({'insert': '\n'});
      }
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

      // Get household ID if available (user may not be authenticated or in a household)
      String? householdId;
      try {
        final householdState = ref.read(householdNotifierProvider);
        householdId = householdState.currentHousehold?.id;
      } catch (_) {
        // User not authenticated or no household - that's fine, clippings don't require it
        householdId = null;
      }

      // Pass JSON-LD recipe data if available for richer clipping content
      final jsonLdRecipe = _webExtractionResult?.recipe;
      final quillContent = _buildQuillDelta(content, recipe: jsonLdRecipe);

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
          _extractionError = 'We couldn\'t save this clipping. Please try again.';
          _errorType = _ExtractionErrorType.clippingSaveFailed;
          _modalState = _ModalState.extractionError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show buttons immediately - don't wait for session to load
    // If session fails to load after user taps, we'll show error then

    // Staged animation approach:
    // 1. AnimatedOpacity handles fade out/in (controlled by _isTransitioningOut)
    // 2. AnimatedSize handles modal size changes (triggered when _modalState changes)
    //
    // The key insight: we delay _modalState change until AFTER fade-out completes,
    // so AnimatedSize only sees the new size after content is invisible.
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

  /// Build the content for the current modal state
  Widget _buildStateContent(BuildContext context) {
    switch (_modalState) {
      case _ModalState.choosingAction:
        return _buildChoosingActionState(context);
      case _ModalState.extractingContent:
        return _buildExtractingState(context);
      case _ModalState.extractionError:
        return _buildExtractionErrorState(context);
      case _ModalState.extractingRecipe:
        return _buildExtractingRecipeState(context);
      case _ModalState.extractingPhotoRecipe:
        return _buildExtractingPhotoRecipeState(context);
      case _ModalState.showingRecipePreview:
        // This state is no longer used - we show a bottom sheet instead
        // Keep case to satisfy exhaustiveness check
        return const SizedBox.shrink();
      case _ModalState.savingClipping:
        return _buildSavingClippingState(context);
    }
  }

  Widget _buildChoosingActionState(BuildContext context) {
    final hasImages = _hasImagesForPhotoImport;

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

          // Photo import button (shown when images are shared)
          if (hasImages) ...[
            _ActionButton(
              icon: Icons.photo_camera_outlined,
              title: 'Import from Photo',
              description: 'Extract recipe from cookbook or food photo',
              emphasized: true,
              onTap: _onPhotoImportTap,
            ),
            SizedBox(height: AppSpacing.md),
          ],

          // Import Recipe button (for URL-based extraction)
          if (!hasImages)
            _ActionButton(
              icon: Icons.restaurant_menu,
              title: 'Import Recipe',
              description: 'Extract ingredients and steps to create a new recipe',
              emphasized: true,
              onTap: () => _onActionTap(_ModalAction.importRecipe),
            ),

          // Save as Clipping button (hidden for image/video only shares)
          if (_showClippingOption) ...[
            if (!hasImages) SizedBox(height: AppSpacing.md),
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

  /// Handle photo import button tap
  Future<void> _onPhotoImportTap() async {
    // Transition to photo extraction state
    await _transitionToState(_ModalState.extractingPhotoRecipe);

    // Process photo import
    await _handlePhotoImport();
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

  Widget _buildExtractionErrorState(BuildContext context) {
    final colors = AppColors.of(context);

    // Determine title based on error type
    final title = switch (_errorType) {
      _ExtractionErrorType.noRecipeDetected => 'No Recipe Found',
      _ExtractionErrorType.noContentExtracted => 'Couldn\'t Read Post',
      _ExtractionErrorType.noConnectivity => 'No Connection',
      _ExtractionErrorType.sessionFailed => 'Something Went Wrong',
      _ExtractionErrorType.clippingSaveFailed => 'Couldn\'t Save',
      _ExtractionErrorType.generic => 'Import Failed',
    };

    // Only offer "Save as Clipping" for noRecipeDetected (when we got content but no recipe)
    final canSaveAsClipping = _errorType == _ExtractionErrorType.noRecipeDetected &&
        (_gatherClippingContent()?.hasContent ?? false);

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
                  title,
                  style: AppTypography.h4.copyWith(
                    color: colors.textPrimary,
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

          // Error message
          Text(
            _extractionError ?? 'Something went wrong.',
            style: AppTypography.body.copyWith(
              color: colors.textSecondary,
            ),
          ),

          SizedBox(height: AppSpacing.xl),

          // For noRecipeDetected: offer Save as Clipping
          // For all other errors: show Close button
          if (canSaveAsClipping)
            _ActionButton(
              icon: Icons.note_add_outlined,
              title: 'Save as Clipping',
              description: 'Save the link for later',
              onTap: _saveAsClipping,
            )
          else
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
                onPressed: widget.onClose,
                child: Text(
                  'Close',
                  style: AppTypography.body.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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

  Widget _buildExtractingPhotoRecipeState(BuildContext context) {
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
          _AnimatedLoadingText(
            messages: const [
              'Reading photo...',
              'Finding recipe...',
              'Extracting ingredients...',
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
