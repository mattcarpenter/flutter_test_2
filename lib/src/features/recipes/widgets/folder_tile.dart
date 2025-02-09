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
    // Wrap in IntrinsicWidth and IntrinsicHeight to match content size
    final tileContent = IntrinsicWidth(child: IntrinsicHeight( child: Container(
          color: const Color.fromARGB(255, 255, 255, 0), // Debug color
          padding: const EdgeInsets.all(8),
          child: Center(child: Column(
            mainAxisSize: MainAxisSize.min, // Prevent unwanted expansion
            children: [
              SvgPicture.asset(
                'assets/images/empty_folder.svg',
                width: 64,
                height: 64,
              ),
              const SizedBox(height: 8),
              Text(
                folderName,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
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
