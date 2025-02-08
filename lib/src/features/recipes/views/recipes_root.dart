import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../widgets/folder_list.dart';

class RecipesTab extends StatelessWidget {
  const RecipesTab({super.key});

  @override
  Widget build(BuildContext context) {
    // This is the "root" content for `/shopping`.
    // No nested Navigator needed—go_router handles sub-routes:
    return AdaptiveSliverPage(
      title: 'Recipes',
      body: FolderList(),
      trailing: const Icon(CupertinoIcons.add_circled),
      leading: const Icon(CupertinoIcons.person_2),
    );
  }
}
