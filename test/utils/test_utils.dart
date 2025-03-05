import 'dart:async';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

loadEnvVars() async {
  final envFilePath = p.join(Directory.current.path, '.env.test');
  await dotenv.load(fileName: envFilePath);
}

/// Waits until the [provider] emits a state for which [predicate] returns true.
/// If it doesn’t happen within [timeout], throws a [TimeoutException].
Future<T> waitForProviderValue<T>(
    ProviderContainer container,
    ProviderListenable<AsyncValue<T>> provider,
    bool Function(T value) predicate, {
      Duration timeout = const Duration(seconds: 10),
    }) async {
  final completer = Completer<T>();

  // Listen to provider state changes.
  final listener = container.listen(provider, (previous, next) {
    next.whenOrNull(
      data: (value) {
        if (predicate(value) && !completer.isCompleted) {
          completer.complete(value);
        }
      },
      error: (error, stack) {
        if (!completer.isCompleted) {
          completer.completeError(error, stack);
        }
      },
    );
  });

  // Wait for the condition to be met.
  final result = await completer.future.timeout(
    timeout,
    onTimeout: () {
      listener.close();
      throw TimeoutException(
        'Provider did not meet the predicate within $timeout.',
      );
    },
  );

  // Clean up listener after completion.
  listener.close();
  return result;
}

