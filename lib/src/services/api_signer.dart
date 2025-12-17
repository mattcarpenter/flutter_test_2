import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utility class for signing API requests with HMAC-SHA256.
///
/// This provides a lightweight security layer to protect API endpoints from
/// casual abuse. Requests are signed with a timestamp and body hash to ensure
/// integrity and prevent replay attacks outside a short time window.
///
/// Note: This is security-by-obscurity. The signing key is embedded in the app
/// binary and can be extracted by a determined attacker. It's designed to add
/// friction, not provide cryptographic security guarantees.
class ApiSigner {
  // Signing key - used for HMAC computation
  // This is embedded in the app binary (acceptable tradeoff for MVP)
  static const String _signingKey = 'rcp_sk_7f3a9b2c4d5e6f8g1h2i3j4k5l6m7n8o';

  // Public API key - identifies the app (not secret)
  static const String apiKey = 'rcp_live_flutter_v1';

  /// Signs an API request and returns headers to include.
  ///
  /// [method] - HTTP method (e.g., 'POST', 'GET')
  /// [path] - Request path starting with '/' (e.g., '/v1/ingredients/analyze')
  /// [bodyString] - The exact request body string (must match what's sent)
  ///
  /// Returns a map of headers to include in the request:
  /// - X-Api-Key: Public identifier
  /// - X-Timestamp: Unix seconds when request was signed
  /// - X-Signature: HMAC-SHA256 signature (hex)
  static Map<String, String> sign(String method, String path, String bodyString) {
    // Get current timestamp in Unix seconds
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Hash the body (SHA256, lowercase hex)
    final bodyHash = sha256.convert(utf8.encode(bodyString)).toString();

    // Build canonical string: METHOD\nPATH\nTIMESTAMP\nBODY_HASH
    final canonical = '$method\n$path\n$timestamp\n$bodyHash';

    // Compute HMAC-SHA256
    final hmacSha256 = Hmac(sha256, utf8.encode(_signingKey));
    final signature = hmacSha256.convert(utf8.encode(canonical)).toString();

    return {
      'X-Api-Key': apiKey,
      'X-Timestamp': timestamp.toString(),
      'X-Signature': signature,
    };
  }
}
