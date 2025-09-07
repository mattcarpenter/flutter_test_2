import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:super_cupertino_navigation_bar/super_cupertino_navigation_bar.dart';

import '../../theme/colors.dart';
import '../../theme/typography.dart';

/// A custom SearchDelegate that defers building suggestions/results
/// to the provided searchResultsBuilder.
class AdaptiveSearchDelegate extends SearchDelegate<String> {
  final Widget Function(BuildContext context, String query)? searchResultsBuilder;
  final ValueChanged<String>? onSearchChanged;

  AdaptiveSearchDelegate({
    this.searchResultsBuilder,
    this.onSearchChanged,
    String defaultQuery = '',
  }) {
    query = defaultQuery;
  }

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
  final Widget Function(BuildContext context, String query)? searchResultsBuilder;
  final ValueChanged<String>? onSearchChanged;

  AdaptiveSliverPage({
    Key? key,
    required this.title,
    this.body,
    this.slivers,
    this.trailing,
    this.leading,
    this.previousPageTitle,
    this.automaticallyImplyLeading,
    bool? searchEnabled,
    this.searchResultsBuilder,
    this.onSearchChanged,
  }) : this.searchEnabled = searchEnabled ?? (searchResultsBuilder != null),
       super(key: key);

  @override
  _AdaptiveSliverPageState createState() => _AdaptiveSliverPageState();
}

class _AdaptiveSliverPageState extends State<AdaptiveSliverPage> {
  late final TextEditingController _controller;
  String _searchQuery = '';
  bool _searchIsActive = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _searchQuery);
    _controller.addListener(() {
      final newQuery = _controller.text;
      if (newQuery != _searchQuery) {
        setState(() {
          _searchQuery = newQuery;
        });
        widget.onSearchChanged?.call(newQuery);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Widget> _buildContentSlivers() {
    if (widget.slivers != null) {
      return widget.slivers!;
    } else if (widget.body != null) {
      return [
        SliverToBoxAdapter(child: widget.body!),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ];
    } else {
      return [];
    }
  }

  Widget _buildSearchResultsSliver() {
    if (widget.searchResultsBuilder != null) {
      return SliverFillRemaining(
        child: widget.searchResultsBuilder!(context, _searchQuery)
      );
    }
    return const SliverFillRemaining(
      child: Center(child: Text('No search results'))
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double screenWidth = MediaQuery.of(context).size.width;
      final double pageWidth = constraints.maxWidth;
      final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
      final scaffoldColor = CupertinoTheme.of(context).scaffoldBackgroundColor;

      final double padding = (screenWidth - pageWidth > 50)
          ? 0
          : (isTablet ? 50 - (screenWidth - pageWidth) : 0);

      if (Platform.isIOS) {
        return CupertinoPageScaffold(
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              widget.leading == null
                  ? (widget.searchEnabled
                      ? CupertinoSliverNavigationBar.search(
                          searchField: CupertinoSearchTextField(
                            controller: _controller,
                            placeholder: _searchIsActive ? 'Enter search text' : 'Search',
                            autofocus: _searchIsActive,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                              widget.onSearchChanged?.call(value);
                            },
                          ),
                          largeTitle: Text(
                              widget.title,
                              style: AppTypography.h1.copyWith(
                                color: AppColors.of(context).textPrimary,
                              ),
                          ),
                          transitionBetweenRoutes: true,
                          previousPageTitle: widget.previousPageTitle,
                          trailing: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: widget.trailing,
                          ),
                          padding: EdgeInsetsDirectional.only(start: padding),
                          automaticallyImplyLeading: widget.automaticallyImplyLeading ?? false,
                          onSearchableBottomTap: widget.searchResultsBuilder != null
                              ? (value) {
                                  setState(() {
                                    _searchIsActive = value;
                                  });
                                }
                              : null,
                        )
                      : CupertinoSliverNavigationBar(
                          largeTitle: Text(widget.title,
                              style: AppTypography.h1.copyWith(
                                color: AppColors.of(context).textPrimary,
                              )),
                          transitionBetweenRoutes: true,
                          previousPageTitle: widget.previousPageTitle,
                          trailing: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: widget.trailing,
                          ),
                          padding: EdgeInsetsDirectional.only(start: padding),
                          automaticallyImplyLeading: widget.automaticallyImplyLeading ?? false,
                        ))
                  : (widget.searchEnabled
                      ? CupertinoSliverNavigationBar.search(
                          searchField: CupertinoSearchTextField(
                            controller: _controller,
                            placeholder: _searchIsActive ? 'Enter search text' : 'Search',
                            autofocus: _searchIsActive,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                              widget.onSearchChanged?.call(value);
                            },
                          ),
                          largeTitle: Text(widget.title,
                              style: AppTypography.h1.copyWith(
                                color: AppColors.of(context).textPrimary,
                              )),
                          transitionBetweenRoutes: true,
                          previousPageTitle: widget.previousPageTitle,
                          trailing: widget.trailing,
                          automaticallyImplyLeading: widget.automaticallyImplyLeading ?? false,
                          leading: Padding(
                            padding: EdgeInsets.symmetric(horizontal: padding),
                            child: widget.leading,
                          ),
                          onSearchableBottomTap: widget.searchResultsBuilder != null
                              ? (value) {
                                  setState(() {
                                    _searchIsActive = value;
                                  });
                                }
                              : null,
                        )
                      : CupertinoSliverNavigationBar(
                          largeTitle: Text(widget.title,
                              style: AppTypography.h1.copyWith(
                                color: AppColors.of(context).textPrimary,
                              )),
                          transitionBetweenRoutes: true,
                          previousPageTitle: widget.previousPageTitle,
                          trailing: widget.trailing,
                          automaticallyImplyLeading: widget.automaticallyImplyLeading ?? false,
                          leading: Padding(
                            padding: EdgeInsets.symmetric(horizontal: padding),
                            child: widget.leading,
                          ),
                        )),
              // Show search results when search is active and enabled, otherwise show normal content
              if (widget.searchEnabled && _searchIsActive && widget.searchResultsBuilder != null)
                _buildSearchResultsSliver()
              else
                ..._buildContentSlivers(),
            ],
          ),
        );
      } else {
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
                    defaultQuery: _searchQuery,
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
                title: Text(widget.title,
                    style: AppTypography.h1.copyWith(
                      color: AppColors.of(context).textPrimary,
                    )),
                floating: true,
                pinned: true,
                // leadingPadding:
                // isTablet ? EdgeInsetsDirectional.only(start: padding) : null,
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
