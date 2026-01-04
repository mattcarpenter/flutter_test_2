import 'package:flutter/widgets.dart';
import '../localization/l10n_extension.dart';

/// Maps raw English category strings from the API to localized labels.
///
/// Categories are stored in English in the database (returned by the API),
/// but displayed in the user's locale. This utility handles the translation.
class CategoryLocalizer {
  /// Returns the localized category label for display.
  ///
  /// Takes the raw English category string from the API and returns
  /// the localized version for the current locale.
  ///
  /// If the category is not recognized, returns the original string.
  static String localize(BuildContext context, String? category) {
    if (category == null || category.isEmpty) {
      return context.l10n.categoryOther;
    }

    // Map the raw API category to the localization key
    switch (category) {
      case 'Produce':
        return context.l10n.categoryProduce;
      case 'Meat & Seafood':
        return context.l10n.categoryMeatSeafood;
      case 'Dairy & Eggs':
        return context.l10n.categoryDairyEggs;
      case 'Frozen Foods':
        return context.l10n.categoryFrozenFoods;
      case 'Grains, Cereals & Pasta':
        return context.l10n.categoryGrainsCerealsPasta;
      case 'Legumes, Nuts & Plant Proteins':
        return context.l10n.categoryLegumesNutsPlantProteins;
      case 'Baking & Sweeteners':
        return context.l10n.categoryBakingSweeteners;
      case 'Oils, Fats & Vinegars':
        return context.l10n.categoryOilsFatsVinegars;
      case 'Herbs, Spices & Seasonings':
        return context.l10n.categoryHerbsSpicesSeasonings;
      case 'Sauces, Condiments & Spreads':
        return context.l10n.categorySaucesCondimentsSpreads;
      case 'Canned & Jarred Goods':
        return context.l10n.categoryCannedJarredGoods;
      case 'Beverages & Snacks':
        return context.l10n.categoryBeveragesSnacks;
      case 'Other':
        return context.l10n.categoryOther;
      default:
        // For unknown categories, return the original string
        return category;
    }
  }

  /// Returns all available categories in display order with their localized names.
  ///
  /// Returns a list of (apiKey, localizedLabel) pairs.
  static List<(String, String)> allCategories(BuildContext context) {
    return [
      ('Produce', context.l10n.categoryProduce),
      ('Meat & Seafood', context.l10n.categoryMeatSeafood),
      ('Dairy & Eggs', context.l10n.categoryDairyEggs),
      ('Frozen Foods', context.l10n.categoryFrozenFoods),
      ('Grains, Cereals & Pasta', context.l10n.categoryGrainsCerealsPasta),
      ('Legumes, Nuts & Plant Proteins', context.l10n.categoryLegumesNutsPlantProteins),
      ('Baking & Sweeteners', context.l10n.categoryBakingSweeteners),
      ('Oils, Fats & Vinegars', context.l10n.categoryOilsFatsVinegars),
      ('Herbs, Spices & Seasonings', context.l10n.categoryHerbsSpicesSeasonings),
      ('Sauces, Condiments & Spreads', context.l10n.categorySaucesCondimentsSpreads),
      ('Canned & Jarred Goods', context.l10n.categoryCannedJarredGoods),
      ('Beverages & Snacks', context.l10n.categoryBeveragesSnacks),
      ('Other', context.l10n.categoryOther),
    ];
  }

  /// Returns the list of raw API category keys in display order.
  static const List<String> categoryKeys = [
    'Produce',
    'Meat & Seafood',
    'Dairy & Eggs',
    'Frozen Foods',
    'Grains, Cereals & Pasta',
    'Legumes, Nuts & Plant Proteins',
    'Baking & Sweeteners',
    'Oils, Fats & Vinegars',
    'Herbs, Spices & Seasonings',
    'Sauces, Condiments & Spreads',
    'Canned & Jarred Goods',
    'Beverages & Snacks',
    'Other',
  ];
}
