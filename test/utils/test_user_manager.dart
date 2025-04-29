import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_admin.dart';
import 'test_utils.dart';

class TestUserManager {

  static const testUserPassword = 'TestPassword123!';

  static Future<void> createTestUsers(List<String> usernames) async {
    for (final username in usernames) {
      final email = "$username@example.com";
      await createUser(email, testUserPassword);
    }
  }

  static Future<void> createTestUser(String username) async {
    final email = "$username@example.com";
    await createUser(email, testUserPassword);
  }

  static Future<void> deleteAllTestUsers() async {
    await deleteAllUsers();
  }

  static Future<void> loginAsTestUser(String username) async {
    final email = "$username@example.com";
    await Supabase.instance.client.auth
        .signInWithPassword(email: email, password: testUserPassword);
  }

  static Future<void> logoutTestUser() async {
    await Supabase.instance.client.auth.signOut();
  }

  static Future<void> wipeAlLocalAndRemoteTestUserData() async {
    await Supabase.instance.client.auth.signOut();
    await truncateAllTables();
    await deleteAllUsers();
    await clearMaterializedTables();
  }

}
