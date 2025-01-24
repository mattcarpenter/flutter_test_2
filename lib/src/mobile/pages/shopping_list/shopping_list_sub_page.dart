import 'package:flutter/cupertino.dart';
import '../../utils/adaptive_sliver_page.dart';

class ShoppingListSubPage extends StatelessWidget {
  final String title;

  const ShoppingListSubPage({Key? key, this.title = ''}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverPage(
      title: title,
      body: Center(
        child: CupertinoButton.filled(
          onPressed: () {
            Navigator.of(context).pushNamed('/deep');
          },
          child: const Text('Go to Deep Nested Page'),
        ),
      ),
      trailing: const Icon(CupertinoIcons.add_circled),
      previousPageTitle: 'Shopping List',
      automaticallyImplyLeading: true,
    );
  }
}
