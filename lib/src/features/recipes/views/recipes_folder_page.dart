import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../widgets/folder_list.dart';

class RecipesFolderPage extends StatelessWidget {
  final String? parentId;
  final String title;

  const RecipesFolderPage({
    super.key,
    this.parentId,
    this.title = 'Folders',
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverPage(
      title: title,
      body: FolderList(parentId: parentId),
      trailing: const Icon(CupertinoIcons.add_circled),
      previousPageTitle: 'Recipes',
      automaticallyImplyLeading: true,
    );
  }
}
