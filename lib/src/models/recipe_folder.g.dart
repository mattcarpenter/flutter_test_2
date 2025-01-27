// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_folder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeFolder _$RecipeFolderFromJson(Map<String, dynamic> json) => RecipeFolder(
      id: json['id'] as String?,
      name: json['name'] as String,
      parentId: json['parentId'] as String?,
    );

Map<String, dynamic> _$RecipeFolderToJson(RecipeFolder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parentId': instance.parentId,
    };
