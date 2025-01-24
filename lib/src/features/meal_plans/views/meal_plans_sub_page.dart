import 'package:flutter/cupertino.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import 'package:go_router/go_router.dart';

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
      trailing: const Icon(CupertinoIcons.add_circled),
      previousPageTitle: 'Meal Plans',
      automaticallyImplyLeading: true,
    );
  }
}
