import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/spacing.dart';
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
    
    return AdaptiveSliverPage(
      title: 'Settings',
      leading: menuButton,
      automaticallyImplyLeading: onMenuPressed == null,
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: AppSpacing.md),
            
            // Tags section
            SettingsGroup(
              children: [
                SettingsRow(
                  title: 'Manage Tags',
                  subtitle: 'Edit tag colors and delete unused tags',
                  onTap: () {
                    context.push('/settings/tags');
                  },
                ),
              ],
            ),
            
            SizedBox(height: AppSpacing.xl),
            
            // Future sections can be added here
            // SettingsGroup(
            //   children: [
            //     SettingsRow(
            //       title: 'Another Setting',
            //       onTap: () {
            //         // Handle another setting
            //       },
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}