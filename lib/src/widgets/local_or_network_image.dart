import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class LocalOrNetworkImage extends StatefulWidget {
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
  State<LocalOrNetworkImage> createState() => _LocalOrNetworkImageState();
}

class _LocalOrNetworkImageState extends State<LocalOrNetworkImage> {
  bool? _fileExists;
  bool _isLoading = true;
  late File localFile;

  @override
  void initState() {
    super.initState();
    _checkFileExists();
  }

  @override
  void didUpdateWidget(LocalOrNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only re-check if the file path changes
    if (oldWidget.filePath != widget.filePath) {
      _isLoading = true;
      _fileExists = null;
      _checkFileExists();
    }
  }

  Future<void> _checkFileExists() async {
    if (widget.filePath.isEmpty) {
      setState(() {
        _fileExists = false;
        _isLoading = false;
      });
      return;
    }

    localFile = File(widget.filePath);
    final exists = await localFile.exists();

    if (mounted) {
      setState(() {
        _fileExists = exists;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we're still loading, show the placeholder
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: widget.height,
          width: widget.width,
          color: Colors.white,
        ),
      );
    }

    // If file exists, show local file
    if (_fileExists == true) {
      return Image.file(
        localFile,
        height: widget.height,
        width: widget.width,
        fit: widget.fit,
      );
    }

    // Otherwise show network image if URL exists
    if (widget.url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.url,
        height: widget.height,
        width: widget.width,
        fit: widget.fit,
        placeholder: (context, url) => SizedBox(
          height: widget.height,
          width: widget.width,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => SizedBox(
          height: widget.height,
          width: widget.width,
          child: const Center(child: Icon(Icons.error, color: Colors.red)),
        ),
      );
    }

    // Fallback when neither local file exists nor URL is provided
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: const Center(
        child: Icon(Icons.no_photography, color: Colors.grey),
      ),
    );
  }
}
