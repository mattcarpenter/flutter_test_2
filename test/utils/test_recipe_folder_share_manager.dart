import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TestRecipeFolderShareManager {
  /// Creates a new recipe folder share.
  ///
  /// [folderId] - The ID of the folder being shared.
  /// [sharerId] - The ID of the user sharing the folder.
  /// [targetUserId] - (Optional) The target user ID if sharing directly with a single user.
  /// [canEdit] - Permission flag (default 0 for read-only, 1 for can_edit).
  /// [createdAt] - (Optional) Timestamp in Unix epoch millis. If null, the database trigger or default may set it.
  ///
  /// Returns the inserted share record as a map.
  static Future<Map<String, dynamic>> createShare({
    required String folderId,
    required String sharerId,
    String? targetUserId,
    int canEdit = 0,
    int? createdAt,
  }) async {
    final String supabaseUrl = dotenv.env['SUPABASE_URL']!;
    final String serviceRoleKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY']!;

    final response = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/recipe_folder_shares'),
      headers: {
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      },
      body: jsonEncode({
        'folder_id': folderId,
        'sharer_id': sharerId,
        if (targetUserId != null) 'target_user_id': targetUserId,
        'can_edit': canEdit,
        if (createdAt != null) 'created_at': createdAt,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data[0]; // Return the first (and only) inserted share record.
    } else {
      throw Exception('Failed to create recipe folder share: ${response.body}');
    }
  }
}
