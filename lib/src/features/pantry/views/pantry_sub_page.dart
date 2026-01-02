import 'package:flutter/cupertino.dart';
import '../../../localization/l10n_extension.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';

class PantrySubPage extends StatelessWidget {
  final String? title;

  const PantrySubPage({
    super.key,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverPage(
      title: title ?? context.l10n.pantryDetailsTitle,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(context.l10n.pantrySubPagePlaceholder),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(context.l10n.pantryGoBack),
            ),
          ],
        ),
      ),
      previousPageTitle: context.l10n.pantryTitle,
    );
  }
}