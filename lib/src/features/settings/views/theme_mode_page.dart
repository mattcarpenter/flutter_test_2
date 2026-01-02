import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../localization/l10n_extension.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/spacing.dart';
import '../providers/app_settings_provider.dart';
import '../widgets/settings_group_condensed.dart';
import '../widgets/settings_row_condensed.dart';

/// Page for selecting app theme mode (Light/Dark/Auto)
class ThemeModePage extends ConsumerWidget {
  const ThemeModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeStringProvider);

    final options = [
      _ThemeOption(
        value: 'light',
        title: context.l10n.settingsThemeLight,
        subtitle: context.l10n.settingsThemeLightDescription,
      ),
      _ThemeOption(
        value: 'dark',
        title: context.l10n.settingsThemeDark,
        subtitle: context.l10n.settingsThemeDarkDescription,
      ),
      _ThemeOption(
        value: 'auto',
        title: context.l10n.settingsThemeSystem,
        subtitle: context.l10n.settingsThemeSystemDescription,
      ),
    ];

    return AdaptiveSliverPage(
      title: context.l10n.settingsLayoutColorTheme,
      automaticallyImplyLeading: true,
      previousPageTitle: context.l10n.settingsLayoutAppearance,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xl),
              SettingsGroupCondensed(
                children: options.map((option) {
                  final isSelected = currentTheme == option.value;

                  return SettingsSelectionRow(
                    title: option.title,
                    subtitle: option.subtitle,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(appSettingsProvider.notifier).setThemeMode(option.value);
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeOption {
  final String value;
  final String title;
  final String subtitle;

  const _ThemeOption({
    required this.value,
    required this.title,
    required this.subtitle,
  });
}
