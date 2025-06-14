// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_plan_items.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MealPlanItem _$MealPlanItemFromJson(Map<String, dynamic> json) => MealPlanItem(
      id: json['id'] as String,
      type: json['type'] as String,
      position: (json['position'] as num).toInt(),
      recipeId: json['recipeId'] as String?,
      recipeTitle: json['recipeTitle'] as String?,
      noteText: json['noteText'] as String?,
      noteTitle: json['noteTitle'] as String?,
    );

Map<String, dynamic> _$MealPlanItemToJson(MealPlanItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'position': instance.position,
      'recipeId': instance.recipeId,
      'recipeTitle': instance.recipeTitle,
      'noteText': instance.noteText,
      'noteTitle': instance.noteTitle,
    };
