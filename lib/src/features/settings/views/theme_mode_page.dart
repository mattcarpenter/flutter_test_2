import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../providers/app_settings_provider.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_row.dart';

/// Page for selecting app theme mode (Light/Dark/Auto)
class ThemeModePage extends ConsumerWidget {
  const ThemeModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final currentTheme = ref.watch(themeModeStringProvider);

    final options = [
      _ThemeOption(
        value: 'light',
        title: 'Light',
        subtitle: 'Always use light appearance',
        icon: CupertinoIcons.sun_max,
      ),
      _ThemeOption(
        value: 'dark',
        title: 'Dark',
        subtitle: 'Always use dark appearance',
        icon: CupertinoIcons.moon,
      ),
      _ThemeOption(
        value: 'auto',
        title: 'System',
        subtitle: 'Match device appearance',
        icon: CupertinoIcons.device_phone_portrait,
      ),
    ];

    return AdaptiveSliverPage(
      title: 'Color Theme',
      automaticallyImplyLeading: true,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xl),
              SettingsGroup(
                children: options.indexed.map((indexed) {
                  final (index, option) = indexed;
                  final isSelected = currentTheme == option.value;

                  return SettingsRow(
                    title: option.title,
                    subtitle: option.subtitle,
                    leading: Icon(
                      option.icon,
                      size: 22,
                      color: colors.primary,
                    ),
                    trailing: isSelected
                        ? Icon(
                            CupertinoIcons.checkmark,
                            color: colors.primary,
                            size: 20,
                          )
                        : null,
                    showChevron: false,
                    isFirst: index == 0,
                    isLast: index == options.length - 1,
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
  final IconData icon;

  const _ThemeOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
