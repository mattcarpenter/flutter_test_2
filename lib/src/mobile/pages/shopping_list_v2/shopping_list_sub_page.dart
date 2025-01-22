import 'package:flutter/cupertino.dart';
import '../../utils/adaptive_sliver_page.dart';
import 'package:go_router/go_router.dart';

class ShoppingListSubPage extends StatelessWidget {
  final String title;

  const ShoppingListSubPage({Key? key, this.title = 'Sub Page'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverPage(
      title: title,
      body: Center(
        child: CupertinoButton.filled(
          onPressed: () {
            // Another deeper route => /shopping/deep
            context.push('/shopping/deep');
          },
          child: const Text('Go to Deep Nested Page'),
        ),
      ),
      trailing: const Icon(CupertinoIcons.add_circled),
      previousPageTitle: 'Shopping',
      transitionBetweenRoutes: true,
      automaticallyImplyLeading: true,
    );
  }
}
