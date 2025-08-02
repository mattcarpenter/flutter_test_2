import 'package:flutter/material.dart';

/// A widget that enables edge-to-edge horizontal scrolling content
/// while maintaining proper padding for non-scrollable elements.
/// 
/// This widget extends the scrollable area beyond the parent's horizontal
/// padding to create an edge-to-edge scrolling effect.
class EdgeToEdgeScrollSection extends StatelessWidget {
  final Widget? header;
  final Widget scrollableContent;
  final double scrollableHeight;
  final double horizontalPaddingToNegate;
  
  const EdgeToEdgeScrollSection({
    super.key,
    this.header,
    required this.scrollableContent,
    required this.scrollableHeight,
    this.horizontalPaddingToNegate = 16.0, // Default modal padding
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header maintains original padding
        if (header != null) header!,
        
        // Use Transform to shift content without affecting layout
        Transform.translate(
          offset: Offset(-horizontalPaddingToNegate, 0),
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            maxWidth: MediaQuery.of(context).size.width,
            child: SizedBox(
              height: scrollableHeight,
              width: MediaQuery.of(context).size.width,
              child: scrollableContent,
            ),
          ),
        ),
      ],
    );
  }
}