import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';

class MealPlansSubPage extends StatelessWidget {
  final String title;

  const MealPlansSubPage({super.key, this.title = 'Sub Page'});

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverPage(
      title: title,
      body: const Center(
        child: Text("Discover Sub Page"),
      ),
      trailing: const HugeIcon(icon: HugeIcons.strokeRoundedAddCircle),
      previousPageTitle: 'Meal Plans',
      automaticallyImplyLeading: true,
    );
  }
}
