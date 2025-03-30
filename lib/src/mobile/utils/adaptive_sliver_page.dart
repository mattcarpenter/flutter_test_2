import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:super_cupertino_navigation_bar/super_cupertino_navigation_bar.dart';

class AdaptiveSliverPage extends StatelessWidget {
  final String title;
  final Widget? body;
  final List<Widget>? slivers;
  final Widget? trailing;
  final Widget? leading;
  final String? previousPageTitle;
  final bool? automaticallyImplyLeading;

  const AdaptiveSliverPage({
    super.key,
    required this.title,
    this.body,
    this.slivers,
    this.trailing,
    this.leading,
    this.previousPageTitle,
    this.automaticallyImplyLeading,
  });

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
                    enabled: true,
                    onChanged: (query) {
                      // Search Bar Changes
                    },
                    onSubmitted: (query) {
                      // On Search Bar submitted
                    },
                    //searchResult: /* ... */,
                    // Add other search bar properties as needed
                  ),
                ),
                body: CustomScrollView(
                  slivers: _buildContentSlivers()
                )
              )
          );
        } else {
          return Scaffold(
            body: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverAppBar(
                  title: Text(title),
                  floating: true,
                  leadingPadding: isTablet ? EdgeInsetsDirectional.only(start: padding) : null,
                  pinned: true,
                  actions: trailing != null
                      ? [
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: trailing,
                    )
                  ]
                      : null,
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

