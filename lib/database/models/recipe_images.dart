import 'package:json_annotation/json_annotation.dart';

part 'recipe_images.g.dart';

@JsonSerializable()
class RecipeImage {
  final String id;
  final String fileName;
  final String localBasePath;
  final int? retryCount;
  final bool? isCover;

  RecipeImage({
    required this.id,
    required this.fileName,
    required this.localBasePath,
    this.retryCount,
    this.isCover,
  });

  factory RecipeImage.fromJson(Map<String, dynamic> json) => _$RecipeImageFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeImageToJson(this);

  RecipeImage copyWith({
    String? id,
    String? fileName,
    String? localBasePath,
    int? retryCount,
  }) {
    return RecipeImage(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      localBasePath: localBasePath ?? this.localBasePath,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
