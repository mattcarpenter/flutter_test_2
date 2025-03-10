import 'package:json_annotation/json_annotation.dart';

part 'ingredients.g.dart';

@JsonSerializable()
class Ingredient {
  final String type; // "ingredient" or "section"
  final String name;
  final String? note;

  final String? primaryAmount1Value;
  final String? primaryAmount1Unit;
  final String? primaryAmount1Type;

  final String? primaryAmount2Value;
  final String? primaryAmount2Unit;
  final String? primaryAmount2Type;

  final String? secondaryAmount1Value;
  final String? secondaryAmount1Unit;
  final String? secondaryAmount1Type;

  final String? secondaryAmount2Value;
  final String? secondaryAmount2Unit;
  final String? secondaryAmount2Type;

  Ingredient({
    required this.type,
    required this.name,
    this.note,
    this.primaryAmount1Value,
    this.primaryAmount1Unit,
    this.primaryAmount1Type,
    this.primaryAmount2Value,
    this.primaryAmount2Unit,
    this.primaryAmount2Type,
    this.secondaryAmount1Value,
    this.secondaryAmount1Unit,
    this.secondaryAmount1Type,
    this.secondaryAmount2Value,
    this.secondaryAmount2Unit,
    this.secondaryAmount2Type,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) => _$IngredientFromJson(json);
  Map<String, dynamic> toJson() => _$IngredientToJson(this);
}
