import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

Future<void> deleteAllUsers() async {
  String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  String serviceRoleKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';

  final response = await http.get(
    Uri.parse('$supabaseUrl/auth/v1/admin/users'),
    headers: {
      'apikey': serviceRoleKey,
      'Authorization': 'Bearer $serviceRoleKey',
    },
  );

  if (response.statusCode == 200) {
    final users = jsonDecode(response.body)['users'];
    for (var user in users) {
      final userId = user['id'];
      await http.delete(
        Uri.parse('$supabaseUrl/auth/v1/admin/users/$userId'),
        headers: {
          'apikey': serviceRoleKey,
          'Authorization': 'Bearer $serviceRoleKey',
        },
      );
      print("Deleted user: $userId");
    }
  } else {
    print("Failed to retrieve users: ${response.body}");
  }
}

Future<void> truncateAllTables() async {
  final String postgresHost = dotenv.env['POSTGRES_HOST'] ?? '';
  final String postgresDbName = dotenv.env['POSTGRES_DB_NAME'] ?? '';
  final String postgresUsername = dotenv.env['POSTGRES_USERNAME'] ?? '';
  final String postgresPassword = dotenv.env['POSTGRES_PASSWORD'] ?? '';

  final connection = await Connection.open(
    Endpoint(
      host: postgresHost,
      database: postgresDbName,
      username: postgresUsername,
      password: postgresPassword,
      port: 5433,
    ),
    settings: const ConnectionSettings(
      sslMode: SslMode.disable
    )
  );

  try {
    print("Connected to PostgreSQL.");

    final truncateQuery = """
      DO \$\$
      DECLARE r RECORD;
      BEGIN
        FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
          EXECUTE 'TRUNCATE TABLE public.' || quote_ident(r.tablename) || ' CASCADE';
        END LOOP;
      END \$\$;
    """;

    await connection.execute(truncateQuery);
    print("All tables truncated successfully.");

  } catch (e) {
    print("Error truncating tables: $e");
  } finally {
    await connection.close();
    print("Connection closed.");
  }
}
