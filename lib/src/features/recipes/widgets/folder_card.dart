import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_context_menu/super_context_menu.dart';
import '../../../providers/folder_thumbnail_provider.dart';
import '../../../widgets/local_or_network_image.dart';
import '../../../../database/models/recipe_images.dart';

class FolderCard extends ConsumerStatefulWidget {
  final String folderId;
  final String folderName;
  final int recipeCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const FolderCard({
    Key? key,
    required this.folderId,
    required this.folderName,
    required this.recipeCount,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  ConsumerState<FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends ConsumerState<FolderCard> with SingleTickerProviderStateMixin {
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
          child: _FolderCardContextMenu(
            folderId: widget.folderId,
            folderName: widget.folderName,
            recipeCount: widget.recipeCount,
            onDelete: _startDeletionAnimation,
          ),
        ),
      ),
    );
  }
}

class _FolderCardContextMenu extends ConsumerWidget {
  final String folderId;
  final String folderName;
  final int recipeCount;
  final VoidCallback onDelete;

  const _FolderCardContextMenu({
    Key? key,
    required this.folderId,
    required this.folderName,
    required this.recipeCount,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContextMenuWidget(
      liftBuilder: (context, child) => _FolderCardContent(
        folderId: folderId,
        folderName: folderName,
        recipeCount: recipeCount,
      ),
      previewBuilder: (context, child) => _FolderCardContent(
        folderId: folderId,
        folderName: folderName,
        recipeCount: recipeCount,
        isPreview: true,
      ),
      child: _FolderCardContent(
        folderId: folderId,
        folderName: folderName,
        recipeCount: recipeCount,
        isChild: true,
      ),
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

class _FolderCardContent extends ConsumerWidget {
  final String folderId;
  final String folderName;
  final int recipeCount;
  final bool isPreview;
  final bool isChild;

  const _FolderCardContent({
    Key? key,
    required this.folderId,
    required this.folderName,
    required this.recipeCount,
    this.isPreview = false,
    this.isChild = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = CupertinoTheme.of(context).scaffoldBackgroundColor;
    final thumbnailAsyncValue = ref.watch(folderThumbnailProvider(folderId));

    return Container(
      padding: const EdgeInsets.all(8.0), // Reduced padding
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: CupertinoColors.systemGrey4, // Middle gray - darker than systemGrey5
          width: 0.5, // Keep thin stroke
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          // Thumbnail section (left) - made square
          Container(
            width: 48, // Smaller and square
            height: 48, // Same as width for square
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.0), // Slightly smaller radius
              color: CupertinoColors.systemGrey6,
            ),
            clipBehavior: Clip.hardEdge,
            child: thumbnailAsyncValue.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, stack) => _buildFolderIcon(),
              data: (thumbnailImage) => _ThumbnailImage(thumbnailImage: thumbnailImage),
            ),
          ),
          
          const SizedBox(width: 8.0), // Reduced spacing
          
          // Text content section (right)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Important: minimize column height
              children: [
                Text(
                  folderName,
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .textStyle
                      .copyWith(
                        fontSize: 14, // Smaller font
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1, // Only 1 line
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1.0), // Reduced spacing
                Text(
                  '$recipeCount recipes',
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .textStyle
                      .copyWith(
                        fontSize: 12, // Smaller font
                        color: CupertinoColors.secondaryLabel,
                      ),
                  maxLines: 1, // Only 1 line
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderIcon() {
    return const Center(
      child: Icon(
        CupertinoIcons.folder,
        size: 20, // Smaller icon
        color: CupertinoColors.systemGrey2,
      ),
    );
  }
}

// Stateful thumbnail widget that caches image state
class _ThumbnailImage extends StatefulWidget {
  final RecipeImage? thumbnailImage;

  const _ThumbnailImage({Key? key, required this.thumbnailImage}) : super(key: key);

  @override
  State<_ThumbnailImage> createState() => _ThumbnailImageState();
}

class _ThumbnailImageState extends State<_ThumbnailImage> {
  String? _cachedImagePath;
  String? _cachedImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(_ThumbnailImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reload if the thumbnailImage actually changed
    if (oldWidget.thumbnailImage != widget.thumbnailImage) {
      _loadImage();
    }
  }

  void _loadImage() async {
    if (widget.thumbnailImage == null) {
      setState(() {
        _cachedImagePath = null;
        _cachedImageUrl = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final imagePath = await widget.thumbnailImage!.getFullPath();
      final imageUrl = widget.thumbnailImage!.getPublicUrlForSize(RecipeImageSize.small) ?? '';
      
      if (mounted) {
        setState(() {
          _cachedImagePath = imagePath;
          _cachedImageUrl = imageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cachedImagePath = null;
          _cachedImageUrl = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_cachedImagePath == null || _cachedImageUrl == null) {
      return _buildFolderIcon();
    }

    return LocalOrNetworkImage(
      filePath: _cachedImagePath!,
      url: _cachedImageUrl!,
      fit: BoxFit.cover,
    );
  }

  Widget _buildFolderIcon() {
    return const Center(
      child: Icon(
        CupertinoIcons.folder,
        size: 20,
        color: CupertinoColors.systemGrey2,
      ),
    );
  }
}