import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../providers/app_settings_provider.dart';
import '../widgets/settings_group_condensed.dart';
import '../widgets/settings_row_condensed.dart';

/// Page for configuring how many folders to show on the recipes page
class ShowFoldersPage extends ConsumerWidget {
  const ShowFoldersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final showFolders = ref.watch(showFoldersProvider);
    final showFoldersCount = ref.watch(showFoldersCountProvider);

    return AdaptiveSliverPage(
      title: 'Show Folders',
      automaticallyImplyLeading: true,
      previousPageTitle: 'Layout',
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xl),

              // Options group
              SettingsGroupCondensed(
                children: [
                  SettingsSelectionRow(
                    title: 'All folders',
                    isSelected: showFolders == 'all',
                    onTap: () {
                      ref.read(appSettingsProvider.notifier).setShowFolders('all');
                    },
                  ),
                  SettingsSelectionRow(
                    title: 'First N folders',
                    isSelected: showFolders == 'firstN',
                    onTap: () {
                      ref.read(appSettingsProvider.notifier).setShowFolders('firstN');
                    },
                  ),
                ],
              ),

              // Number picker when "First N" is selected
              if (showFolders == 'firstN') ...[
                SizedBox(height: AppSpacing.lg),
                SettingsGroupCondensed(
                  header: 'Number of Folders',
                  footer: 'Show this many folders on the recipes page.',
                  children: [
                    _FolderCountPicker(
                      count: showFoldersCount,
                      onChanged: (value) {
                        ref.read(appSettingsProvider.notifier).setShowFoldersCount(value);
                      },
                    ),
                  ],
                ),
              ],

              SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }
}

/// Number picker widget for folder count
class _FolderCountPicker extends StatelessWidget {
  final int count;
  final ValueChanged<int> onChanged;

  const _FolderCountPicker({
    required this.count,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Decrement button
          GestureDetector(
            onTap: count > 3 ? () => onChanged(count - 1) : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: count > 3 ? colors.primary : colors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                CupertinoIcons.minus,
                color: count > 3 ? CupertinoColors.white : colors.textDisabled,
                size: 20,
              ),
            ),
          ),

          SizedBox(width: AppSpacing.xl),

          // Count display
          SizedBox(
            width: 48,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: AppTypography.h3.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),

          SizedBox(width: AppSpacing.xl),

          // Increment button
          GestureDetector(
            onTap: count < 20 ? () => onChanged(count + 1) : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: count < 20 ? colors.primary : colors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                CupertinoIcons.plus,
                color: count < 20 ? CupertinoColors.white : colors.textDisabled,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
