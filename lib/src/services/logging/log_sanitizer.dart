/// Sanitizes log messages to remove sensitive information.
class LogSanitizer {
  LogSanitizer._();

  /// Sanitize a message by replacing sensitive patterns.
  static String sanitize(String message) {
    var result = message;

    // JWT tokens (header.payload.signature format)
    result = result.replaceAll(
      RegExp(r'eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*'),
      '[REDACTED_JWT]',
    );

    // Bearer tokens in headers
    result = result.replaceAll(
      RegExp(r'Bearer\s+[A-Za-z0-9_-]+', caseSensitive: false),
      'Bearer [REDACTED]',
    );

    // API keys (common patterns)
    result = result.replaceAll(
      RegExp(r'api[_-]?key[=:]\s*\S{20,}', caseSensitive: false),
      'api_key=[REDACTED]',
    );

    // Authorization headers
    result = result.replaceAll(
      RegExp(r'authorization[=:]\s*\S{10,}', caseSensitive: false),
      'authorization=[REDACTED]',
    );

    // Password fields
    result = result.replaceAll(
      RegExp(r'password[=:]\s*\S+', caseSensitive: false),
      'password=[REDACTED]',
    );

    // Email addresses
    result = result.replaceAll(
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
      '[REDACTED_EMAIL]',
    );

    // Supabase keys
    result = result.replaceAll(
      RegExp(r'supabase[_-]?(?:anon|service)[_-]?key[=:]\s*\S{30,}', caseSensitive: false),
      'supabase_key=[REDACTED]',
    );

    // Generic secret/token patterns
    result = result.replaceAll(
      RegExp(r'(?:secret|token|credential)[=:]\s*\S{16,}', caseSensitive: false),
      'secret=[REDACTED]',
    );

    // Credit card numbers (16 digits with optional separators)
    result = result.replaceAll(
      RegExp(r'\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b'),
      '[REDACTED_CARD]',
    );

    // Phone numbers (US format)
    result = result.replaceAll(
      RegExp(r'\b\+?1?[-.\s]?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b'),
      '[REDACTED_PHONE]',
    );

    // URLs (http, https, wss, ws) - preserve scheme for debugging context
    /*result = result.replaceAllMapped(
      RegExp(r'(https?|wss?)://[^\s,\]}\)]+'),
      (match) => '${match.group(1)}://[REDACTED_URL]',
    );*/

    return result;
  }
}
