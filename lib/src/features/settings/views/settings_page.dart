import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/spacing.dart';
import '../../../theme/colors.dart';
import '../providers/app_settings_provider.dart';
import '../widgets/settings_group_condensed.dart';
import '../widgets/settings_row_condensed.dart';

class SettingsPage extends ConsumerWidget {
  final VoidCallback? onMenuPressed;

  const SettingsPage({super.key, this.onMenuPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuButton = onMenuPressed != null
        ? GestureDetector(
            onTap: onMenuPressed,
            child: const HugeIcon(icon: HugeIcons.strokeRoundedMenu01),
          )
        : null;

    final colors = AppColors.of(context);
    final settingsState = ref.watch(appSettingsProvider);
    final settings = settingsState.settings;

    // Get display values for current settings
    final homeScreenLabel = _getHomeScreenLabel(settings.homeScreen);

    return AdaptiveSliverPage(
      title: 'Settings',
      leading: menuButton,
      automaticallyImplyLeading: onMenuPressed == null,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.xl),

              // Home Screen section
              SettingsGroupCondensed(
                children: [
                  SettingsRowCondensed(
                    title: 'Home Screen',
                    value: homeScreenLabel,
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedHome01,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/home-screen');
                    },
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.settingsGroupGap),

              // Layout & Appearance section
              SettingsGroupCondensed(
                children: [
                  SettingsRowCondensed(
                    title: 'Layout & Appearance',
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedPaintBrush01,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/layout-appearance');
                    },
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.settingsGroupGap),

              // Manage Tags section
              SettingsGroupCondensed(
                children: [
                  SettingsRowCondensed(
                    title: 'Manage Tags',
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedTag01,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/tags');
                    },
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.settingsGroupGap),

              // Account section
              SettingsGroupCondensed(
                children: [
                  SettingsRowCondensed(
                    title: 'Account',
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedUserCircle,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/account');
                    },
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.settingsGroupGap),

              // Import/Export section
              SettingsGroupCondensed(
                children: [
                  SettingsRowCondensed(
                    title: 'Import Recipes',
                    leading: Icon(
                      CupertinoIcons.arrow_down_doc,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/import');
                    },
                  ),
                  SettingsRowCondensed(
                    title: 'Export Recipes',
                    leading: Icon(
                      CupertinoIcons.arrow_up_doc,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/export');
                    },
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.settingsGroupGap),

              // Help section
              SettingsGroupCondensed(
                children: [
                  SettingsRowCondensed(
                    title: 'Help',
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedHelpCircle,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/help');
                    },
                  ),
                  SettingsRowCondensed(
                    title: 'Support',
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedMessage01,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/support');
                    },
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.settingsGroupGap),

              // Legal section
              SettingsGroupCondensed(
                children: [
                  SettingsRowCondensed(
                    title: 'Privacy Policy',
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedShield01,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/privacy');
                    },
                  ),
                  SettingsRowCondensed(
                    title: 'Terms of Use',
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedFile01,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/terms');
                    },
                  ),
                  SettingsRowCondensed(
                    title: 'Acknowledgements',
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedFavourite,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/acknowledgements');
                    },
                  ),
                ],
              ),

              // Bottom spacing - extra large to ensure content is always scrollable
              // and prevents large title animation bounce loop on iPad landscape
              const SizedBox(height: 200),
            ],
          ),
        ),
      ],
    );
  }

  String _getHomeScreenLabel(String value) {
    return switch (value) {
      'shopping' => 'Shopping',
      'meal_plans' => 'Meal Plan',
      'pantry' => 'Pantry',
      _ => 'Recipes',
    };
  }
}
