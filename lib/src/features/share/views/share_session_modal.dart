import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import '../../../services/logging/app_logger.dart';
import '../../../services/share_session_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_circle_button.dart';

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
  bool _isLoading = true;

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
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.error('Failed to load share session', e, stack);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
      if (item.originalFileName != null) AppLogger.info('  Original File Name: ${item.originalFileName}');
      if (item.mimeType != null) AppLogger.info('  MIME Type: ${item.mimeType}');
      if (item.sizeBytes != null) AppLogger.info('  Size: ${item.sizeBytes} bytes');
      if (item.uniformTypeIdentifier != null) AppLogger.info('  UTI: ${item.uniformTypeIdentifier}');
    }
    AppLogger.info('=== END SHARE SESSION ===');
  }

  /// Returns true if clipping option should be shown.
  /// Hidden when only images or videos (files) are shared.
  bool get _showClippingOption {
    if (_session == null) return false;
    // Show clipping option if there's at least one item that's not an image/movie file
    return _session!.items.any((item) => !item.isImage && !item.isMovie);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _LoadingState(onClose: widget.onClose);
    }

    if (_session == null) {
      return _ErrorState(
        error: 'Session not found',
        onClose: widget.onClose,
      );
    }

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
            onTap: () {
              // TODO: Implement recipe import flow
              widget.onClose();
            },
          ),

          // Save as Clipping button (hidden for image/video only shares)
          if (_showClippingOption) ...[
            SizedBox(height: AppSpacing.md),
            _ActionButton(
              icon: Icons.note_add_outlined,
              title: 'Save as Clipping',
              description: 'Save for later and convert to a recipe when ready',
              onTap: () {
                // TODO: Implement clipping save flow
                widget.onClose();
              },
            ),
          ],
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
