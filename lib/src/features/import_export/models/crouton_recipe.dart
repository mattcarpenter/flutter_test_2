import 'package:json_annotation/json_annotation.dart';

part 'crouton_recipe.g.dart';

/// Represents a recipe exported from Crouton app (.crumb JSON format)
@JsonSerializable()
class CroutonRecipe {
  final String uuid;
  final String name;
  final int? serves;
  final int? duration; // in seconds
  final int? cookingDuration; // in seconds
  final double? defaultScale;
  final String? webLink;
  final String? notes;

  // Note: Crouton has a typo in their export format
  @JsonKey(name: 'neutritionalInfo')
  final String? nutritionalInfo;

  final List<CroutonIngredient>? ingredients;
  final List<CroutonStep>? steps;
  final List<String>? images; // base64-encoded image strings
  final List<String>? tags;
  final List<String>? folderIDs;
  final bool? isPublicRecipe;

  CroutonRecipe({
    required this.uuid,
    required this.name,
    this.serves,
    this.duration,
    this.cookingDuration,
    this.defaultScale,
    this.webLink,
    this.notes,
    this.nutritionalInfo,
    this.ingredients,
    this.steps,
    this.images,
    this.tags,
    this.folderIDs,
    this.isPublicRecipe,
  });

  factory CroutonRecipe.fromJson(Map<String, dynamic> json) =>
      _$CroutonRecipeFromJson(json);

  Map<String, dynamic> toJson() => _$CroutonRecipeToJson(this);
}

/// Represents an ingredient entry in a Crouton recipe
@JsonSerializable()
class CroutonIngredient {
  final String? uuid;
  final int? order;
  final CroutonIngredientInfo? ingredient;
  final CroutonQuantity? quantity;

  CroutonIngredient({
    this.uuid,
    this.order,
    this.ingredient,
    this.quantity,
  });

  factory CroutonIngredient.fromJson(Map<String, dynamic> json) =>
      _$CroutonIngredientFromJson(json);

  Map<String, dynamic> toJson() => _$CroutonIngredientToJson(this);
}

/// Represents the ingredient information (name and identifier)
@JsonSerializable()
class CroutonIngredientInfo {
  final String? uuid;
  final String name;

  CroutonIngredientInfo({
    this.uuid,
    required this.name,
  });

  factory CroutonIngredientInfo.fromJson(Map<String, dynamic> json) =>
      _$CroutonIngredientInfoFromJson(json);

  Map<String, dynamic> toJson() => _$CroutonIngredientInfoToJson(this);
}

/// Represents a quantity measurement for an ingredient
@JsonSerializable()
class CroutonQuantity {
  final double? amount;
  final String? quantityType; // ITEM, RECIPE, CUP, TABLESPOON, TEASPOON, GRAM, KILOGRAM, OUNCE, POUND, MILLILITER, LITER, PINCH

  CroutonQuantity({
    this.amount,
    this.quantityType,
  });

  factory CroutonQuantity.fromJson(Map<String, dynamic> json) =>
      _$CroutonQuantityFromJson(json);

  Map<String, dynamic> toJson() => _$CroutonQuantityToJson(this);
}

/// Represents a recipe step or section header
@JsonSerializable()
class CroutonStep {
  final String? uuid;
  final int? order;
  final String? step; // The step text content
  final bool? isSection; // true if this is a section header, false if it's a regular step

  CroutonStep({
    this.uuid,
    this.order,
    this.step,
    this.isSection,
  });

  factory CroutonStep.fromJson(Map<String, dynamic> json) =>
      _$CroutonStepFromJson(json);

  Map<String, dynamic> toJson() => _$CroutonStepToJson(this);
}
