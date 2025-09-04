import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
    final backgroundColor = colors.brightness == Brightness.light
        ? AppColorSwatches.neutral[100]!
        : colors.background;
    
    // Wrap in CupertinoTheme to set scaffold background for entire page
    return CupertinoTheme(
      data: CupertinoTheme.of(context).copyWith(
        scaffoldBackgroundColor: backgroundColor,
      ),
      child: AdaptiveSliverPage(
        title: 'Settings',
        leading: menuButton,
        automaticallyImplyLeading: onMenuPressed == null,
        body: Container(
          color: backgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          SizedBox(height: AppSpacing.xl),
          
          // Tags section
          SettingsGroup(
            children: [
              SettingsRow(
                title: 'Manage Tags',
                leading: Icon(
                  CupertinoIcons.tag,
                  size: 20,
                  color: colors.textSecondary,
                ),
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
      ),
    );
  }
}