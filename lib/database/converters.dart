import 'dart:convert';

import 'package:drift/drift.dart';

import 'models/cooks.dart';
import 'models/recipe_images.dart';
import 'models/steps.dart';
import 'models/ingredients.dart';

class StringListTypeConverter extends TypeConverter<List<String>, String> {
  @override
  List<String> fromSql(String fromDb) {
    try {
      return List<String>.from(jsonDecode(fromDb));
    } catch (_) {
      return [];
    }
  }

  @override
  String toSql(List<String> value) {
    return jsonEncode(value);
  }
}

// JSON Converter for Steps
class StepListConverter extends TypeConverter<List<Step>, String> {
  const StepListConverter();

  @override
  List<Step> fromSql(String fromDb) {
    final List<dynamic> decoded = json.decode(fromDb);
    return decoded.map((item) => Step.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  String toSql(List<Step> value) {
    return json.encode(value.map((step) => step.toJson()).toList());
  }
}

// JSON Converter for Ingredients
class IngredientListConverter extends TypeConverter<List<Ingredient>, String> {
  const IngredientListConverter();

  @override
  List<Ingredient> fromSql(String fromDb) {
    final List<dynamic> decoded = json.decode(fromDb);
    return decoded.map((item) => Ingredient.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  String toSql(List<Ingredient> value) {
    return json.encode(value.map((ingredient) => ingredient.toJson()).toList());
  }
}

// JSON Converter for Recipe Images
class RecipeImageListConverter extends TypeConverter<List<RecipeImage>, String> {
  const RecipeImageListConverter();

  @override
  List<RecipeImage> fromSql(String fromDb) {
    final List<dynamic> decoded = json.decode(fromDb);
    return decoded.map((item) => RecipeImage.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  String toSql(List<RecipeImage> value) {
    return json.encode(value.map((image) => image.toJson()).toList());
  }
}

class CookStatusConverter extends TypeConverter<CookStatus, String> {
  const CookStatusConverter();

  @override
  CookStatus fromSql(String fromDb) {
    switch (fromDb) {
      case 'finished':
        return CookStatus.finished;
      case 'discarded':
        return CookStatus.discarded;
      default:
        return CookStatus.inProgress;
    }
  }

  @override
  String toSql(CookStatus value) {
    switch (value) {
      case CookStatus.finished:
        return 'finished';
      case CookStatus.discarded:
        return 'discarded';
      case CookStatus.inProgress:
      default:
        return 'in_progress';
    }
  }
}

