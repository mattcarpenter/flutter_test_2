// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_terms.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IngredientTerm _$IngredientTermFromJson(Map<String, dynamic> json) =>
    IngredientTerm(
      value: json['value'] as String,
      source: json['source'] as String,
      sort: (json['sort'] as num).toInt(),
      exclusive: json['exclusive'] as bool,
    );

Map<String, dynamic> _$IngredientTermToJson(IngredientTerm instance) =>
    <String, dynamic>{
      'value': instance.value,
      'source': instance.source,
      'sort': instance.sort,
      'exclusive': instance.exclusive,
    };
