// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_images.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeImage _$RecipeImageFromJson(Map<String, dynamic> json) => RecipeImage(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      publicUrl: json['publicUrl'] as String?,
      isCover: json['isCover'] as bool?,
    );

Map<String, dynamic> _$RecipeImageToJson(RecipeImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'isCover': instance.isCover,
      'publicUrl': instance.publicUrl,
    };
