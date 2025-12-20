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
          SizedBox(height: AppSpacing.lg),

          // Session summary
          _SessionSummary(session: _session!),
          SizedBox(height: AppSpacing.lg),

          // Items list
          _ItemsList(session: _session!),
        ],
      ),
    );
  }
}

/// Session summary widget
class _SessionSummary extends StatelessWidget {
  final ShareSession session;

  const _SessionSummary({required this.session});

  @override
  Widget build(BuildContext context) {
    final itemCount = session.items.length;
    final sourceApp = session.sourceApp ?? 'Unknown';

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.of(context).border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shared from $sourceApp',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
            style: AppTypography.body.copyWith(
              color: AppColors.of(context).textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// List of shared items
class _ItemsList extends StatelessWidget {
  final ShareSession session;

  const _ItemsList({required this.session});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items',
          style: AppTypography.label.copyWith(
            color: AppColors.of(context).textSecondary,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        ...session.items.map((item) => _ShareItemTile(item: item)),
      ],
    );
  }
}

/// Individual share item tile
class _ShareItemTile extends StatelessWidget {
  final ShareSessionItem item;

  const _ShareItemTile({required this.item});

  IconData _getIcon() {
    if (item.isUrl) return Icons.link;
    if (item.isText) return Icons.text_fields;
    if (item.isImage) return Icons.image;
    if (item.isMovie) return Icons.movie;
    if (item.isData) return Icons.insert_drive_file;
    return Icons.help_outline;
  }

  String _getTitle() {
    if (item.title != null && item.title!.isNotEmpty) {
      return item.title!;
    }
    if (item.originalFileName != null) {
      return item.originalFileName!;
    }
    if (item.url != null) {
      return item.url!;
    }
    if (item.text != null && item.text!.isNotEmpty) {
      return item.text!.length > 50
          ? '${item.text!.substring(0, 50)}...'
          : item.text!;
    }
    return item.type;
  }

  String? _getSubtitle() {
    if (item.isFile && item.mimeType != null) {
      return item.mimeType;
    }
    if (item.isUrl && item.url != null) {
      return item.url;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _getSubtitle();

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.of(context).border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getIcon(),
            size: 24,
            color: AppColors.of(context).textSecondary,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(),
                  style: AppTypography.body.copyWith(
                    color: AppColors.of(context).textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.of(context).textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
