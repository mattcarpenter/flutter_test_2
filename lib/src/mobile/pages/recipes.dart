import 'package:flutter/cupertino.dart';

// Instead of "extends StatelessWidget", we rename it to something like RecipesTab
class RecipesPage extends StatelessWidget {
  final String title;
  const RecipesPage({super.key, this.title = ""});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabView(
      builder: (BuildContext context) {
        return CupertinoPageScaffold(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double screenWidth = MediaQuery.of(context).size.width;
              final double pageWidth = constraints.maxWidth;
              final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;

              // Same dynamic padding logic
              final double padding = (screenWidth - pageWidth > 50)
                  ? 0
                  : (isTablet ? 50 - (screenWidth - pageWidth) : 0);

              print('screenWidth: $screenWidth, pageWidth: $pageWidth, padding: $padding');

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
                  SliverFillRemaining(
                    child: Center(
                      child: CupertinoButton.filled(
                        onPressed: () {
                          // Navigates within this tab's Navigator stack
                          Navigator.push(
                            context,
                            CupertinoPageRoute<Widget>(
                              builder: (_) => const NextPage(title: "Next Page"),
                            ),
                          );
                        },
                        child: const Text('Go to Next Page'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}



class NextPage extends StatelessWidget {
  final String title;

  const NextPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return CupertinoPageScaffold(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double pageWidth = constraints.maxWidth;
          final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;

          // Same dynamic padding logic
          final double padding = (screenWidth - pageWidth > 50)
              ? 0
              : (isTablet ? 50 - (screenWidth - pageWidth) : 0);

          return CustomScrollView(
            slivers: <Widget>[
              CupertinoSliverNavigationBar(
                // 1) Turn on route transitions
                transitionBetweenRoutes: true,

                // 2) Provide a previousPageTitle to show as the back button text
                previousPageTitle: 'Recipes',  // from the original page

                largeTitle: Text(title),
                automaticallyImplyLeading: true,
                padding: EdgeInsetsDirectional.only(start: padding),
                trailing: const Icon(CupertinoIcons.add_circled),
              ),
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'This page transitions back to Recipes with an iOS large-title animation.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

