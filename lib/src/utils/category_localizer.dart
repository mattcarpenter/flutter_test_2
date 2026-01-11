import 'package:flutter/widgets.dart';
import '../localization/l10n_extension.dart';

/// Maps category strings from the API to localized labels.
///
/// Categories are stored in their native language (English for EN locale,
/// Japanese for JA locale). This utility provides optional l10n lookup
/// for known categories, with fallback to the raw string for unknown ones.
class CategoryLocalizer {
  /// Map of known category strings (in any language) to l10n getter functions.
  static final Map<String, String Function(BuildContext)> _categoryMap = {
    // English categories
    'Produce': (ctx) => ctx.l10n.categoryProduce,
    'Meat & Seafood': (ctx) => ctx.l10n.categoryMeatSeafood,
    'Dairy & Eggs': (ctx) => ctx.l10n.categoryDairyEggs,
    'Tofu & Soy Products': (ctx) => ctx.l10n.categoryTofuSoyProducts,
    'Frozen Foods': (ctx) => ctx.l10n.categoryFrozenFoods,
    'Grains, Cereals & Pasta': (ctx) => ctx.l10n.categoryGrainsCerealsPasta,
    'Legumes, Nuts & Plant Proteins': (ctx) => ctx.l10n.categoryLegumesNutsPlantProteins,
    'Dried Goods': (ctx) => ctx.l10n.categoryDriedGoods,
    'Baking & Sweeteners': (ctx) => ctx.l10n.categoryBakingSweeteners,
    'Oils, Fats & Vinegars': (ctx) => ctx.l10n.categoryOilsFatsVinegars,
    'Herbs, Spices & Seasonings': (ctx) => ctx.l10n.categoryHerbsSpicesSeasonings,
    'Sauces, Condiments & Spreads': (ctx) => ctx.l10n.categorySaucesCondimentsSpreads,
    'Canned & Jarred Goods': (ctx) => ctx.l10n.categoryCannedJarredGoods,
    'Beverages & Snacks': (ctx) => ctx.l10n.categoryBeveragesSnacks,
    'Other': (ctx) => ctx.l10n.categoryOther,

    // Japanese categories
    '野菜・果物': (ctx) => ctx.l10n.categoryProduce,
    '肉・魚介類': (ctx) => ctx.l10n.categoryMeatSeafood,
    '乳製品・卵': (ctx) => ctx.l10n.categoryDairyEggs,
    '豆腐・大豆食品': (ctx) => ctx.l10n.categoryTofuSoyProducts,
    '冷凍食品': (ctx) => ctx.l10n.categoryFrozenFoods,
    '穀物・シリアル・パスタ': (ctx) => ctx.l10n.categoryGrainsCerealsPasta,
    '豆類・ナッツ・植物性タンパク質': (ctx) => ctx.l10n.categoryLegumesNutsPlantProteins,
    '乾物': (ctx) => ctx.l10n.categoryDriedGoods,
    '製菓材料・甘味料': (ctx) => ctx.l10n.categoryBakingSweeteners,
    '油脂・酢': (ctx) => ctx.l10n.categoryOilsFatsVinegars,
    'ハーブ・スパイス・調味料': (ctx) => ctx.l10n.categoryHerbsSpicesSeasonings,
    'ソース・調味料・スプレッド': (ctx) => ctx.l10n.categorySaucesCondimentsSpreads,
    '缶詰・瓶詰': (ctx) => ctx.l10n.categoryCannedJarredGoods,
    '飲料・スナック': (ctx) => ctx.l10n.categoryBeveragesSnacks,
    'その他': (ctx) => ctx.l10n.categoryOther,
  };

  /// Returns the localized category label for display.
  ///
  /// Takes the raw category string from the API (which may be in English
  /// or Japanese depending on the locale used during canonicalization)
  /// and returns the localized version for the current app locale.
  ///
  /// If the category is not recognized, returns the original string as-is.
  static String localize(BuildContext context, String? category) {
    if (category == null || category.isEmpty) {
      return context.l10n.categoryOther;
    }

    final getter = _categoryMap[category];
    if (getter != null) {
      return getter(context);
    }

    // Unknown category - return the raw string as-is
    return category;
  }

  /// Returns all known categories with their localized names.
  ///
  /// Returns a list of (rawCategory, localizedLabel) pairs.
  /// This uses the English category keys as the canonical identifiers.
  static List<(String, String)> allCategories(BuildContext context) {
    return [
      ('Produce', context.l10n.categoryProduce),
      ('Meat & Seafood', context.l10n.categoryMeatSeafood),
      ('Dairy & Eggs', context.l10n.categoryDairyEggs),
      ('Tofu & Soy Products', context.l10n.categoryTofuSoyProducts),
      ('Frozen Foods', context.l10n.categoryFrozenFoods),
      ('Grains, Cereals & Pasta', context.l10n.categoryGrainsCerealsPasta),
      ('Legumes, Nuts & Plant Proteins', context.l10n.categoryLegumesNutsPlantProteins),
      ('Dried Goods', context.l10n.categoryDriedGoods),
      ('Baking & Sweeteners', context.l10n.categoryBakingSweeteners),
      ('Oils, Fats & Vinegars', context.l10n.categoryOilsFatsVinegars),
      ('Herbs, Spices & Seasonings', context.l10n.categoryHerbsSpicesSeasonings),
      ('Sauces, Condiments & Spreads', context.l10n.categorySaucesCondimentsSpreads),
      ('Canned & Jarred Goods', context.l10n.categoryCannedJarredGoods),
      ('Beverages & Snacks', context.l10n.categoryBeveragesSnacks),
      ('Other', context.l10n.categoryOther),
    ];
  }

  /// Returns the list of English category keys.
  /// Kept for backward compatibility with existing code.
  static const List<String> categoryKeys = [
    'Produce',
    'Meat & Seafood',
    'Dairy & Eggs',
    'Tofu & Soy Products',
    'Frozen Foods',
    'Grains, Cereals & Pasta',
    'Legumes, Nuts & Plant Proteins',
    'Dried Goods',
    'Baking & Sweeteners',
    'Oils, Fats & Vinegars',
    'Herbs, Spices & Seasonings',
    'Sauces, Condiments & Spreads',
    'Canned & Jarred Goods',
    'Beverages & Snacks',
    'Other',
  ];
}
