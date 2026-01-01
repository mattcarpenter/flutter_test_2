import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';

class ShoppingListSubPage extends StatelessWidget {
  final String title;

  const ShoppingListSubPage({super.key, this.title = 'Sub Page'});

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverPage(
      title: title,
      body: const Center(
        child: Text("Shopping list sub page 🛒"),
      ),
      trailing: const HugeIcon(icon: HugeIcons.strokeRoundedAddCircle),
      previousPageTitle: 'Shopping List',
      automaticallyImplyLeading: true,
    );
  }
}
