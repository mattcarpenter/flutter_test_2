import 'package:flutter/cupertino.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import 'package:go_router/go_router.dart';

class ShoppingListSubPage extends StatelessWidget {
  final String title;

  const ShoppingListSubPage({Key? key, this.title = 'Sub Page'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverPage(
      title: title,
      body: const Center(
        child: Text("Shopping list sub page 🛒"),
      ),
      trailing: const Icon(CupertinoIcons.add_circled),
      previousPageTitle: 'Shopping List',
      transitionBetweenRoutes: true,
      automaticallyImplyLeading: true,
    );
  }
}
