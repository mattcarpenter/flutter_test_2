import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            child: const Icon(CupertinoIcons.bars),
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
                    leading: Icon(
                      CupertinoIcons.house,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/home-screen');
                    },
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.lg),

              // Layout & Appearance section
              SettingsGroupCondensed(
                children: [
                  SettingsRowCondensed(
                    title: 'Layout & Appearance',
                    leading: Icon(
                      CupertinoIcons.paintbrush,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/layout-appearance');
                    },
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.lg),

              // Recipes section
              SettingsGroupCondensed(
                header: 'Recipes',
                children: [
                  SettingsRowCondensed(
                    title: 'Manage Tags',
                    leading: Icon(
                      CupertinoIcons.tag,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/tags');
                    },
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.lg),

              // Account section
              SettingsGroupCondensed(
                children: [
                  SettingsRowCondensed(
                    title: 'Account',
                    leading: Icon(
                      CupertinoIcons.person_circle,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/account');
                    },
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.lg),

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

              SizedBox(height: AppSpacing.lg),

              // Help section
              SettingsGroupCondensed(
                children: [
                  SettingsRowCondensed(
                    title: 'Help',
                    leading: Icon(
                      CupertinoIcons.question_circle,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/help');
                    },
                  ),
                  SettingsRowCondensed(
                    title: 'Support',
                    leading: Icon(
                      CupertinoIcons.chat_bubble_2,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/support');
                    },
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.lg),

              // Legal section
              SettingsGroupCondensed(
                children: [
                  SettingsRowCondensed(
                    title: 'Privacy Policy',
                    leading: Icon(
                      CupertinoIcons.shield,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/privacy');
                    },
                  ),
                  SettingsRowCondensed(
                    title: 'Terms of Use',
                    leading: Icon(
                      CupertinoIcons.doc_text,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/terms');
                    },
                  ),
                  SettingsRowCondensed(
                    title: 'Acknowledgements',
                    leading: Icon(
                      CupertinoIcons.heart,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () {
                      context.push('/settings/acknowledgements');
                    },
                  ),
                ],
              ),

              // Bottom spacing
              SizedBox(height: AppSpacing.xxl),
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
