import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LocalOrNetworkImage extends StatelessWidget {
  final String filePath;
  final String url;
  final double? height;
  final double? width;
  final BoxFit fit;

  const LocalOrNetworkImage({
    super.key,
    required this.filePath,
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    File localFile = File(filePath);

    return FutureBuilder<bool>(
      future: localFile.exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: height,
            width: width,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          // Local file exists, load from disk
          return Image.file(
            localFile,
            height: height,
            width: width,
            fit: fit,
          );
        } else {
          // Fallback to network image
          return CachedNetworkImage(
            imageUrl: url,
            height: height,
            width: width,
            fit: fit,
            placeholder: (context, url) => SizedBox(
              height: height,
              width: width,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => SizedBox(
              height: height,
              width: width,
              child: const Center(child: Icon(Icons.error, color: Colors.red)),
            ),
          );
        }
      },
    );
  }
}
