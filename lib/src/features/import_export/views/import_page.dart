import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../localization/l10n_extension.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/spacing.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../settings/widgets/settings_group_condensed.dart';
import '../services/import_service.dart';

/// Page for selecting import source
class ImportPage extends ConsumerWidget {
  const ImportPage({super.key});

  Future<void> _selectFile(BuildContext context, ImportSource source) async {
    // Paprika uses .paprikarecipes which iOS/macOS don't recognize with FileType.custom
    // Use FileType.any for Paprika to allow selecting the file
    final PlatformFile? file;

    if (source == ImportSource.paprika) {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      file = result?.files.single;

      // Validate extension for Paprika
      if (file != null && !file.path!.toLowerCase().endsWith('.paprikarecipes')) {
        if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder: (dialogContext) => CupertinoAlertDialog(
              title: Text(context.l10n.importInvalidFile),
              content: Text(context.l10n.importInvalidPaprikaFile),
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
        return;
      }
    } else {
      final allowedExtensions = switch (source) {
        ImportSource.stockpot => ['zip'],
        ImportSource.paprika => ['paprikarecipes'], // Not used, handled above
        ImportSource.crouton => ['zip'],
      };

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );
      file = result?.files.single;
    }

    if (file != null && file.path != null && context.mounted) {
      // Navigate to preview page
      context.push('/settings/import/preview', extra: {
        'filePath': file.path,
        'source': source.name,
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    return AdaptiveSliverPage(
      title: context.l10n.importTitle,
      automaticallyImplyLeading: true,
      previousPageTitle: context.l10n.settingsTitle,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.xl),

              // Import from section header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  context.l10n.importFromHeader,
                  style: AppTypography.h5.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              // Import source options
              SettingsGroupCondensed(
                children: [
                  _ImportSourceRow(
                    title: context.l10n.importSourceStockpot,
                    subtitle: context.l10n.importSourceStockpotDesc,
                    onTap: () => _selectFile(context, ImportSource.stockpot),
                  ),
                  _ImportSourceRow(
                    title: context.l10n.importSourcePaprika,
                    subtitle: context.l10n.importSourcePaprikaDesc,
                    onTap: () => _selectFile(context, ImportSource.paprika),
                  ),
                  _ImportSourceRow(
                    title: context.l10n.importSourceCrouton,
                    subtitle: context.l10n.importSourceCroutonDesc,
                    onTap: () => _selectFile(context, ImportSource.crouton),
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom row widget for import sources with title and subtitle stacked vertically
class _ImportSourceRow extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ImportSourceRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_ImportSourceRow> createState() => _ImportSourceRowState();
}

class _ImportSourceRowState extends State<_ImportSourceRow> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: _isPressed ? colors.surfaceVariant : colors.input,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.subtitle,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: colors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
