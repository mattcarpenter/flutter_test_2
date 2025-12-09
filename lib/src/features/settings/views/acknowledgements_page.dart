import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LicensePage;
import 'package:package_info_plus/package_info_plus.dart';

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
      title: 'Acknowledgements',
      automaticallyImplyLeading: true,
      previousPageTitle: 'Settings',
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
                    title: 'Open Source Software Licenses',
                    leading: Icon(
                      CupertinoIcons.doc_text,
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
                  'Sound material used: OtoLogic (https://otologic.jp)',
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
