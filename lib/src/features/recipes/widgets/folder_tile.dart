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

class _FolderTileState extends State<FolderTile> with SingleTickerProviderStateMixin {
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
          child: _ComplexContextMenu(
            folderName: widget.folderName,
            recipeCount: widget.recipeCount,
            onDelete: _startDeletionAnimation,
          ),
        ),
      ),
    );
  }
}

class _ComplexContextMenu extends StatelessWidget {
  final String folderName;
  final int recipeCount;
  final VoidCallback onDelete;

  const _ComplexContextMenu({
    Key? key,
    required this.folderName,
    required this.recipeCount,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ContextMenuWidget(
      // Reuse the common folder tile content for all three states.
      liftBuilder: (context, child) => _FolderTileContent(folderName, recipeCount),
      previewBuilder: (context, child) => _FolderTileContent(folderName, recipeCount, isPreview: true),
      child: _FolderTileContent(folderName, recipeCount, isChild: true),
      menuProvider: (_) {
        return Menu(
          children: [
            MenuAction(
              title: 'Delete Folder',
              image: MenuImage.icon(Icons.delete),
              attributes: const MenuActionAttributes(destructive: true),
              callback: onDelete,
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
