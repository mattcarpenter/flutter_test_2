import 'package:flutter/cupertino.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';

class PantrySubPage extends StatelessWidget {
  final String title;

  const PantrySubPage({
    super.key,
    this.title = 'Pantry Details',
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverPage(
      title: title,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('This is a pantry sub-page'),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
      previousPageTitle: 'Pantry',
    );
  }
}