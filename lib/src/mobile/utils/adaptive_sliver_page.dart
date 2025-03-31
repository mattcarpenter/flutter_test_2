import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:super_cupertino_navigation_bar/super_cupertino_navigation_bar.dart';

/// Dummy SearchDelegate implementation.
class DummySearchDelegate extends SearchDelegate<String> {
  final List<String> dummyData = ['Item 1', 'Item 2', 'Item 3', 'Item 4'];

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = dummyData
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(suggestions[index]),
        onTap: () => close(context, suggestions[index]),
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: Text('You selected: $query'),
    );
  }
}

class AdaptiveSliverPage extends StatelessWidget {
  final String title;
  final Widget? body;
  final List<Widget>? slivers;
  final Widget? trailing;
  final Widget? leading;
  final String? previousPageTitle;
  final bool? automaticallyImplyLeading;
  final bool searchEnabled; // New property

  const AdaptiveSliverPage({
    Key? key,
    required this.title,
    this.body,
    this.slivers,
    this.trailing,
    this.leading,
    this.previousPageTitle,
    this.automaticallyImplyLeading,
    this.searchEnabled = false, // Default to true
  }) : super(key: key);

  List<Widget> _buildContentSlivers() {
    if (slivers != null) {
      return slivers!;
    } else if (body != null) {
      return [
        SliverToBoxAdapter(child: body!),
        // Optional: extra space at the bottom.
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ];
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = MediaQuery.of(context).size.width;
        final double pageWidth = constraints.maxWidth;
        final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
        final scaffoldColor = CupertinoTheme.of(context).scaffoldBackgroundColor;

        // Compute dynamic padding.
        final double padding =
        (screenWidth - pageWidth > 50) ? 0 : (isTablet ? 50 - (screenWidth - pageWidth) : 0);

        if (Platform.isIOS) {
          // iOS branch remains unchanged.
          return Scaffold(
            backgroundColor: scaffoldColor,
            body: SuperScaffold(
              appBar: SuperAppBar(
                title: Text(title),
                largeTitle: SuperLargeTitle(
                  enabled: true,
                  largeTitle: title,
                ),
                previousPageTitle: previousPageTitle ?? "",
                leading: leading,
                actions: trailing,
                searchBar: SuperSearchBar(
                  enabled: searchEnabled,
                  onChanged: (query) {
                    // Search Bar Changes
                  },
                  onSubmitted: (query) {
                    // On Search Bar submitted
                  },
                  // Add other search bar properties as needed
                ),
              ),
              body: CustomScrollView(
                slivers: _buildContentSlivers(),
              ),
            ),
          );
        } else {
          // Material branch with injected search icon when searchEnabled is true.
          List<Widget> actionsList = [];
          if (searchEnabled) {
            actionsList.add(
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  showSearch(context: context, delegate: DummySearchDelegate());
                },
              ),
            );
          }
          if (trailing != null) {
            actionsList.add(
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: trailing,
              ),
            );
          }

          return Scaffold(
            body: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverAppBar(
                  title: Text(title),
                  floating: true,
                  pinned: true,
                  leadingPadding: isTablet ? EdgeInsetsDirectional.only(start: padding) : null,
                  actions: actionsList.isNotEmpty ? actionsList : null,
                  leading: leading,
                ),
                if (body != null)
                  SliverFillRemaining(child: body!)
                else
                  ..._buildContentSlivers(),
              ],
            ),
          );
        }
      },
    );
  }
}
