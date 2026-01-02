import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LicensePage;
import 'package:hugeicons/hugeicons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../localization/l10n_extension.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../widgets/settings_group_condensed.dart';
import '../widgets/settings_row_condensed.dart';

class AcknowledgementsPage extends StatelessWidget {
  const AcknowledgementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return AdaptiveSliverPage(
      title: context.l10n.settingsAcknowledgements,
      automaticallyImplyLeading: true,
      previousPageTitle: context.l10n.settingsTitle,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.xl),

              // Open Source Licenses
              SettingsGroupCondensed(
                children: [
                  SettingsRowCondensed(
                    title: context.l10n.settingsAcknowledgementsOSSLicenses,
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedFile01,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () => _openLicensesPage(context),
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.xl),

              // Credits section - plain text
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  context.l10n.settingsAcknowledgementsSoundCredits,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),

              // Bottom spacing
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  void _openLicensesPage(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.data?.version ?? '';
            return LicensePage(
              applicationName: 'Stockpot',
              applicationVersion: version,
            );
          },
        ),
      ),
    );
  }
}
