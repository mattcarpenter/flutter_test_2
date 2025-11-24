import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../providers/app_settings_provider.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_row.dart';

/// Sub-page for layout and appearance settings
class LayoutAppearancePage extends ConsumerWidget {
  const LayoutAppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final settingsState = ref.watch(appSettingsProvider);
    final settings = settingsState.settings;

    // Get display values
    final showFoldersLabel = _getShowFoldersLabel(
      settings.layout.showFolders,
      settings.layout.showFoldersCount,
    );
    final sortFoldersLabel = _getSortFoldersLabel(settings.layout.folderSortOption);
    final themeLabel = _getThemeLabel(settings.appearance.themeMode);
    final fontSizeLabel = _getFontSizeLabel(settings.appearance.recipeFontSize);

    return AdaptiveSliverPage(
      title: 'Layout & Appearance',
      automaticallyImplyLeading: true,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xl),

              // Recipes Page section
              SettingsGroup(
                header: 'Recipes Page',
                children: [
                  SettingsRow(
                    title: 'Show Folders',
                    subtitle: showFoldersLabel,
                    leading: Icon(
                      CupertinoIcons.folder,
                      size: 22,
                      color: colors.primary,
                    ),
                    isFirst: true,
                    isLast: false,
                    onTap: () {
                      context.push('/settings/layout-appearance/show-folders');
                    },
                  ),
                  SettingsRow(
                    title: 'Sort Folders',
                    subtitle: sortFoldersLabel,
                    leading: Icon(
                      CupertinoIcons.arrow_up_arrow_down,
                      size: 22,
                      color: colors.primary,
                    ),
                    isFirst: false,
                    isLast: true,
                    onTap: () {
                      context.push('/settings/layout-appearance/sort-folders');
                    },
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.xl),

              // Color Theme section
              SettingsGroup(
                header: 'Color Theme',
                children: [
                  SettingsRow(
                    title: 'Theme',
                    subtitle: themeLabel,
                    leading: Icon(
                      CupertinoIcons.circle_lefthalf_fill,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/layout-appearance/theme');
                    },
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.xl),

              // Recipes section
              SettingsGroup(
                header: 'Recipes',
                children: [
                  SettingsRow(
                    title: 'Font Size',
                    subtitle: fontSizeLabel,
                    leading: Icon(
                      CupertinoIcons.textformat_size,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/layout-appearance/font-size');
                    },
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

  String _getShowFoldersLabel(String showFolders, int count) {
    if (showFolders == 'firstN') {
      return 'First $count folders';
    }
    return 'All folders';
  }

  String _getSortFoldersLabel(String sortOption) {
    return switch (sortOption) {
      'alphabetical_asc' => 'Alphabetical (A-Z)',
      'alphabetical_desc' => 'Alphabetical (Z-A)',
      'newest' => 'Newest First',
      'oldest' => 'Oldest First',
      'custom' => 'Custom',
      _ => 'Alphabetical (A-Z)',
    };
  }

  String _getThemeLabel(String themeMode) {
    return switch (themeMode) {
      'light' => 'Light',
      'dark' => 'Dark',
      _ => 'System',
    };
  }

  String _getFontSizeLabel(String fontSize) {
    return switch (fontSize) {
      'small' => 'Small',
      'large' => 'Large',
      _ => 'Medium',
    };
  }
}
