import 'package:flutter/material.dart';

import 'sample_item.dart';
import 'dart:ui';  // For ImageFilter

// https://pub.dev/packages/macos_window_utils

/// Displays a list of SampleItems.
class SampleItemListView extends StatelessWidget {
  const SampleItemListView({
    super.key,
    this.items = const [SampleItem(1), SampleItem(2), SampleItem(3)],
  });

  static const routeName = '/';

  final List<SampleItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Our "sidebar"
          SizedBox(
            width: 250,
            child: Stack(
              children: [
                // 1. Background container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                  ),
                ),
                // 2. The blur layer
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
                // 3. Sidebar content goes here
                const Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home, color: Colors.white),
                      SizedBox(height: 20),
                      Icon(Icons.settings, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content area
          Expanded(
            child: Center(
              child: Text(
                'Main content goes here',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
