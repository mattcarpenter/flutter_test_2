import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app_config.dart';
import '../services/api_signer.dart';

/// HTTP client for the Recipe API with automatic HMAC request signing.
///
/// This client handles the transport layer concerns:
/// - JSON encoding of request bodies
/// - HMAC-SHA256 request signing via [ApiSigner]
/// - HTTP request execution
///
/// Services should use this client instead of making direct HTTP calls
/// to ensure consistent signing across all API requests.
class RecipeApiClient {
  final String baseUrl;

  RecipeApiClient({required this.baseUrl});

  /// Sends a signed POST request to the API.
  ///
  /// [path] - Full path starting with '/' (e.g., '/v1/ingredients/analyze')
  /// [body] - Request body as Map (will be JSON encoded)
  /// [requiresAuth] - If true, includes Authorization header with Supabase JWT
  ///
  /// Returns the raw [http.Response] for the caller to handle parsing and errors.
  ///
  /// The request is automatically signed with HMAC-SHA256 using the headers:
  /// - X-Api-Key: Public API key identifier
  /// - X-Timestamp: Unix timestamp in seconds
  /// - X-Signature: HMAC signature of canonical request string
  Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    // Create body string ONCE - used for both signing and sending
    // This ensures the exact bytes signed match the bytes sent
    final bodyString = json.encode(body);

    // Sign the request
    final signatureHeaders = ApiSigner.sign('POST', path, bodyString);

    // Build headers
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...signatureHeaders,
    };

    // Add auth header if required
    if (requiresAuth) {
      final token = _getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return await http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: bodyString,
    );
  }

  /// Gets the current Supabase session token.
  String? _getAuthToken() {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.accessToken;
  }
}

/// Provider for the Recipe API client.
///
/// Injects the base URL from [AppConfig.ingredientApiUrl].
final recipeApiClientProvider = Provider<RecipeApiClient>((ref) {
  return RecipeApiClient(baseUrl: AppConfig.ingredientApiUrl);
});
