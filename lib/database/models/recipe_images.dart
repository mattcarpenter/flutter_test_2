import 'package:json_annotation/json_annotation.dart';
import 'package:path_provider/path_provider.dart';

part 'recipe_images.g.dart';

@JsonSerializable()
class RecipeImage {
  final String id;
  final String fileName;
  final String uploadStatus;
  final int? retryCount;
  final bool? isCover;

  RecipeImage({
    required this.id,
    required this.fileName,
    required this.uploadStatus,
    this.retryCount,
    this.isCover,
  });

  factory RecipeImage.fromJson(Map<String, dynamic> json) => _$RecipeImageFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeImageToJson(this);

  RecipeImage copyWith({
    String? id,
    String? fileName,
    String? uploadStatus,
    int? retryCount,
  }) {
    return RecipeImage(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      retryCount: retryCount ?? this.retryCount,
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
}
