import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../services/content_extraction/content_extractor.dart';
import '../../../services/logging/app_logger.dart';
import '../../../services/share_session_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_circle_button.dart';
import '../models/og_extracted_content.dart';

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
}

/// The action the user chose
enum _ModalAction {
  importRecipe,
  saveAsClipping,
}

/// Main content when session is loaded
class _ShareSessionLoaded extends StatefulWidget {
  final String sessionId;
  final ShareSessionService service;
  final VoidCallback onClose;

  const _ShareSessionLoaded({
    required this.sessionId,
    required this.service,
    required this.onClose,
  });

  @override
  State<_ShareSessionLoaded> createState() => _ShareSessionLoadedState();
}

class _ShareSessionLoadedState extends State<_ShareSessionLoaded> {
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
      _extractionFuture = _extractor.extract(extractableUrl);
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
      // Always show spinner first - keeps UX consistent
      _modalState = _ModalState.extractingContent;
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

      // Step 1: Await OG extraction if we started one
      // If extraction completed before button tap, this returns immediately
      OGExtractedContent? content;
      if (_extractionFuture != null) {
        content = await _extractionFuture;
      }

      if (!mounted) return;

      // Step 2: (Future) Additional processing like OpenAI structuring would go here
      // e.g., final recipe = await _structureWithAI(content);

      // Step 3: Handle result
      if (content != null && content.hasContent) {
        AppLogger.info('OG extraction successful: ${content.title}');
        setState(() {
          _extractedContent = content;
          _modalState = _ModalState.showingPreview;
        });
      } else if (_extractionFuture != null) {
        // Had an extractable URL but extraction failed/returned empty
        AppLogger.warning('OG extraction returned no content');
        setState(() {
          _extractionError = 'No content could be extracted from this link.';
          _modalState = _ModalState.extractionError;
        });
      } else {
        // No extractable URL, proceed directly
        _proceedWithAction();
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

  /// Proceed with the chosen action (future implementation)
  void _proceedWithAction() {
    // TODO: Implement actual recipe import or clipping save
    AppLogger.info(
      'Proceeding with action: $_chosenAction, extracted: ${_extractedContent?.title}',
    );
    widget.onClose();
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
