import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../widgets/adaptive_pull_down/adaptive_menu_item.dart';
import '../../../widgets/adaptive_pull_down/adaptive_pull_down.dart';

class RecipePage extends StatelessWidget {
  final String recipeId;
  final String previousPageTitle;

  const RecipePage({super.key, required this.recipeId, required this.previousPageTitle});

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverPage(
      title: 'Recipe',
      // Instead of a body, we pass in slivers.
      slivers: const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Hello World'
            ),
          ),
        ),
      ],
      trailing: AdaptivePullDownButton(
        items: [
          AdaptiveMenuItem(
              title: 'Edit Recipe', icon: const Icon(CupertinoIcons.folder), onTap: () {
                // Todo
          }
          ),
        ],
        child: const Icon(CupertinoIcons.pencil_circle),
      ),
      automaticallyImplyLeading: true,
      previousPageTitle: previousPageTitle,
    );
  }
}


