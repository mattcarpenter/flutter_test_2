// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_images.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeImage _$RecipeImageFromJson(Map<String, dynamic> json) => RecipeImage(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      uploadStatus: json['uploadStatus'] as String,
      publicUrl: json['publicUrl'] as String?,
      retryCount: (json['retryCount'] as num).toInt(),
      isCover: json['isCover'] as bool?,
    );

Map<String, dynamic> _$RecipeImageToJson(RecipeImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'uploadStatus': instance.uploadStatus,
      'retryCount': instance.retryCount,
      'isCover': instance.isCover,
      'publicUrl': instance.publicUrl,
    };
