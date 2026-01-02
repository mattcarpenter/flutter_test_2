import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../localization/l10n_extension.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/spacing.dart';
import '../providers/app_settings_provider.dart';
import '../widgets/settings_group_condensed.dart';
import '../widgets/settings_row_condensed.dart';

/// Page for selecting which tab opens when app launches
class HomeScreenPage extends ConsumerWidget {
  const HomeScreenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentHomeScreen = ref.watch(homeScreenProvider);

    final options = [
      _HomeScreenOption(
        value: 'recipes',
        title: context.l10n.settingsHomeScreenRecipes,
        icon: HugeIcons.strokeRoundedBook01,
      ),
      _HomeScreenOption(
        value: 'shopping',
        title: context.l10n.settingsHomeScreenShopping,
        icon: HugeIcons.strokeRoundedShoppingCart01,
      ),
      _HomeScreenOption(
        value: 'meal_plans',
        title: context.l10n.settingsHomeScreenMealPlan,
        icon: HugeIcons.strokeRoundedCalendar01,
      ),
      _HomeScreenOption(
        value: 'pantry',
        title: context.l10n.settingsHomeScreenPantry,
        icon: CupertinoIcons.cube_box,
      ),
    ];

    return AdaptiveSliverPage(
      title: context.l10n.settingsHomeScreen,
      automaticallyImplyLeading: true,
      previousPageTitle: context.l10n.settingsTitle,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xl),
              SettingsGroupCondensed(
                footer: context.l10n.settingsHomeScreenDescription,
                children: options.map((option) {
                  final isSelected = currentHomeScreen == option.value;

                  return SettingsSelectionRow(
                    title: option.title,
                    isSelected: isSelected,
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
  final dynamic icon; // HugeIcons return List<List<dynamic>>, IconData for Cupertino

  const _HomeScreenOption({
    required this.value,
    required this.title,
    required this.icon,
  });
}
