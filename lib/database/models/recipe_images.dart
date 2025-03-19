import 'package:json_annotation/json_annotation.dart';
import 'package:path_provider/path_provider.dart';

part 'recipe_images.g.dart';

enum RecipeImageSize { large, small }

@JsonSerializable()
class RecipeImage {
  final String id;
  final String fileName;
  final bool? isCover;
  final String? publicUrl;

  RecipeImage({
    required this.id,
    required this.fileName,
    this.publicUrl,
    this.isCover,
  });

  factory RecipeImage.fromJson(Map<String, dynamic> json) => _$RecipeImageFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeImageToJson(this);

  RecipeImage copyWith({
    String? id,
    String? fileName,
    int? retryCount,
    String? publicUrl,
  }) {
    return RecipeImage(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      publicUrl: publicUrl ?? this.publicUrl,
    );
  }

  /// Dynamically resolves the full file path from the stored filename
  Future<String> getFullPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }

  /// Resolves the full path synchronously (useful when not in an async context)
  static Future<String> resolveFullPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }

  String? getPublicUrlForSize(RecipeImageSize size) {
    if (size == RecipeImageSize.large) {
      return this.publicUrl;
    } else if (this.publicUrl != null) {
      final uri = Uri.parse(this.publicUrl!);
      final filename = uri.pathSegments.last;
      final dotIndex = filename.lastIndexOf('.');

      if (dotIndex != -1) {
        final newFilename = '${filename.substring(0, dotIndex)}_small${filename.substring(dotIndex)}';
        return this.publicUrl!.replaceFirst(filename, newFilename);
      }
    }
    return null;
  }

  static RecipeImage? getCoverImage(List<RecipeImage>? images) {
    if (images == null || images.isEmpty) {
      return null;
    }
    return images.firstWhere((element) => element.isCover == true, orElse: () => images.first);
  }
}
