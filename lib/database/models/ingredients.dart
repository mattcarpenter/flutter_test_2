import 'package:json_annotation/json_annotation.dart';
import 'ingredient_terms.dart';

part 'ingredients.g.dart';

@JsonSerializable()
class Ingredient {
  final String id;
  final String type; // "ingredient" or "section"
  final String name;
  final String? displayName; // Clean name for shopping lists (no prep instructions)
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
  final bool isCanonicalised; // Whether this ingredient has been processed by canonicalization API
  final String? category; // Optional category from canonicalization API
  final String? recipeId; // Optional reference to another recipe for sub-recipes

  Ingredient({
    required this.id,
    required this.type,
    required this.name,
    this.displayName,
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
    this.isCanonicalised = false,
    this.category,
    this.recipeId,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    // Handle potential null values from imported/synced data
    return Ingredient(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'ingredient',
      name: json['name'] as String? ?? '',
      displayName: json['displayName'] as String?,
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
      category: json['category'] as String?,
      recipeId: json['recipeId'] as String?,
    );
  }
  Map<String, dynamic> toJson() => _$IngredientToJson(this);

  Ingredient copyWith({
    String? id,
    String? type,
    String? name,
    String? displayName,
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
    bool? isCanonicalised,
    String? category,
    String? recipeId,
  }) {
    return Ingredient(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
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
      isCanonicalised: isCanonicalised ?? this.isCanonicalised,
      category: category ?? this.category,
      recipeId: recipeId ?? this.recipeId,
    );
  }
}
