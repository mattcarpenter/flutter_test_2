import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path/path.dart' as p;
import 'package:recipe_app/app_config.dart';
import 'package:recipe_app/database/powersync.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async {
    return Directory.systemTemp.path;
  }
}

resetDatabase () async {
  final testDbPath = p.join(Directory.current.path, 'database', 'test.db');
  final dbFile = File(testDbPath);
  if (await dbFile.exists()) {
    await dbFile.delete();
    print('Deleted existing test database file at $testDbPath');
  }
}

initializeTestEnvironment() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  PathProviderPlatform.instance = FakePathProviderPlatform();

  await AppConfig.initialize(isTest: true);
  await resetDatabase();
  await openDatabase(isTest: true);
}

