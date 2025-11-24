import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../providers/app_settings_provider.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_row.dart';

/// Page for selecting which tab opens when app launches
class HomeScreenPage extends ConsumerWidget {
  const HomeScreenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final currentHomeScreen = ref.watch(homeScreenProvider);

    final options = [
      _HomeScreenOption(
        value: 'recipes',
        title: 'Recipes',
        icon: CupertinoIcons.book,
      ),
      _HomeScreenOption(
        value: 'shopping',
        title: 'Shopping',
        icon: CupertinoIcons.cart,
      ),
      _HomeScreenOption(
        value: 'meal_plans',
        title: 'Meal Plan',
        icon: CupertinoIcons.calendar,
      ),
      _HomeScreenOption(
        value: 'pantry',
        title: 'Pantry',
        icon: CupertinoIcons.cube_box,
      ),
    ];

    return AdaptiveSliverPage(
      title: 'Home Screen',
      automaticallyImplyLeading: true,
      previousPageTitle: 'Settings',
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xl),
              SettingsGroup(
                footer: 'Choose which tab opens when the app launches. Changes take effect on next app launch.',
                children: options.indexed.map((indexed) {
                  final (index, option) = indexed;
                  final isSelected = currentHomeScreen == option.value;

                  return SettingsRow(
                    title: option.title,
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
                      ref.read(appSettingsProvider.notifier).setHomeScreen(option.value);
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

class _HomeScreenOption {
  final String value;
  final String title;
  final IconData icon;

  const _HomeScreenOption({
    required this.value,
    required this.title,
    required this.icon,
  });
}
