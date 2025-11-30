import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/spacing.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../settings/widgets/settings_group_condensed.dart';
import '../../settings/widgets/settings_row_condensed.dart';
import '../services/import_service.dart';

/// Page for selecting import source
class ImportPage extends ConsumerWidget {
  const ImportPage({super.key});

  Future<void> _selectFile(BuildContext context, ImportSource source) async {
    // Determine file extensions based on source
    final allowedExtensions = switch (source) {
      ImportSource.stockpot => ['zip'],
      ImportSource.paprika => ['paprikarecipes'],
      ImportSource.crouton => ['zip'],
    };

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result != null && result.files.single.path != null && context.mounted) {
      // Navigate to preview page
      context.push('/settings/import/preview', extra: {
        'filePath': result.files.single.path,
        'source': source.name,
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    return AdaptiveSliverPage(
      title: 'Import Recipes',
      automaticallyImplyLeading: true,
      previousPageTitle: 'Settings',
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
                  'Import from:',
                  style: AppTypography.h5.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              // Import source options
              SettingsGroupCondensed(
                children: [
                  SettingsRowCondensed(
                    title: 'Stockpot Export',
                    value: 'Import from a previous backup',
                    showChevron: false,
                    onTap: () => _selectFile(context, ImportSource.stockpot),
                  ),
                  SettingsRowCondensed(
                    title: 'Paprika',
                    value: 'Import from Paprika Recipe Manager',
                    showChevron: false,
                    onTap: () => _selectFile(context, ImportSource.paprika),
                  ),
                  SettingsRowCondensed(
                    title: 'Crouton',
                    value: 'Import from Crouton app',
                    showChevron: false,
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
