import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../utils/feature_flags.dart';

class LabsSubPage extends ConsumerWidget {
  final String title;

  const LabsSubPage({Key? key, this.title = 'Sub Page'}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveSliverPage(
      title: title,
      body: FeatureGate(
        feature: 'labs',
        customUpgradeText: 'Upgrade to access Labs',
        child: const Center(
          child: Text("Labs Sub Page"),
        ),
      ),
      trailing: const Icon(CupertinoIcons.add_circled),
      previousPageTitle: 'Labs',
      automaticallyImplyLeading: true,
    );
  }
}
