import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../localization/l10n_extension.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

/// Reusable placeholder page for settings that aren't yet implemented
class PlaceholderSettingsPage extends ConsumerWidget {
  final String title;
  final IconData icon;
  final String? message;
  final String? description;
  final String? previousPageTitle;

  const PlaceholderSettingsPage({
    super.key,
    required this.title,
    required this.icon,
    this.message,
    this.description,
    this.previousPageTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final effectiveMessage = message ?? context.l10n.commonComingSoon;
    final effectivePreviousPageTitle = previousPageTitle ?? context.l10n.settingsTitle;

    return AdaptiveSliverPage(
      title: title,
      automaticallyImplyLeading: true,
      previousPageTitle: effectivePreviousPageTitle,
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
                  effectiveMessage,
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

class ImportRecipesPage extends ConsumerWidget {
  const ImportRecipesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PlaceholderSettingsPage(
      title: context.l10n.settingsImportRecipes,
      icon: CupertinoIcons.arrow_down_doc,
      message: context.l10n.commonComingSoon,
      description: context.l10n.settingsImportDescription,
    );
  }
}

class ExportRecipesPage extends ConsumerWidget {
  const ExportRecipesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PlaceholderSettingsPage(
      title: context.l10n.settingsExportRecipes,
      icon: CupertinoIcons.arrow_up_doc,
      message: context.l10n.commonComingSoon,
      description: context.l10n.settingsExportDescription,
    );
  }
}

