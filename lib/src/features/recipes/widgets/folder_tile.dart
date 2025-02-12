import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    // Theme Colors
    final Color backgroundColor = isDarkMode ? CupertinoTheme.of(context).barBackgroundColor : CupertinoTheme.of(context).scaffoldBackgroundColor;
    // Wrap in IntrinsicWidth and IntrinsicHeight to match content size
    final tileContent = IntrinsicWidth(child: IntrinsicHeight( child: Container(
          color: backgroundColor, // Debug color
          child: Center(child: Column(
            mainAxisSize: MainAxisSize.min, // Prevent unwanted expansion
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
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '$recipeCount recipes',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        )
    )
    )
    );
    if (Platform.isIOS) {
      return CupertinoContextMenu(
        enableHapticFeedback: true,
        actions: <Widget>[
          CupertinoContextMenuAction(
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ],
        child: GestureDetector(
          onTap: onTap,
          child: tileContent,
        ),
      );
    } else {
      return GestureDetector(
        onTap: onTap,
        onLongPress: () async {
          final selected = await showMenu<String>(
            context: context,
            position: RelativeRect.fromLTRB(100, 100, 100, 100),
            items: [
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          );
          if (selected == 'delete') {
            onDelete();
          }
        },
        child: tileContent,
      );
    }
  }
}
