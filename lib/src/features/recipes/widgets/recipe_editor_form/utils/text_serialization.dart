import 'package:uuid/uuid.dart';

import '../../../../../../database/models/ingredients.dart';
import '../../../../../../database/models/steps.dart';
import '../../../../../repositories/recipe_repository.dart';

/// Regex pattern for [recipe:Name] - matches existing RecipeTextRenderer pattern
final _recipePattern = RegExp(r'\[recipe:([^\]]+)\]');

/// Converts a list of Ingredients to text format.
///
/// Async because we need to look up recipe titles for sub-recipe links.
/// Pass the repository to resolve recipeId → recipe title.
///
/// Format:
/// - One ingredient per line
/// - Sections prefixed with `#`
/// - Sub-recipe links appended as `[recipe:Title]`
Future<String> ingredientsToText(
  List<Ingredient> ingredients,
  RecipeRepository repository,
) async {
  final lines = <String>[];

  for (final ing in ingredients) {
    String text = ing.name.replaceAll('\n', ' ').trim();

    if (ing.type == 'section') {
      if (text.isNotEmpty) {
        lines.add('# $text');
      }
      continue;
    }

    // If ingredient has a sub-recipe link, append [recipe:Title]
    if (ing.recipeId != null && ing.recipeId!.isNotEmpty) {
      final linkedRecipe = await repository.getRecipeById(ing.recipeId!);
      if (linkedRecipe != null) {
        text = '$text [recipe:${linkedRecipe.title}]';
      }
    }

    if (text.isNotEmpty) {
      lines.add(text);
    }
  }

  return lines.join('\n');
}

/// Parses text format back to Ingredients.
///
/// Async because we need to resolve recipe names to IDs for sub-recipe links.
/// Pass the repository to resolve recipe title → recipeId.
///
/// Format:
/// - One ingredient per line
/// - Lines starting with `#` become sections
/// - `[recipe:Name]` is parsed and resolved to a recipeId
/// - Empty lines are ignored
Future<List<Ingredient>> textToIngredients(
  String text,
  RecipeRepository repository,
) async {
  final lines = text.split('\n');
  final ingredients = <Ingredient>[];
  final uuid = const Uuid();

  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty) continue;

    // Check for section header
    if (line.startsWith('#')) {
      final name = line.substring(1).trim();
      ingredients.add(Ingredient(
        id: uuid.v4(),
        type: 'section',
        name: name.isEmpty ? 'New Section' : name,
      ));
      continue;
    }

    // Check for [recipe:Name] pattern
    String? recipeId;
    String ingredientName = line;

    final match = _recipePattern.firstMatch(line);
    if (match != null) {
      final recipeName = match.group(1)!;
      // Try to resolve recipe by title
      final recipe = await repository.getRecipeByTitle(recipeName);
      if (recipe != null) {
        recipeId = recipe.id;
        // Strip the [recipe:Name] marker entirely - the ingredient name
        // already contains the human-readable text from serialization
        ingredientName = line.replaceFirst(_recipePattern, '').trim();
      }
      // If recipe not found, leave the text as-is (including brackets)
      // so user knows the link didn't resolve
    }

    ingredients.add(Ingredient(
      id: uuid.v4(),
      type: 'ingredient',
      name: ingredientName,
      recipeId: recipeId,
      primaryAmount1Value: '',
      primaryAmount1Unit: 'g',
      primaryAmount1Type: 'weight',
    ));
  }

  return ingredients;
}

/// Converts a list of Steps to text format.
///
/// Synchronous - steps don't have sub-recipe links at the model level.
/// (They use inline [recipe:Name] in the text itself, which we preserve as-is)
///
/// Format:
/// - Steps separated by blank lines (double newlines)
/// - Single newlines within steps are preserved
/// - Sections prefixed with `#`
String stepsToText(List<Step> steps) {
  return steps.map((step) {
    // Only scrub double newlines (our delimiter), preserve single newlines
    final text = step.text.replaceAll('\n\n', ' ').trim();
    if (step.type == 'section') {
      return '# $text';
    }
    return text;
  }).where((block) => block.isNotEmpty).join('\n\n');
}

/// Parses text format back to Steps.
///
/// Synchronous - no recipe resolution needed for steps.
///
/// Format:
/// - Steps separated by blank lines (double newlines)
/// - Single newlines within a block are preserved in the step text
/// - Blocks starting with `#` become sections
/// - Empty blocks are ignored
List<Step> textToSteps(String text) {
  // Split on blank lines - each block becomes a step
  final blocks = text.split('\n\n');
  final uuid = const Uuid();

  return blocks
      .map((block) => block.trim())
      .where((block) => block.isNotEmpty)
      .map((block) {
        if (block.startsWith('#')) {
          // Section: text after # (may contain internal newlines)
          final stepText = block.substring(1).trim();
          return Step(
            id: uuid.v4(),
            type: 'section',
            text: stepText.isEmpty ? 'New Section' : stepText,
          );
        }
        return Step(
          id: uuid.v4(),
          type: 'step',
          text: block, // Preserve internal newlines
        );
      })
      .toList();
}
