import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:super_cupertino_navigation_bar/super_cupertino_navigation_bar.dart';

/// A custom SearchDelegate that defers building suggestions/results
/// to the provided searchResultsBuilder.
class AdaptiveSearchDelegate extends SearchDelegate<String> {
  final Widget Function(BuildContext context, String query)? searchResultsBuilder;
  final ValueChanged<String>? onSearchChanged;

  AdaptiveSearchDelegate({
    this.searchResultsBuilder,
    this.onSearchChanged,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            query = '';
            onSearchChanged?.call(query);
            showSuggestions(context);
          },
        )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        // First close search, then allow navigation context to resume
        close(context, '');
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    onSearchChanged?.call(query);
    if (searchResultsBuilder != null) {
      return searchResultsBuilder!(context, query);
    }
    return Container();
  }

  @override
  Widget buildResults(BuildContext context) {
    if (searchResultsBuilder != null) {
      return searchResultsBuilder!(context, query);
    }
    return Center(child: Text('No results'));
  }
}

class AdaptiveSliverPage extends StatefulWidget {
  final String title;
  final Widget? body;
  final List<Widget>? slivers;
  final Widget? trailing;
  final Widget? leading;
  final String? previousPageTitle;
  final bool? automaticallyImplyLeading;
  final bool searchEnabled;

  /// Called to build the search results widget tree.
  /// It receives the current search query.
  final Widget Function(BuildContext context, String query)? searchResultsBuilder;

  /// Optional callback when the search query changes.
  final ValueChanged<String>? onSearchChanged;

  const AdaptiveSliverPage({
    Key? key,
    required this.title,
    this.body,
    this.slivers,
    this.trailing,
    this.leading,
    this.previousPageTitle,
    this.automaticallyImplyLeading,
    this.searchEnabled = false,
    this.searchResultsBuilder,
    this.onSearchChanged,
  }) : super(key: key);

  @override
  _AdaptiveSliverPageState createState() => _AdaptiveSliverPageState();
}

class _AdaptiveSliverPageState extends State<AdaptiveSliverPage> {
  String _searchQuery = '';

  List<Widget> _buildContentSlivers() {
    if (widget.slivers != null) {
      return widget.slivers!;
    } else if (widget.body != null) {
      return [
        SliverToBoxAdapter(child: widget.body!),
        // Optional: extra space at the bottom.
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ];
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double screenWidth = MediaQuery.of(context).size.width;
      final double pageWidth = constraints.maxWidth;
      final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
      final scaffoldColor = CupertinoTheme.of(context).scaffoldBackgroundColor;

      // Compute dynamic padding.
      final double padding = (screenWidth - pageWidth > 50)
          ? 0
          : (isTablet ? 50 - (screenWidth - pageWidth) : 0);

      if (Platform.isIOS) {
        return CupertinoPageScaffold(
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              // Navigation bar
              widget.leading == null
                  ? CupertinoSliverNavigationBar.search(
                searchField: CupertinoSearchTextField(
                  autofocus: true,
                  placeholder: true ? 'Enter search text' : 'Search',
                  onChanged: (String value) {
                    setState(() {
                    });
                  },
                ),
                largeTitle: Text(widget.title),
                transitionBetweenRoutes: true,
                previousPageTitle: widget.previousPageTitle,
                trailing: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: widget.trailing,
                ),
                padding: EdgeInsetsDirectional.only(start: padding),
                automaticallyImplyLeading: widget.automaticallyImplyLeading ?? false,
              )
                  : CupertinoSliverNavigationBar.search(
                searchField: CupertinoSearchTextField(
                  autofocus: true,
                  placeholder: true ? 'Enter search text' : 'Search',
                  onChanged: (String value) {
                    setState(() {
                    });
                  },
                ),
                largeTitle: Text(widget.title),
                transitionBetweenRoutes: true,
                previousPageTitle: widget.previousPageTitle,
                trailing: widget.trailing,
                automaticallyImplyLeading: widget.automaticallyImplyLeading ?? false,
                leading: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: widget.leading,
                ),
              ),
              ..._buildContentSlivers(),
            ],
          ),
        );
        // For iOS, we leverage SuperSearchBar.
        /*return Scaffold(
          backgroundColor: scaffoldColor,
          body: SuperScaffold(
            appBar: SuperAppBar(
              title: Text(widget.title),
              largeTitle: SuperLargeTitle(
                enabled: true,
                largeTitle: widget.title,
              ),
              previousPageTitle: widget.previousPageTitle ?? "",
              leading: widget.leading,
              actions: widget.trailing,
              searchBar: SuperSearchBar(
                enabled: widget.searchEnabled,
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                  widget.onSearchChanged?.call(query);
                },
                onSubmitted: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                  widget.onSearchChanged?.call(query);
                },
                // The searchResult here is built using your provided builder.
                // For iOS search, we need to make sure the builder gets a proper context
                searchResult: widget.searchResultsBuilder != null
                    ? widget.searchResultsBuilder!(context, _searchQuery)
                    : Container(),
              ),
            ),
            body: CustomScrollView(
              slivers: _buildContentSlivers(),
            ),
          ),
        );*/
      } else {
        // For Material (Android), we inject a search icon that calls showSearch.
        List<Widget> actionsList = [];
        if (widget.searchEnabled) {
          actionsList.add(
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: AdaptiveSearchDelegate(
                    searchResultsBuilder: widget.searchResultsBuilder,
                    onSearchChanged: widget.onSearchChanged,
                  ),
                );
              },
            ),
          );
        }
        if (widget.trailing != null) {
          actionsList.add(
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: widget.trailing!,
            ),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverAppBar(
                title: Text(widget.title),
                floating: true,
                pinned: true,
                leadingPadding:
                isTablet ? EdgeInsetsDirectional.only(start: padding) : null,
                actions: actionsList.isNotEmpty ? actionsList : null,
                leading: widget.leading,
              ),
              if (widget.body != null)
                SliverFillRemaining(child: widget.body!)
              else
                ..._buildContentSlivers(),
            ],
          ),
        );
      }
    });
  }
}
