import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:recipe_app/database/models/pantry_item_terms.dart';

import 'models/cooks.dart';
import 'models/ingredient_terms.dart';
import 'models/recipe_images.dart';
import 'models/steps.dart';
import 'models/ingredients.dart';
import 'models/meal_plan_items.dart';

class StringListTypeConverter extends TypeConverter<List<String>, String> {
  const StringListTypeConverter();

  @override
  List<String> fromSql(String fromDb) {
    try {
      var decoded = jsonDecode(fromDb);

      // Handle double-encoded JSON: if decoded is a string, try to decode it again
      if (decoded is String) {
        try {
          decoded = jsonDecode(decoded);
        } catch (e) {
          final result = [decoded as String];
          return result;
        }
      }

      if (decoded is List) {
        final result = decoded.cast<String>();
        return result;
      } else {
        return [];
      }
    } catch (e) {
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

class IngredientTermListConverter extends TypeConverter<List<IngredientTerm>, String> {
  const IngredientTermListConverter();

  @override
  List<IngredientTerm> fromSql(String fromDb) {
    try {
      final List<dynamic> decoded = json.decode(fromDb);
      return decoded.map((item) => IngredientTerm.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  String toSql(List<IngredientTerm> value) {
    return json.encode(value.map((term) => term.toJson()).toList());
  }
}

class PantryItemTermListConverter extends TypeConverter<List<PantryItemTerm>, String> {
  const PantryItemTermListConverter();

  @override
  List<PantryItemTerm> fromSql(String fromDb) {
    try {
      final List<dynamic> decoded = json.decode(fromDb);
      return decoded.map((item) => PantryItemTerm.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  String toSql(List<PantryItemTerm> value) {
    return json.encode(value.map((term) => term.toJson()).toList());
  }
}

class MealPlanItemListConverter extends TypeConverter<List<MealPlanItem>, String> {
  const MealPlanItemListConverter();

  @override
  List<MealPlanItem> fromSql(String fromDb) {
    try {
      final List<dynamic> decoded = json.decode(fromDb);
      return decoded.map((item) => MealPlanItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  String toSql(List<MealPlanItem> value) {
    return json.encode(value.map((item) => item.toJson()).toList());
  }
}
