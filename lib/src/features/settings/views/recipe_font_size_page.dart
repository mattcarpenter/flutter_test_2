import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../localization/l10n_extension.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../providers/app_settings_provider.dart';
import '../widgets/settings_group_condensed.dart';
import '../widgets/settings_row_condensed.dart';

/// Page for selecting recipe text font size
class RecipeFontSizePage extends ConsumerWidget {
  const RecipeFontSizePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFontSize = ref.watch(recipeFontSizeProvider);

    final options = [
      _FontSizeOption(
        value: 'small',
        title: context.l10n.settingsFontSizeSmall,
        scaleFactor: 0.85,
      ),
      _FontSizeOption(
        value: 'medium',
        title: context.l10n.settingsFontSizeMedium,
        scaleFactor: 1.0,
      ),
      _FontSizeOption(
        value: 'large',
        title: context.l10n.settingsFontSizeLarge,
        scaleFactor: 1.15,
      ),
    ];

    return AdaptiveSliverPage(
      title: context.l10n.settingsFontSizeTitle,
      automaticallyImplyLeading: true,
      previousPageTitle: context.l10n.settingsLayoutAppearance,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xl),

              // Options
              SettingsGroupCondensed(
                footer: context.l10n.settingsFontSizeDescription,
                children: options.map((option) {
                  final isSelected = currentFontSize == option.value;

                  return SettingsSelectionRow(
                    title: option.title,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(appSettingsProvider.notifier).setRecipeFontSize(option.value);
                    },
                  );
                }).toList(),
              ),

              SizedBox(height: AppSpacing.settingsGroupGap),

              // Preview section
              SettingsGroupCondensed(
                header: context.l10n.settingsFontSizePreview,
                children: [
                  _FontSizePreview(
                    scaleFactor: currentFontSize == 'small'
                        ? 0.85
                        : currentFontSize == 'large'
                            ? 1.15
                            : 1.0,
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }
}

class _FontSizeOption {
  final String value;
  final String title;
  final double scaleFactor;

  const _FontSizeOption({
    required this.value,
    required this.title,
    required this.scaleFactor,
  });
}

/// Preview widget showing sample text at the selected font size
class _FontSizePreview extends StatelessWidget {
  final double scaleFactor;

  const _FontSizePreview({required this.scaleFactor});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final baseSize = AppTypography.body.fontSize ?? 16;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.settingsFontSizePreviewIngredients,
            style: AppTypography.bodySmall.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          _buildIngredientLine(
            context.l10n.settingsFontSizePreviewItem1,
            baseSize,
            scaleFactor,
            colors,
          ),
          SizedBox(height: AppSpacing.xs),
          _buildIngredientLine(
            context.l10n.settingsFontSizePreviewItem2,
            baseSize,
            scaleFactor,
            colors,
          ),
          SizedBox(height: AppSpacing.xs),
          _buildIngredientLine(
            context.l10n.settingsFontSizePreviewItem3,
            baseSize,
            scaleFactor,
            colors,
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientLine(
    String text,
    double baseSize,
    double scaleFactor,
    AppColors colors,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '•  ',
          style: TextStyle(
            fontSize: baseSize * scaleFactor,
            color: colors.textPrimary,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: baseSize * scaleFactor,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
