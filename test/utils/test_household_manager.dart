import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TestHouseholdManager {

  /// Creates a new household.
  /// Returns the inserted household record as a map.
  static Future<Map<String, dynamic>> createHousehold(String name, String ownerUserId) async {
    final String supabaseUrl = dotenv.env['SUPABASE_URL']!;
    final String serviceRoleKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY']!;

    final response = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/households'),
      headers: {
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
        'Content-Type': 'application/json',
        // Request returning the inserted row.
        'Prefer': 'return=representation',
      },
      body: jsonEncode({
        'name': name,
        'user_id': ownerUserId,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data[0]; // Return the first (and only) inserted household record.
    } else {
      throw Exception('Failed to create household: ${response.body}');
    }
  }

  /// Adds a user to an existing household.
  /// Returns the inserted household member record as a map.
  static Future<Map<String, dynamic>> addHouseholdMember(String householdId, String userId) async {
    final String supabaseUrl = dotenv.env['SUPABASE_URL']!;
    final String serviceRoleKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY']!;

    final response = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/household_members'),
      headers: {
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      },
      body: jsonEncode({
        'household_id': householdId,
        'user_id': userId,
        'is_active': 1,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data[0];
    } else {
      throw Exception('Failed to add household member: ${response.body}');
    }
  }
}
