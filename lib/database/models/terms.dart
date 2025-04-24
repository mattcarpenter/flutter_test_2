import 'package:json_annotation/json_annotation.dart';

part 'terms.g.dart';

@JsonSerializable()
class IngredientTerm {
  final String value;
  final String source; // "user", "ai", or "inferred"

  IngredientTerm({
    required this.value,
    required this.source,
  });

  factory IngredientTerm.fromJson(Map<String, dynamic> json) =>
      _$IngredientTermFromJson(json);

  Map<String, dynamic> toJson() => _$IngredientTermToJson(this);
}
