import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../database/database.dart';
import '../../../../database/models/ingredients.dart';
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
      // For Import Recipe, show the final "Importing Recipe" spinner immediately
      // For other actions, show the content extraction spinner
      _modalState = action == _ModalAction.importRecipe
          ? _ModalState.extractingRecipe
          : _ModalState.extractingContent;
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
      if (_extractedContent != null && _extractedContent!.hasContent) {
        AppLogger.info('OG extraction successful');

        // For Import Recipe, proceed to API call (spinner already showing)
        if (_chosenAction == _ModalAction.importRecipe) {
          await _handleImportRecipe();
        } else {
          // For clippings, show the preview state
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
    } else {
      // TODO: Implement clipping save
      AppLogger.info(
        'Proceeding with clipping save: ${_extractedContent?.title}',
      );
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

      final recipe = await service.extractRecipe(
        ogTitle: _extractedContent!.title,
        ogDescription: _extractedContent!.description,
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

      // Success - close modal and open recipe editor
      widget.onClose();

      if (context.mounted) {
        final recipeEntry = _convertToRecipeEntry(recipe);
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

      final preview = await service.previewRecipe(
        ogTitle: _extractedContent!.title,
        ogDescription: _extractedContent!.description,
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

  /// Convert ExtractedRecipe to RecipeEntry for the editor
  RecipeEntry _convertToRecipeEntry(ExtractedRecipe extracted) {
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
      folderIds: [],
      pinned: 0,
      pinnedAt: null,
    );
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
