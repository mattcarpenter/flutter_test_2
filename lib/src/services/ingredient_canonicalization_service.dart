import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../app_config.dart';
import '../../database/database.dart';
import '../../database/models/ingredient_terms.dart';

/// Class representing a converter returned from the API
class ConverterData {
  final String term;
  final String fromUnit;
  final String toBaseUnit;
  final double conversionFactor;
  final bool isApproximate;
  final String? notes;

  ConverterData({
    required this.term,
    required this.fromUnit,
    required this.toBaseUnit,
    required this.conversionFactor,
    this.isApproximate = false,
    this.notes,
  });

  factory ConverterData.fromJson(Map<String, dynamic> json, String term) {
    return ConverterData(
      term: term,
      fromUnit: json['fromUnit'] as String,
      toBaseUnit: json['toUnit'] as String,
      conversionFactor: (json['factor'] as num).toDouble(),
      isApproximate: json['isApproximate'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  /// Convert to a database ConverterEntry
  ConverterEntry toConverterEntry({
    required String userId,
    String? householdId,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ConverterEntry(
      id: const Uuid().v4(),
      term: term,
      fromUnit: fromUnit,
      toBaseUnit: toBaseUnit,
      conversionFactor: conversionFactor,
      isApproximate: isApproximate,
      notes: notes,
      userId: userId,
      householdId: householdId,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
    );
  }
}

/// Class to hold canonicalization result
class CanonicalizeResult {
  final Map<String, List<IngredientTerm>> terms;
  final Map<String, ConverterData> converters;

  CanonicalizeResult({
    required this.terms,
    required this.converters,
  });
}

class IngredientCanonicalizer {
  final String apiBaseUrl;

  IngredientCanonicalizer({required this.apiBaseUrl});

  /// Analyzes a list of ingredients and returns canonicalized terms and converters
  Future<CanonicalizeResult> canonicalizeIngredients(
      List<Map<String, dynamic>> ingredients) async {
    try {
      final url = Uri.parse('$apiBaseUrl/v1/ingredients/analyze');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'ingredients': ingredients,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('API request failed with status: ${response.statusCode}, body: ${response.body}');
      }

      final Map<String, dynamic> responseData = json.decode(response.body);
      final Map<String, List<IngredientTerm>> terms = {};
      final Map<String, ConverterData> converters = {};

      if (responseData.containsKey('ingredients') && responseData['ingredients'] is List) {
        final List<dynamic> analyzedIngredients = responseData['ingredients'];

        for (int i = 0; i < analyzedIngredients.length; i++) {
          final item = analyzedIngredients[i];
          final original = item['original']['name'];

          // Process terms
          if (item.containsKey('terms') && item['terms'] is List) {
            final List<dynamic> termList = item['terms'];
            // Create a map to deduplicate terms while preserving the first occurrence's sort order
            final Map<String, IngredientTerm> uniqueTerms = {};

            termList.asMap().entries.forEach((entry) {
              final index = entry.key;
              final value = entry.value.toString().trim();

              // Skip empty terms
              if (value.isEmpty) return;

              // Only add if we haven't seen this term yet
              if (!uniqueTerms.containsKey(value)) {
                uniqueTerms[value] = IngredientTerm(
                  value: value,
                  source: 'ai',
                  sort: index,
                );
              }
            });

            // Convert the map back to a list, sorted by the original sort order
            final List<IngredientTerm> termsList = uniqueTerms.values.toList()
              ..sort((a, b) => a.sort.compareTo(b.sort));

            // Use the original name as key
            if (termsList.isNotEmpty) {
              terms[original] = termsList;

              // Process converter if available
              if (item.containsKey('converter') && item['converter'] != null) {
                final converter = item['converter'];
                // Use the first (most specific) term for the converter
                final mainTerm = termsList.first.value;
                converters[original] = ConverterData.fromJson(converter, mainTerm);
              }
            }
          }
        }
      }

      return CanonicalizeResult(terms: terms, converters: converters);
    } catch (e) {
      debugPrint('Error in canonicalizeIngredients: $e');
      rethrow;
    }
  }

  /// Canonicalize a single ingredient
  Future<CanonicalizeResult?> canonicalizeSingleIngredient(
      String name, {double? quantity, String? unit}) async {
    try {
      final Map<String, dynamic> ingredient = {
        'name': name,
        'quantity': quantity,
        'unit': unit,
      };

      return await canonicalizeIngredients([ingredient]);
    } catch (e) {
      debugPrint('Error in canonicalizeSingleIngredient: $e');
      return null;
    }
  }
}

final ingredientCanonicalizerProvider = Provider<IngredientCanonicalizer>((ref) {
  final apiUrl = AppConfig.ingredientApiUrl;
  return IngredientCanonicalizer(apiBaseUrl: apiUrl);
});
