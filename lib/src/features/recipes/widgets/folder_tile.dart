import 'dart:io' show Platform;
import 'dart:ui' as ui; // Needed for ImageFilter.blur
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../widgets/extended_clip_rect.dart';

class FolderTile extends StatefulWidget {
  final String folderName;
  final int recipeCount;
  final VoidCallback onTap;
  /// Instead of removing the item immediately, the onDelete callback will be called
  /// after the deletion animation completes.
  final VoidCallback onDelete;

  const FolderTile({
    Key? key,
    required this.folderName,
    required this.recipeCount,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  _FolderTileState createState() => _FolderTileState();
}

class _FolderTileState extends State<FolderTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutExpo,
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(curve);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(curve);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDelete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startDeletionAnimation() {
    if (!_isDeleting) {
      setState(() {
        _isDeleting = true;
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  /// Builds the static content of the tile.
  Widget _buildTileContent(BuildContext context) {
    final backgroundColor = CupertinoTheme.of(context).scaffoldBackgroundColor;
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
            widget.folderName,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '${widget.recipeCount} recipes',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (Platform.isIOS) {
      content = CupertinoContextMenu.builder(
        actions: <Widget>[
          Builder(
            builder: (BuildContext actionContext) {
              return CupertinoContextMenuAction(
                child: const Text('Delete'),
                onPressed: () {
                  Navigator.pop(actionContext);
                  _startDeletionAnimation();
                },
              );
            },
          ),
        ],
        // Customize the preview.
        builder: (BuildContext previewContext, Animation<double> animation) {
          // Animate the border radius.
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
              curve: Interval(
                0.0,
                CupertinoContextMenu.animationOpensAt,
                curve: Curves.easeOut,
              ),
            ),
          );

          final List<BoxShadow> animatedBoxShadows =
          CupertinoContextMenu.kEndBoxShadow.map((boxShadow) {
            return boxShadow.copyWith(
              color: boxShadow.color.withOpacity(shadowOpacityAnimation.value),
            );
          }).toList();

          // Animate the blur, delaying its start until near the end.
          final Animation<double> blurAnimation = Tween<double>(
            begin: 0.0,
            end: 5.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Interval(
                0.8,
                1.0,
                curve: Curves.easeOut,
              ),
            ),
          );

          // Build the preview widget.
          final Widget animatedPreview = BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: blurAnimation.value,
              sigmaY: blurAnimation.value,
            ),
            child: FittedBox(
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: animatedBoxShadows,
                ),
                child: ClipRRect(
                  borderRadius:
                  borderRadiusAnimation.value ?? BorderRadius.circular(12),
                  child: _buildTileContent(previewContext),
                ),
              ),
            ),
          );

          return GestureDetector(
            onTap: widget.onTap,
            child: ExtendedClipRect(
              extraVerticalPadding: 10.0,
              child: animatedPreview,
            ),
          );
        },
      );
    } else {
      content = GestureDetector(
        onTap: widget.onTap,
        onLongPress: () async {
          final RenderBox button = context.findRenderObject() as RenderBox;
          final Offset position = button.localToGlobal(
            Offset.zero,
            ancestor: Overlay.of(context).context.findRenderObject(),
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
            _startDeletionAnimation();
          }
        },
        child: _buildTileContent(context),
      );
    }

    // Wrap the entire tile in fade and scale transitions.
    return FadeTransition(
      opacity: _opacityAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: content,
      ),
    );
  }
}
