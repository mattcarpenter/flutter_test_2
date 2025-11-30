import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import '../../../../services/logging/app_logger.dart';
import '../../models/paprika_recipe.dart';
import 'recipe_parser.dart';

/// Parser for Paprika export format (.paprikarecipes)
class PaprikaParser implements RecipeParser<PaprikaRecipe> {
  @override
  List<String> get supportedExtensions => ['.paprikarecipes'];

  @override
  Future<List<PaprikaRecipe>> parseArchive(File archive) async {
    final recipes = <PaprikaRecipe>[];

    try {
      final bytes = await archive.readAsBytes();
      final zipArchive = ZipDecoder().decodeBytes(bytes);

      // Find all .paprikarecipe files
      for (final file in zipArchive.files) {
        if (!file.isFile) continue;
        if (!file.name.toLowerCase().endsWith('.paprikarecipe')) continue;

        try {
          final recipe = parseRecipe(file.content as List<int>, file.name);
          recipes.add(recipe);
        } catch (e, stackTrace) {
          AppLogger.error(
            'Failed to parse recipe file: ${file.name}',
            e,
            stackTrace,
          );
          // Continue processing other recipes
        }
      }

      AppLogger.info('Parsed ${recipes.length} recipes from Paprika archive');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to parse Paprika archive', e, stackTrace);
    }

    return recipes;
  }

  @override
  PaprikaRecipe parseRecipe(List<int> bytes, String filename) {
    try {
      // Paprika recipe files are gzip compressed JSON
      final decompressed = GZipDecoder().decodeBytes(bytes);
      final jsonString = utf8.decode(decompressed);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return PaprikaRecipe.fromJson(json);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to parse recipe: $filename', e, stackTrace);
      rethrow;
    }
  }
}
