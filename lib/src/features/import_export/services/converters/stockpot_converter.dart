import '../../models/export_recipe.dart';
import 'recipe_converter.dart';

/// Converts Stockpot export format to ImportedRecipe
class StockpotConverter extends RecipeConverter<ExportRecipe> {
  @override
  ImportedRecipe convert(ExportRecipe source) {
    return ImportedRecipe(
      title: source.title,
      description: source.description,
      rating: source.rating,
      language: source.language,
      servings: source.servings,
      prepTime: source.prepTime,
      cookTime: source.cookTime,
      totalTime: source.totalTime,
      source: source.source,
      nutrition: source.nutrition,
      generalNotes: source.generalNotes,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
      pinned: source.pinned ?? false,
      tagNames: source.tagNames ?? [],
      folderNames: source.folderNames ?? [],
      ingredients: _convertIngredients(source.ingredients ?? []),
      steps: _convertSteps(source.steps ?? []),
      images: _convertImages(source.images ?? []),
    );
  }

  List<ImportedIngredient> _convertIngredients(List<ExportIngredient> ingredients) {
    return ingredients.map((ingredient) {
      return ImportedIngredient(
        type: ingredient.type,
        name: ingredient.name,
        note: ingredient.note,
        terms: ingredient.terms?.map((term) {
          return ImportedTerm(
            value: term.value,
            source: term.source,
            sort: term.sort,
          );
        }).toList(),
        isCanonicalised: ingredient.isCanonicalised ?? false,
        category: ingredient.category,
      );
    }).toList();
  }

  List<ImportedStep> _convertSteps(List<ExportStep> steps) {
    return steps.map((step) {
      return ImportedStep(
        type: step.type,
        text: step.text,
        note: step.note,
        timerDurationSeconds: step.timerDurationSeconds,
      );
    }).toList();
  }

  List<ImportedImage> _convertImages(List<ExportImage> images) {
    return images.map((image) {
      return ImportedImage(
        isCover: image.isCover ?? false,
        data: image.data,
        publicUrl: image.publicUrl,
      );
    }).toList();
  }
}
