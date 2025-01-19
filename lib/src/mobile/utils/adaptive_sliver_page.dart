import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A shared sliver scaffold that adapts based on the platform.
/// Large-title on iOS, standard SliverAppBar on Android.
/// Includes a LayoutBuilder for accessing BoxConstraints.
class AdaptiveSliverPage extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? trailing;
  final Widget? leading;

  const AdaptiveSliverPage({
    Key? key,
    required this.title,
    required this.body,
    this.trailing,
    this.leading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoTabView(
      builder: (BuildContext context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final double screenWidth = MediaQuery
                .of(context)
                .size
                .width;
            final double pageWidth = constraints.maxWidth;
            final bool isTablet = MediaQuery
                .of(context)
                .size
                .shortestSide >= 600;

            // Same dynamic padding logic
            final double padding = (screenWidth - pageWidth > 50)
                ? 0
                : (isTablet ? 50 - (screenWidth - pageWidth) : 0);

            if (Platform.isIOS) {
              // iOS: Use CupertinoPageScaffold with CupertinoSliverNavigationBar
              return CupertinoPageScaffold(
                child: CustomScrollView(
                  slivers: [
                    CupertinoSliverNavigationBar(
                      largeTitle: Text(title),
                      trailing: trailing,
                      leading: leading != null ? Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding),
                        child: leading,
                      ) : null,
                    ),
                    SliverFillRemaining(child: Builder(builder: (BuildContext context)  {return body; })),
                  ],
                ),
              );
            } else {
              // Android: Use Scaffold with a SliverAppBar
              return Scaffold(
                body: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      title: Text(title),
                      floating: true,
                      pinned: true,
                      actions: trailing != null
                          ? [trailing!]
                          : null,
                      leading: leading,
                    ),
                    SliverFillRemaining(child: body),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }
}
