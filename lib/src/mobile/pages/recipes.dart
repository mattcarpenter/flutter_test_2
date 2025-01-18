import 'package:flutter/cupertino.dart';

class RecipesPage extends StatelessWidget {
  final String title;

  const RecipesPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return CupertinoPageScaffold(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double pageWidth = constraints.maxWidth;

          // Calculate the dynamic padding
          final double padding = (screenWidth - pageWidth > 50)
              ? 0
              : 50 - (screenWidth - pageWidth);

          return CustomScrollView(
            slivers: <Widget>[
              CupertinoSliverNavigationBar(
                leading: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: const Icon(CupertinoIcons.person_2),
                ),
                largeTitle: const Text('Recipes'),
                trailing: const Icon(CupertinoIcons.add_circled),
              ),
              const SliverFillRemaining(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Text('Drag me up', textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
