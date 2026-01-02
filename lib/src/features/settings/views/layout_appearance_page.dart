import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:go_router/go_router.dart';

import '../../../localization/l10n_extension.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../providers/app_settings_provider.dart';
import '../widgets/settings_group_condensed.dart';
import '../widgets/settings_row_condensed.dart';

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
      context,
      settings.layout.showFolders,
      settings.layout.showFoldersCount,
    );
    final sortFoldersLabel = _getSortFoldersLabel(context, settings.layout.folderSortOption);
    final themeLabel = _getThemeLabel(context, settings.appearance.themeMode);
    final fontSizeLabel = _getFontSizeLabel(context, settings.appearance.recipeFontSize);

    return AdaptiveSliverPage(
      title: context.l10n.settingsLayoutAppearance,
      automaticallyImplyLeading: true,
      previousPageTitle: context.l10n.settingsTitle,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xl),

              // Recipes Page section
              SettingsGroupCondensed(
                header: context.l10n.settingsLayoutRecipesPage,
                children: [
                  SettingsRowCondensed(
                    title: context.l10n.settingsLayoutShowFolders,
                    value: showFoldersLabel,
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedFolder01,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/layout-appearance/show-folders');
                    },
                  ),
                  SettingsRowCondensed(
                    title: context.l10n.settingsLayoutSortFolders,
                    value: sortFoldersLabel,
                    leading: Icon(
                      CupertinoIcons.arrow_up_arrow_down,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/layout-appearance/sort-folders');
                    },
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.settingsGroupGap),

              // Color Theme section
              SettingsGroupCondensed(
                header: context.l10n.settingsLayoutAppearanceSection,
                children: [
                  SettingsRowCondensed(
                    title: context.l10n.settingsLayoutColorTheme,
                    value: themeLabel,
                    leading: Icon(
                      CupertinoIcons.circle_lefthalf_fill,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/layout-appearance/theme');
                    },
                  ),
                  SettingsRowCondensed(
                    title: context.l10n.settingsLayoutRecipeFontSize,
                    value: fontSizeLabel,
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedTextFont,
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

  String _getShowFoldersLabel(BuildContext context, String showFolders, int count) {
    if (showFolders == 'firstN') {
      return context.l10n.settingsShowFoldersFirst(count);
    }
    return context.l10n.settingsShowFoldersAll;
  }

  String _getSortFoldersLabel(BuildContext context, String sortOption) {
    return switch (sortOption) {
      'alphabetical_asc' => context.l10n.settingsSortFoldersAlphaAZ,
      'alphabetical_desc' => context.l10n.settingsSortFoldersAlphaZA,
      'newest' => context.l10n.settingsSortFoldersNewest,
      'oldest' => context.l10n.settingsSortFoldersOldest,
      'custom' => context.l10n.settingsSortFoldersCustom,
      _ => context.l10n.settingsSortFoldersAlphaAZ,
    };
  }

  String _getThemeLabel(BuildContext context, String themeMode) {
    return switch (themeMode) {
      'light' => context.l10n.settingsThemeLight,
      'dark' => context.l10n.settingsThemeDark,
      _ => context.l10n.settingsThemeSystem,
    };
  }

  String _getFontSizeLabel(BuildContext context, String fontSize) {
    return switch (fontSize) {
      'small' => context.l10n.settingsFontSizeSmall,
      'large' => context.l10n.settingsFontSizeLarge,
      _ => context.l10n.settingsFontSizeMedium,
    };
  }
}
