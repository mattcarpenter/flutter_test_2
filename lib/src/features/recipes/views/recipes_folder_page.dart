import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../widgets/folder_list.dart';

class RecipesFolderPage extends StatelessWidget {
  final String? parentId;
  final String title;
  final String previousPageTitle; // New parameter

  const RecipesFolderPage({
    Key? key,
    this.parentId,
    required this.title,
    required this.previousPageTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverPage(
      title: title, // Large title displayed at the top.
      body: FolderList(
        parentId: parentId,
        // Pass the current page’s title down so FolderList can use it.
        currentPageTitle: title,
      ),
      trailing: const Icon(CupertinoIcons.add_circled),
      previousPageTitle: previousPageTitle, // This animates into the back button.
      automaticallyImplyLeading: true,
    );
  }
}
