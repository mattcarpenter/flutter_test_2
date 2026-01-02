import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../localization/l10n_extension.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';

class MealPlansSubPage extends StatelessWidget {
  final String? title;

  const MealPlansSubPage({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverPage(
      title: title ?? context.l10n.mealPlanDiscoverSubPage,
      body: Center(
        child: Text(context.l10n.mealPlanDiscoverSubPage),
      ),
      trailing: const HugeIcon(icon: HugeIcons.strokeRoundedAddCircle),
      previousPageTitle: context.l10n.mealPlanPageTitle,
      automaticallyImplyLeading: true,
    );
  }
}
