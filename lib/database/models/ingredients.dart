import 'package:json_annotation/json_annotation.dart';
import 'ingredient_terms.dart';

part 'ingredients.g.dart';

@JsonSerializable()
class Ingredient {
  final String id;
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

  final List<IngredientTerm>? terms; // Optional terms attached to this ingredient

  Ingredient({
    required this.id,
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
    this.terms,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) => _$IngredientFromJson(json);
  Map<String, dynamic> toJson() => _$IngredientToJson(this);

  Ingredient copyWith({
    String? id,
    String? type,
    String? name,
    String? note,
    String? primaryAmount1Value,
    String? primaryAmount1Unit,
    String? primaryAmount1Type,
    String? primaryAmount2Value,
    String? primaryAmount2Unit,
    String? primaryAmount2Type,
    String? secondaryAmount1Value,
    String? secondaryAmount1Unit,
    String? secondaryAmount1Type,
    String? secondaryAmount2Value,
    String? secondaryAmount2Unit,
    String? secondaryAmount2Type,
    List<IngredientTerm>? terms,
  }) {
    return Ingredient(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      note: note ?? this.note,
      primaryAmount1Value: primaryAmount1Value ?? this.primaryAmount1Value,
      primaryAmount1Unit: primaryAmount1Unit ?? this.primaryAmount1Unit,
      primaryAmount1Type: primaryAmount1Type ?? this.primaryAmount1Type,
      primaryAmount2Value: primaryAmount2Value ?? this.primaryAmount2Value,
      primaryAmount2Unit: primaryAmount2Unit ?? this.primaryAmount2Unit,
      primaryAmount2Type: primaryAmount2Type ?? this.primaryAmount2Type,
      secondaryAmount1Value: secondaryAmount1Value ?? this.secondaryAmount1Value,
      secondaryAmount1Unit: secondaryAmount1Unit ?? this.secondaryAmount1Unit,
      secondaryAmount1Type: secondaryAmount1Type ?? this.secondaryAmount1Type,
      secondaryAmount2Value: secondaryAmount2Value ?? this.secondaryAmount2Value,
      secondaryAmount2Unit: secondaryAmount2Unit ?? this.secondaryAmount2Unit,
      secondaryAmount2Type: secondaryAmount2Type ?? this.secondaryAmount2Type,
      terms: terms ?? this.terms,
    );
  }
}
