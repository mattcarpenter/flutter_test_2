import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';

class ShoppingListTab extends StatelessWidget {
  const ShoppingListTab({super.key});

  @override
  Widget build(BuildContext context) {
    // This is the "root" content for `/shopping`.
    // No nested Navigator needed—go_router handles sub-routes:
    return AdaptiveSliverPage(
      title: 'Shopping List',
      body: Center(
        child: CupertinoButton.filled(
          onPressed: () {
            // Navigate to /shopping/sub with go_router
            // This will load the ShoppingListSubPage
            // (configured in the shell route).
            //
            // For iOS transitions, see how we used CupertinoPage in go_router.
            context.go('/shopping/sub');
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
