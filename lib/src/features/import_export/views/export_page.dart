import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

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
      title: 'Export Recipes',
      automaticallyImplyLeading: true,
      previousPageTitle: 'Settings',
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.xl),

              // Export Options section
              SettingsGroupCondensed(
                header: 'Export Options',
                children: [
                  SettingsRowCondensed(
                    title: 'Export All Recipes',
                    leading: Icon(
                      CupertinoIcons.square_arrow_down,
                      size: 22,
                      color: _isExporting ? colors.textTertiary : colors.primary,
                    ),
                    value: _isExporting ? 'Exporting...' : null,
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
                  'Additional export formats (HTML, PDF, etc.) coming soon.',
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
            title: 'No Recipes',
            message: 'You don\'t have any recipes to export.',
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
        subject: 'My Recipes Export',
        sharePositionOrigin: sharePositionOrigin,
      );

      AppLogger.info('Export completed successfully, share status: ${shareResult.status}');

      // Show success message if share was successful or dismissed
      // (dismissed means user saw the share sheet but cancelled - file was still created)
      if (mounted && shareResult.status != ShareResultStatus.unavailable) {
        _showAlert(
          context,
          title: 'Export Complete',
          message: 'Successfully exported ${recipesAsync.length} ${recipesAsync.length == 1 ? 'recipe' : 'recipes'}.',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to export recipes', e, stackTrace);

      if (mounted) {
        _showAlert(
          context,
          title: 'Export Failed',
          message: 'Failed to export recipes: $e',
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
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
