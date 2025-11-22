import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/spacing.dart';
import '../../../theme/colors.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_row.dart';

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

              // Recipes section
              SettingsGroup(
                header: 'Recipes',
                children: [
                  SettingsRow(
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

              SizedBox(height: AppSpacing.xl),

              // Future sections can be added here
              // Example: Account section
              // SettingsGroup(
              //   header: 'Account',
              //   children: [
              //     SettingsRow(
              //       title: 'Profile',
              //       leading: Icon(
              //         CupertinoIcons.person,
              //         size: 22,
              //         color: colors.primary,
              //       ),
              //       onTap: () {},
              //     ),
              //     SettingsRow(
              //       title: 'Sign Out',
              //       isDestructive: true,
              //       showChevron: false,
              //       onTap: () {},
              //     ),
              //   ],
              // ),

              // Bottom spacing
              SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }
}
