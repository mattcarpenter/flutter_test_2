import 'package:flutter/cupertino.dart';
import '../../utils/adaptive_sliver_page.dart';

class ShoppingListRootPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    print('Navigator on build: $navigator');

    return AdaptiveSliverPage(
      title: 'Shopping List',
      body: Center(
        child: CupertinoButton.filled(
          onPressed: () {
            print('Navigator on button press: $navigator');
            Navigator.of(context).pushNamed('/sub');
          },
          child: const Text('Hello! Go to Next Page'),
        ),
      ),
      trailing: const Icon(CupertinoIcons.add_circled),
      leading: const Icon(CupertinoIcons.person_2),
      transitionBetweenRoutes: true,
    );
  }
}
