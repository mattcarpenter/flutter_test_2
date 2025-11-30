// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crouton_recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CroutonRecipe _$CroutonRecipeFromJson(Map<String, dynamic> json) =>
    CroutonRecipe(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      serves: (json['serves'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toInt(),
      cookingDuration: (json['cookingDuration'] as num?)?.toInt(),
      defaultScale: (json['defaultScale'] as num?)?.toDouble(),
      webLink: json['webLink'] as String?,
      notes: json['notes'] as String?,
      nutritionalInfo: json['neutritionalInfo'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>?)
          ?.map((e) => CroutonIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>?)
          ?.map((e) => CroutonStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      images:
          (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      folderIDs: (json['folderIDs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isPublicRecipe: json['isPublicRecipe'] as bool?,
    );

Map<String, dynamic> _$CroutonRecipeToJson(CroutonRecipe instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'name': instance.name,
      'serves': instance.serves,
      'duration': instance.duration,
      'cookingDuration': instance.cookingDuration,
      'defaultScale': instance.defaultScale,
      'webLink': instance.webLink,
      'notes': instance.notes,
      'neutritionalInfo': instance.nutritionalInfo,
      'ingredients': instance.ingredients,
      'steps': instance.steps,
      'images': instance.images,
      'tags': instance.tags,
      'folderIDs': instance.folderIDs,
      'isPublicRecipe': instance.isPublicRecipe,
    };

CroutonIngredient _$CroutonIngredientFromJson(Map<String, dynamic> json) =>
    CroutonIngredient(
      uuid: json['uuid'] as String?,
      order: (json['order'] as num?)?.toInt(),
      ingredient: json['ingredient'] == null
          ? null
          : CroutonIngredientInfo.fromJson(
              json['ingredient'] as Map<String, dynamic>),
      quantity: json['quantity'] == null
          ? null
          : CroutonQuantity.fromJson(json['quantity'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CroutonIngredientToJson(CroutonIngredient instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'order': instance.order,
      'ingredient': instance.ingredient,
      'quantity': instance.quantity,
    };

CroutonIngredientInfo _$CroutonIngredientInfoFromJson(
        Map<String, dynamic> json) =>
    CroutonIngredientInfo(
      uuid: json['uuid'] as String?,
      name: json['name'] as String,
    );

Map<String, dynamic> _$CroutonIngredientInfoToJson(
        CroutonIngredientInfo instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'name': instance.name,
    };

CroutonQuantity _$CroutonQuantityFromJson(Map<String, dynamic> json) =>
    CroutonQuantity(
      amount: (json['amount'] as num?)?.toDouble(),
      quantityType: json['quantityType'] as String?,
    );

Map<String, dynamic> _$CroutonQuantityToJson(CroutonQuantity instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'quantityType': instance.quantityType,
    };

CroutonStep _$CroutonStepFromJson(Map<String, dynamic> json) => CroutonStep(
      uuid: json['uuid'] as String?,
      order: (json['order'] as num?)?.toInt(),
      step: json['step'] as String?,
      isSection: json['isSection'] as bool?,
    );

Map<String, dynamic> _$CroutonStepToJson(CroutonStep instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'order': instance.order,
      'step': instance.step,
      'isSection': instance.isSection,
    };
