import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_config.dart';
import '../../database/models/ingredient_terms.dart';

class IngredientCanonicalizer {
  final String apiBaseUrl;
  
  IngredientCanonicalizer({required this.apiBaseUrl});
  
  /// Analyzes a list of ingredients and returns canonicalized terms
  Future<Map<String, List<IngredientTerm>>> canonicalizeIngredients(
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
      final Map<String, List<IngredientTerm>> result = {};
      
      if (responseData.containsKey('ingredients') && responseData['ingredients'] is List) {
        final List<dynamic> analyzedIngredients = responseData['ingredients'];
        
        for (int i = 0; i < analyzedIngredients.length; i++) {
          final item = analyzedIngredients[i];
          final original = item['original']['name'];
          
          if (item.containsKey('terms') && item['terms'] is List) {
            final List<dynamic> termList = item['terms'];
            final List<IngredientTerm> terms = termList.asMap().entries.map((entry) {
              final index = entry.key;
              final value = entry.value.toString();
              
              return IngredientTerm(
                value: value,
                source: 'ai',
                sort: index,
              );
            }).toList();
            
            // Use the original name as key
            result[original] = terms;
          }
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Error in canonicalizeIngredients: $e');
      rethrow;
    }
  }
  
  /// Canonicalize a single ingredient
  Future<List<IngredientTerm>?> canonicalizeSingleIngredient(
      String name, {double? quantity, String? unit}) async {
    try {
      final Map<String, dynamic> ingredient = {
        'name': name,
        'quantity': quantity,
        'unit': unit,
      };
      
      final result = await canonicalizeIngredients([ingredient]);
      return result[name];
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