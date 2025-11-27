import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

/// Reusable placeholder page for settings that aren't yet implemented
class PlaceholderSettingsPage extends ConsumerWidget {
  final String title;
  final IconData icon;
  final String message;
  final String? description;
  final String previousPageTitle;

  const PlaceholderSettingsPage({
    super.key,
    required this.title,
    required this.icon,
    this.message = 'Coming Soon',
    this.description,
    this.previousPageTitle = 'Settings',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    return AdaptiveSliverPage(
      title: title,
      automaticallyImplyLeading: true,
      previousPageTitle: previousPageTitle,
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 64,
                  color: colors.textTertiary,
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  message,
                  style: AppTypography.h4.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                if (description != null) ...[
                  SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    child: Text(
                      description!,
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Pre-configured placeholder pages for specific settings

class ImportRecipesPage extends PlaceholderSettingsPage {
  const ImportRecipesPage({super.key})
      : super(
          title: 'Import Recipes',
          icon: CupertinoIcons.arrow_down_doc,
          message: 'Coming Soon',
          description: 'Import recipes from other apps or websites.',
        );
}

class ExportRecipesPage extends PlaceholderSettingsPage {
  const ExportRecipesPage({super.key})
      : super(
          title: 'Export Recipes',
          icon: CupertinoIcons.arrow_up_doc,
          message: 'Coming Soon',
          description: 'Export your recipes to share or backup.',
        );
}

class AcknowledgementsPage extends StatelessWidget {
  const AcknowledgementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '';
        return LicensePage(
          applicationName: 'Recipe App',
          applicationVersion: version,
        );
      },
    );
  }
}
