import 'package:json_annotation/json_annotation.dart';

part 'paprika_recipe.g.dart';

@JsonSerializable()
class PaprikaPhoto {
  final String? filename;
  final String? data; // base64-encoded image data

  PaprikaPhoto({
    this.filename,
    this.data,
  });

  factory PaprikaPhoto.fromJson(Map<String, dynamic> json) =>
      _$PaprikaPhotoFromJson(json);
  Map<String, dynamic> toJson() => _$PaprikaPhotoToJson(this);
}

@JsonSerializable()
class PaprikaRecipe {
  final String uid;
  final String name;
  final String? description;
  final String? ingredients;
  final String? directions;
  final String? notes;
  final String? source;

  @JsonKey(name: 'source_url')
  final String? sourceUrl;

  @JsonKey(name: 'prep_time')
  final String? prepTime;

  @JsonKey(name: 'cook_time')
  final String? cookTime;

  @JsonKey(name: 'total_time')
  final String? totalTime;

  final String? servings;
  final int? rating;

  @JsonKey(name: 'nutritional_info')
  final String? nutritionalInfo;

  final List<String>? categories;
  final String? photo;

  @JsonKey(name: 'photo_data')
  final String? photoData; // base64-encoded image data

  @JsonKey(name: 'photo_hash')
  final String? photoHash;

  final List<PaprikaPhoto>? photos;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  final String? difficulty;
  final String? created;
  final String? hash;

  PaprikaRecipe({
    required this.uid,
    required this.name,
    this.description,
    this.ingredients,
    this.directions,
    this.notes,
    this.source,
    this.sourceUrl,
    this.prepTime,
    this.cookTime,
    this.totalTime,
    this.servings,
    this.rating,
    this.nutritionalInfo,
    this.categories,
    this.photo,
    this.photoData,
    this.photoHash,
    this.photos,
    this.imageUrl,
    this.difficulty,
    this.created,
    this.hash,
  });

  factory PaprikaRecipe.fromJson(Map<String, dynamic> json) =>
      _$PaprikaRecipeFromJson(json);
  Map<String, dynamic> toJson() => _$PaprikaRecipeToJson(this);
}
