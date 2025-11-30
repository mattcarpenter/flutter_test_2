import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import '../../../../services/logging/app_logger.dart';
import '../../models/export_recipe.dart';
import 'recipe_parser.dart';

/// Parser for Stockpot export format (.zip with JSON files)
class StockpotParser implements RecipeParser<ExportRecipe> {
  @override
  List<String> get supportedExtensions => ['.zip'];

  @override
  Future<List<ExportRecipe>> parseArchive(File archive) async {
    final recipes = <ExportRecipe>[];

    try {
      final bytes = await archive.readAsBytes();
      final zipArchive = ZipDecoder().decodeBytes(bytes);

      // Find all .json files at root level
      for (final file in zipArchive.files) {
        if (!file.isFile) continue;
        if (!file.name.toLowerCase().endsWith('.json')) continue;

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

      AppLogger.info('Parsed ${recipes.length} recipes from Stockpot archive');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to parse Stockpot archive', e, stackTrace);
    }

    return recipes;
  }

  @override
  ExportRecipe parseRecipe(List<int> bytes, String filename) {
    try {
      final jsonString = utf8.decode(bytes);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ExportRecipe.fromJson(json);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to parse recipe: $filename', e, stackTrace);
      rethrow;
    }
  }
}
