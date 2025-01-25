import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';

class LabsTab extends StatelessWidget {
  final void Function() onMenuPressed;
  const LabsTab({super.key, required this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    final menuButton = GestureDetector(
      onTap: onMenuPressed,
      child: const Icon(CupertinoIcons.bars), // Hamburger icon
    );

    // This is the "root" content for `/shopping`.
    // No nested Navigator needed—go_router handles sub-routes:
    return AdaptiveSliverPage(
      title: 'Labs',
      body: Center(
        child: CupertinoButton.filled(
          onPressed: () {
            // Navigate to /shopping/sub with go_router
            // This will load the ShoppingListSubPage
            // (configured in the shell route).
            //
            // For iOS transitions, see how we used CupertinoPage in go_router.
            context.go('/labs/sub');
          },
          child: const Text('Hello! Go to Next Page'),
        ),
      ),
      trailing: const Icon(CupertinoIcons.add_circled),
      leading: isTablet ? const Icon(CupertinoIcons.person_2) : menuButton,
    );
  }
}
