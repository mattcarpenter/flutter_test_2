import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        title: 'Light',
        subtitle: 'Always use light appearance',
      ),
      _ThemeOption(
        value: 'dark',
        title: 'Dark',
        subtitle: 'Always use dark appearance',
      ),
      _ThemeOption(
        value: 'auto',
        title: 'System',
        subtitle: 'Match device appearance',
      ),
    ];

    return AdaptiveSliverPage(
      title: 'Color Theme',
      automaticallyImplyLeading: true,
      previousPageTitle: 'Layout',
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
