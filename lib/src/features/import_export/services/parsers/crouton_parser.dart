import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import '../../../../services/logging/app_logger.dart';
import '../../models/crouton_recipe.dart';
import 'recipe_parser.dart';

/// Parser for Crouton export format (.zip with .crumb files)
class CroutonParser implements RecipeParser<CroutonRecipe> {
  @override
  List<String> get supportedExtensions => ['.zip'];

  @override
  Future<List<CroutonRecipe>> parseArchive(File archive) async {
    final recipes = <CroutonRecipe>[];

    try {
      final bytes = await archive.readAsBytes();
      final zipArchive = ZipDecoder().decodeBytes(bytes);

      // Find all .crumb files
      for (final file in zipArchive.files) {
        if (!file.isFile) continue;
        if (!file.name.toLowerCase().endsWith('.crumb')) continue;

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

      AppLogger.info('Parsed ${recipes.length} recipes from Crouton archive');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to parse Crouton archive', e, stackTrace);
    }

    return recipes;
  }

  @override
  CroutonRecipe parseRecipe(List<int> bytes, String filename) {
    try {
      // Crouton .crumb files are plain JSON
      final jsonString = utf8.decode(bytes);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return CroutonRecipe.fromJson(json);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to parse recipe: $filename', e, stackTrace);
      rethrow;
    }
  }
}
