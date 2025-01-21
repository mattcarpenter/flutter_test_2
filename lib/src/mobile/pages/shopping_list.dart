import 'package:flutter/cupertino.dart';
import 'package:flutter_test_2/src/mobile/pages/shopping_list_sub.dart';

import '../utils/adaptive_sliver_page.dart';

class ShoppingListPage extends StatelessWidget {
  final String title;
  const ShoppingListPage({super.key, this.title = ''});

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverPage(
      title: 'Shopping List',
      body: Center(
        child: CupertinoButton.filled(
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute<Widget>(
                builder: (_) =>
                const ShoppingListSubPage(title: 'Kinokuniya'),
              ),
            );
            // For iOS, you might push in this tab's Navigator.
            // For Android, you might push on the global navigator or a nested one.
          },
          child: const Text('Go to Next Page'),
        ),
      ),
      trailing: const Icon(CupertinoIcons.add_circled),
      leading: const Icon(CupertinoIcons.person_2),
      transitionBetweenRoutes: true,
    );
  }
}
