import 'package:flutter/cupertino.dart';

import '../utils/adaptive_sliver_page.dart';

class ShoppingListSubPage extends StatelessWidget {
  final String title;
  const ShoppingListSubPage({Key? key, this.title = ''}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AdaptiveSliverPage(
      title: 'Kinokuniya',
      body: Center(
        child: Text('Buy Doritos 🌮'),
      ),
      trailing: Icon(CupertinoIcons.add_circled),
      transitionBetweenRoutes: true,
      previousPageTitle: 'Shopping List',
      automaticallyImplyLeading: true,
    );
  }
}
