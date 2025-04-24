// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pantry_item_terms.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PantryItemTerm _$PantryItemTermFromJson(Map<String, dynamic> json) =>
    PantryItemTerm(
      value: json['value'] as String,
      source: json['source'] as String,
      sort: (json['sort'] as num).toInt(),
    );

Map<String, dynamic> _$PantryItemTermToJson(PantryItemTerm instance) =>
    <String, dynamic>{
      'value': instance.value,
      'source': instance.source,
      'sort': instance.sort,
    };
