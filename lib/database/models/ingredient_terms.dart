import 'dart:ffi';

import 'package:drift/drift.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ingredient_terms.g.dart';

@JsonSerializable()
class IngredientTerm {
  final String value;
  final String source; // "user", "ai", or "inferred"
  final int sort;

  IngredientTerm({
    required this.value,
    required this.source,
    required this.sort,
  });

  factory IngredientTerm.fromJson(Map<String, dynamic> json) =>
      _$IngredientTermFromJson(json);

  Map<String, dynamic> toJson() => _$IngredientTermToJson(this);
}
