import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../utils/feature_flags.dart';

class LabsTab extends ConsumerWidget {
  final void Function() onMenuPressed;
  const LabsTab({super.key, required this.onMenuPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    final menuButton = GestureDetector(
      onTap: onMenuPressed,
      child: const Icon(CupertinoIcons.bars), // Hamburger icon
    );

    // This is the "root" content for `/labs`.
    // No nested Navigator needed—go_router handles sub-routes:
    return AdaptiveSliverPage(
      title: 'Labs',
      body: FeatureGate(
        feature: 'labs',
        customUpgradeText: 'Upgrade to access Labs',
        child: Center(
          child: CupertinoButton.filled(
            onPressed: () {
              // Navigate to /labs/sub with go_router
              // This will load the LabsSubPage
              // (configured in the shell route).
              //
              // For iOS transitions, see how we used CupertinoPage in go_router.
              context.go('/labs/sub');
            },
            child: const Text('Hello! Go to Next Page'),
          ),
        ),
      ),
      trailing: const Icon(CupertinoIcons.add_circled),
      leading: isTablet ? const Icon(CupertinoIcons.person_2) : menuButton,
    );
  }
}
