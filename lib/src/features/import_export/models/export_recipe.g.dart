// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExportRecipe _$ExportRecipeFromJson(Map<String, dynamic> json) => ExportRecipe(
      title: json['title'] as String,
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toInt(),
      language: json['language'] as String?,
      servings: (json['servings'] as num?)?.toInt(),
      prepTime: (json['prepTime'] as num?)?.toInt(),
      cookTime: (json['cookTime'] as num?)?.toInt(),
      totalTime: (json['totalTime'] as num?)?.toInt(),
      source: json['source'] as String?,
      nutrition: json['nutrition'] as String?,
      generalNotes: json['generalNotes'] as String?,
      createdAt: (json['createdAt'] as num?)?.toInt(),
      updatedAt: (json['updatedAt'] as num?)?.toInt(),
      pinned: json['pinned'] as bool?,
      folderNames: (json['folderNames'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      tagNames: (json['tagNames'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      ingredients: (json['ingredients'] as List<dynamic>?)
          ?.map((e) => ExportIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>?)
          ?.map((e) => ExportStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ExportImage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ExportRecipeToJson(ExportRecipe instance) =>
    <String, dynamic>{
      'title': instance.title,
      if (instance.description case final value?) 'description': value,
      if (instance.rating case final value?) 'rating': value,
      if (instance.language case final value?) 'language': value,
      if (instance.servings case final value?) 'servings': value,
      if (instance.prepTime case final value?) 'prepTime': value,
      if (instance.cookTime case final value?) 'cookTime': value,
      if (instance.totalTime case final value?) 'totalTime': value,
      if (instance.source case final value?) 'source': value,
      if (instance.nutrition case final value?) 'nutrition': value,
      if (instance.generalNotes case final value?) 'generalNotes': value,
      if (instance.createdAt case final value?) 'createdAt': value,
      if (instance.updatedAt case final value?) 'updatedAt': value,
      if (instance.pinned case final value?) 'pinned': value,
      if (instance.folderNames case final value?) 'folderNames': value,
      if (instance.tagNames case final value?) 'tagNames': value,
      if (instance.ingredients case final value?) 'ingredients': value,
      if (instance.steps case final value?) 'steps': value,
      if (instance.images case final value?) 'images': value,
    };

ExportIngredient _$ExportIngredientFromJson(Map<String, dynamic> json) =>
    ExportIngredient(
      type: json['type'] as String,
      name: json['name'] as String,
      note: json['note'] as String?,
      terms: (json['terms'] as List<dynamic>?)
          ?.map((e) => ExportIngredientTerm.fromJson(e as Map<String, dynamic>))
          .toList(),
      isCanonicalised: json['isCanonicalised'] as bool?,
      category: json['category'] as String?,
    );

Map<String, dynamic> _$ExportIngredientToJson(ExportIngredient instance) =>
    <String, dynamic>{
      'type': instance.type,
      'name': instance.name,
      if (instance.note case final value?) 'note': value,
      if (instance.terms case final value?) 'terms': value,
      if (instance.isCanonicalised case final value?) 'isCanonicalised': value,
      if (instance.category case final value?) 'category': value,
    };

ExportIngredientTerm _$ExportIngredientTermFromJson(
        Map<String, dynamic> json) =>
    ExportIngredientTerm(
      value: json['value'] as String,
      source: json['source'] as String,
      sort: (json['sort'] as num).toInt(),
    );

Map<String, dynamic> _$ExportIngredientTermToJson(
        ExportIngredientTerm instance) =>
    <String, dynamic>{
      'value': instance.value,
      'source': instance.source,
      'sort': instance.sort,
    };

ExportStep _$ExportStepFromJson(Map<String, dynamic> json) => ExportStep(
      type: json['type'] as String,
      text: json['text'] as String,
      note: json['note'] as String?,
      timerDurationSeconds: (json['timerDurationSeconds'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ExportStepToJson(ExportStep instance) =>
    <String, dynamic>{
      'type': instance.type,
      'text': instance.text,
      if (instance.note case final value?) 'note': value,
      if (instance.timerDurationSeconds case final value?)
        'timerDurationSeconds': value,
    };

ExportImage _$ExportImageFromJson(Map<String, dynamic> json) => ExportImage(
      isCover: json['isCover'] as bool?,
      data: json['data'] as String?,
      publicUrl: json['publicUrl'] as String?,
    );

Map<String, dynamic> _$ExportImageToJson(ExportImage instance) =>
    <String, dynamic>{
      if (instance.isCover case final value?) 'isCover': value,
      if (instance.data case final value?) 'data': value,
      if (instance.publicUrl case final value?) 'publicUrl': value,
    };
