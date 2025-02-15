import 'dart:io' show Platform;
import 'dart:ui' as ui; // Needed for ImageFilter.blur
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../widgets/extended_clip_rect.dart';

class FolderTile extends StatelessWidget {
  final String folderName;
  final int recipeCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const FolderTile({
    Key? key,
    required this.folderName,
    required this.recipeCount,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  /// Builds the static content of the tile.
  Widget _buildTileContent(BuildContext context) {
    final backgroundColor =
        CupertinoTheme.of(context).scaffoldBackgroundColor;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/images/empty_folder.svg',
            width: 50,
            height: 50,
          ),
          const SizedBox(height: 8),
          Text(
            folderName,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '$recipeCount recipes',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoContextMenu.builder(
        actions: <Widget>[
          CupertinoContextMenuAction(
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ],
        // Use the builder to customize the preview.
        builder: (BuildContext context, Animation<double> animation) {
          // Animate the border radius from normal (12) to the open value.
          final Animation<BorderRadius?> borderRadiusAnimation =
          BorderRadiusTween(
            begin: BorderRadius.circular(12),
            end: BorderRadius.circular(CupertinoContextMenu.kOpenBorderRadius),
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Interval(
                CupertinoContextMenu.animationOpensAt,
                1.0,
                curve: Curves.easeOut,
              ),
            ),
          );

          // Animate the box shadow opacity.
          final Animation<double> shadowOpacityAnimation = Tween<double>(
            begin: 0.0,
            end: 0.25,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Interval(0.0, CupertinoContextMenu.animationOpensAt,
                  curve: Curves.easeOut),
            ),
          );

          final List<BoxShadow> animatedBoxShadows =
          CupertinoContextMenu.kEndBoxShadow.map((boxShadow) {
            return boxShadow.copyWith(
              color: boxShadow.color.withOpacity(shadowOpacityAnimation.value),
            );
          }).toList();

          // Animate the blur, delaying its start until near the end.
          final Animation<double> blurAnimation =
          Tween<double>(begin: 0.0, end: 5.0).animate(
            CurvedAnimation(
              parent: animation,
              curve:
              Interval(0.8, 1.0, curve: Curves.easeOut), // delay the blur
            ),
          );

          // Build the preview widget.
          final Widget animatedPreview = BackdropFilter(
            filter:
            ui.ImageFilter.blur(sigmaX: blurAnimation.value, sigmaY: blurAnimation.value),
            child: FittedBox(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: animatedBoxShadows,
                  ),
                  // You can optionally add symmetric padding here if desired.
                  child: ClipRRect(
                    borderRadius:
                    borderRadiusAnimation.value ?? BorderRadius.circular(12),
                    child: _buildTileContent(context),
                  ),
                ),

            ),
          );

          // Wrap the preview in a GestureDetector so that taps are handled.
          return GestureDetector(
            onTap: onTap,
            child: ExtendedClipRect(
              extraVerticalPadding: 10.0, // tweak as needed
              child: animatedPreview,
            ),
          );
        },
      );
    } else {
      // For non-iOS platforms, use the default behavior.
      return GestureDetector(
        onTap: onTap,
        onLongPress: () async {
          // Get the RenderBox of the current widget
          final RenderBox button = context.findRenderObject() as RenderBox;
          // Get position relative to the nearest Overlay
          final Offset position = button.localToGlobal(
              Offset.zero,
              ancestor: Overlay.of(context).context.findRenderObject()
          );
          final Size size = button.size;

          final selected = await showMenu<String>(
            context: context,
            position: RelativeRect.fromLTRB(
              position.dx,
              position.dy,
              position.dx + size.width,
              position.dy + size.height,
            ),
            items: const [
              PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          );
          if (selected == 'delete') {
            onDelete();
          }
        },
        child: _buildTileContent(context),
      );
    }
  }
}
