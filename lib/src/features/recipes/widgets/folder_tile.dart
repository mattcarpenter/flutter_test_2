import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:super_context_menu/super_context_menu.dart';

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

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: _startDeletionAnimation,
          child: _ComplexContextMenu(
            folderName: widget.folderName,
            recipeCount: widget.recipeCount,
          ),
        ),
      ),
    );
  }
}

class _ComplexContextMenu extends StatelessWidget {
  final String folderName;
  final int recipeCount;

  const _ComplexContextMenu({
    Key? key,
    required this.folderName,
    required this.recipeCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ContextMenuWidget(
      liftBuilder: (context, child) => _FolderTileContent(folderName, recipeCount),
      previewBuilder: (context, child) => _FolderTileContent(folderName, recipeCount, isPreview: true),
      child: _FolderTileContent(folderName, recipeCount, isChild: true),
      menuProvider: (_) {
        return Menu(
          children: [
            MenuAction(
              image: MenuImage.icon(Icons.access_time),
              title: 'Menu Item 1',
              callback: () {},
            ),
            MenuAction(
              title: 'Disabled Menu Item',
              image: MenuImage.icon(Icons.replay_outlined),
              attributes: const MenuActionAttributes(disabled: true),
              callback: () {},
            ),
            MenuAction(
              title: 'Destructive Menu Item',
              image: MenuImage.icon(Icons.delete),
              attributes: const MenuActionAttributes(destructive: true),
              callback: () {},
            ),
            MenuSeparator(),
            Menu(title: 'Submenu', children: [
              MenuAction(title: 'Submenu Item 1', callback: () {}),
              MenuAction(title: 'Submenu Item 2', callback: () {}),
            ]),
            Menu(title: 'Deferred Item Example', children: [
              MenuAction(title: 'Leading Item', callback: () {}),
              DeferredMenuElement((_) async {
                await Future.delayed(const Duration(seconds: 2));
                return [
                  MenuSeparator(),
                  MenuAction(title: 'Lazily Loaded Item', callback: () {}),
                  Menu(title: 'Lazily Loaded Submenu', children: [
                    MenuAction(title: 'Submenu Item 1', callback: () {}),
                    MenuAction(title: 'Submenu Item 2', callback: () {}),
                  ]),
                  MenuSeparator(),
                ];
              }),
              MenuAction(title: 'Trailing Item', callback: () {}),
            ]),
            MenuSeparator(),
            MenuAction(
              title: 'Checked Menu Item',
              state: MenuActionState.checkOn,
              callback: () {},
            ),
            MenuAction(
              title: 'Menu Item in Mixed State',
              state: MenuActionState.checkMixed,
              callback: () {},
            ),
          ],
        );
      },
    );
  }
}

class _FolderTileContent extends StatelessWidget {
  final String folderName;
  final int recipeCount;
  final bool isPreview;
  final bool isChild;

  const _FolderTileContent(
      this.folderName,
      this.recipeCount, {
        this.isPreview = false,
        this.isChild = false,
      });

  @override
  Widget build(BuildContext context) {
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
}


class Item extends StatelessWidget {
  const Item({
    super.key,
    this.color = Colors.blue,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final EdgeInsets padding;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: child,
      ),
    );
  }
}


// _startDeletionAnimation();

// return GestureDetector(
//             onTap: widget.onTap,
//             child
