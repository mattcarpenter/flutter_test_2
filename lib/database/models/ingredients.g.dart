// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredients.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Ingredient _$IngredientFromJson(Map<String, dynamic> json) => Ingredient(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      note: json['note'] as String?,
      primaryAmount1Value: json['primaryAmount1Value'] as String?,
      primaryAmount1Unit: json['primaryAmount1Unit'] as String?,
      primaryAmount1Type: json['primaryAmount1Type'] as String?,
      primaryAmount2Value: json['primaryAmount2Value'] as String?,
      primaryAmount2Unit: json['primaryAmount2Unit'] as String?,
      primaryAmount2Type: json['primaryAmount2Type'] as String?,
      secondaryAmount1Value: json['secondaryAmount1Value'] as String?,
      secondaryAmount1Unit: json['secondaryAmount1Unit'] as String?,
      secondaryAmount1Type: json['secondaryAmount1Type'] as String?,
      secondaryAmount2Value: json['secondaryAmount2Value'] as String?,
      secondaryAmount2Unit: json['secondaryAmount2Unit'] as String?,
      secondaryAmount2Type: json['secondaryAmount2Type'] as String?,
      terms: (json['terms'] as List<dynamic>?)
          ?.map((e) => IngredientTerm.fromJson(e as Map<String, dynamic>))
          .toList(),
      isCanonicalised: json['isCanonicalised'] as bool? ?? false,
    );

Map<String, dynamic> _$IngredientToJson(Ingredient instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'name': instance.name,
      'note': instance.note,
      'primaryAmount1Value': instance.primaryAmount1Value,
      'primaryAmount1Unit': instance.primaryAmount1Unit,
      'primaryAmount1Type': instance.primaryAmount1Type,
      'primaryAmount2Value': instance.primaryAmount2Value,
      'primaryAmount2Unit': instance.primaryAmount2Unit,
      'primaryAmount2Type': instance.primaryAmount2Type,
      'secondaryAmount1Value': instance.secondaryAmount1Value,
      'secondaryAmount1Unit': instance.secondaryAmount1Unit,
      'secondaryAmount1Type': instance.secondaryAmount1Type,
      'secondaryAmount2Value': instance.secondaryAmount2Value,
      'secondaryAmount2Unit': instance.secondaryAmount2Unit,
      'secondaryAmount2Type': instance.secondaryAmount2Type,
      'terms': instance.terms,
      'isCanonicalised': instance.isCanonicalised,
    };
