// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paprika_recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaprikaPhoto _$PaprikaPhotoFromJson(Map<String, dynamic> json) => PaprikaPhoto(
      filename: json['filename'] as String?,
      data: json['data'] as String?,
    );

Map<String, dynamic> _$PaprikaPhotoToJson(PaprikaPhoto instance) =>
    <String, dynamic>{
      'filename': instance.filename,
      'data': instance.data,
    };

PaprikaRecipe _$PaprikaRecipeFromJson(Map<String, dynamic> json) =>
    PaprikaRecipe(
      uid: json['uid'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      ingredients: json['ingredients'] as String?,
      directions: json['directions'] as String?,
      notes: json['notes'] as String?,
      source: json['source'] as String?,
      sourceUrl: json['source_url'] as String?,
      prepTime: json['prep_time'] as String?,
      cookTime: json['cook_time'] as String?,
      totalTime: json['total_time'] as String?,
      servings: json['servings'] as String?,
      rating: (json['rating'] as num?)?.toInt(),
      nutritionalInfo: json['nutritional_info'] as String?,
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      photo: json['photo'] as String?,
      photoData: json['photo_data'] as String?,
      photoHash: json['photo_hash'] as String?,
      photos: (json['photos'] as List<dynamic>?)
          ?.map((e) => PaprikaPhoto.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageUrl: json['image_url'] as String?,
      difficulty: json['difficulty'] as String?,
      created: json['created'] as String?,
      hash: json['hash'] as String?,
    );

Map<String, dynamic> _$PaprikaRecipeToJson(PaprikaRecipe instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'description': instance.description,
      'ingredients': instance.ingredients,
      'directions': instance.directions,
      'notes': instance.notes,
      'source': instance.source,
      'source_url': instance.sourceUrl,
      'prep_time': instance.prepTime,
      'cook_time': instance.cookTime,
      'total_time': instance.totalTime,
      'servings': instance.servings,
      'rating': instance.rating,
      'nutritional_info': instance.nutritionalInfo,
      'categories': instance.categories,
      'photo': instance.photo,
      'photo_data': instance.photoData,
      'photo_hash': instance.photoHash,
      'photos': instance.photos,
      'image_url': instance.imageUrl,
      'difficulty': instance.difficulty,
      'created': instance.created,
      'hash': instance.hash,
    };
