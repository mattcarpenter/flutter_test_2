import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../localization/l10n_extension.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../services/logging/app_logger.dart';
import '../../settings/widgets/settings_group_condensed.dart';
import '../../settings/widgets/settings_row_condensed.dart';
import '../providers/import_export_provider.dart';

/// Page for exporting recipes to Stockpot ZIP format
class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({super.key});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return AdaptiveSliverPage(
      title: context.l10n.exportTitle,
      automaticallyImplyLeading: true,
      previousPageTitle: context.l10n.settingsTitle,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.xl),

              // Export Options section
              SettingsGroupCondensed(
                header: context.l10n.exportOptionsHeader,
                children: [
                  SettingsRowCondensed(
                    title: context.l10n.exportAllRecipes,
                    leading: Icon(
                      CupertinoIcons.square_arrow_down,
                      size: 22,
                      color: _isExporting ? colors.textTertiary : colors.primary,
                    ),
                    value: _isExporting ? context.l10n.exportExporting : null,
                    enabled: !_isExporting,
                    onTap: _isExporting ? null : _exportAllRecipes,
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.settingsGroupGap),

              // Future export options placeholder
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg + AppSpacing.sm),
                child: Text(
                  context.l10n.exportComingSoon,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),

              // Bottom spacing
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _exportAllRecipes() async {
    AppLogger.info('Starting export all recipes');

    // Show loading state
    setState(() => _isExporting = true);

    try {
      // Get recipes from the export provider
      final recipesAsync = await ref.read(exportRecipesProvider.future);

      if (recipesAsync.isEmpty) {
        if (mounted) {
          _showAlert(
            context,
            title: context.l10n.exportNoRecipes,
            message: context.l10n.exportNoRecipesMessage,
          );
        }
        return;
      }

      AppLogger.info('Exporting ${recipesAsync.length} recipes');

      // Get export service and create the archive
      final exportService = ref.read(exportServiceProvider);
      final file = await exportService.exportRecipes(
        recipes: recipesAsync,
        onProgress: (current, total) {
          AppLogger.debug('Export progress: $current/$total');
        },
      );

      AppLogger.info('Export file created: ${file.path}');

      if (!mounted) return;

      // Get the position for iPad/macOS share popover
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      // Share the file
      final shareResult = await Share.shareXFiles(
        [XFile(file.path)],
        subject: context.l10n.exportShareSubject,
        sharePositionOrigin: sharePositionOrigin,
      );

      AppLogger.info('Export completed successfully, share status: ${shareResult.status}');

      // Show success message if share was successful or dismissed
      // (dismissed means user saw the share sheet but cancelled - file was still created)
      if (mounted && shareResult.status != ShareResultStatus.unavailable) {
        _showAlert(
          context,
          title: context.l10n.exportComplete,
          message: context.l10n.exportSuccessMessage(recipesAsync.length),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to export recipes', e, stackTrace);

      if (mounted) {
        _showAlert(
          context,
          title: context.l10n.exportFailed,
          message: context.l10n.exportFailedMessage(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showAlert(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.commonOk),
          ),
        ],
      ),
    );
  }
}
