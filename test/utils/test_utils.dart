import 'dart:async';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path/path.dart' as p;
import 'package:recipe_app/app_config.dart';
import 'package:recipe_app/database/database.dart';
import 'package:recipe_app/database/powersync.dart';
import 'package:recipe_app/src/providers/recipe_folder_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_user_manager.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
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
  // Check the current state first.
  final current = container.read(provider);
  final value = current.value;
  print('waitForProviderValue: initial state: $value');
  if (current is AsyncData<T> && predicate(current.value)) {
    return current.value;
  }

  final completer = Completer<T>();

  final listener = container.listen(provider, (previous, next) {
    next.whenOrNull(
      data: (value) {
        print('waitForProviderValue: updated state: $value');
        if (predicate(value) && !completer.isCompleted) {
          completer.complete(value);
        }
      },
      error: (error, stack) {
        if (!completer.isCompleted) {
          print('waitForProviderValue: error: $error');
          completer.completeError(error, stack);
        }
      },
    );
  });

  final result = await completer.future.timeout(
    timeout,
    onTimeout: () {
      listener.close();
      throw TimeoutException(
        'Provider did not meet the predicate within $timeout.',
      );
    },
  );

  listener.close();
  return result;
}


Future<void> withTestUser(String username, Future<void> Function() action) async {
  await TestUserManager.loginAsTestUser(username);
  print('Logged in $username');
  try {
    await action();
  } finally {
    await Future.delayed(const Duration(seconds: 1));
    await TestUserManager.logoutTestUser();
    await Future.delayed(const Duration(seconds: 1));
    print('Logged out test user $username');
  }
}


Future<void> waitForFolder({
  required ProviderContainer container,
  required String folderName,
  required int expectedCount,
}) async {
  await waitForProviderValue<List<RecipeFolderEntry>>(
    container,
    recipeFolderNotifierProvider,
        (folders) => folders.where((f) => f.name == folderName).length == expectedCount,
  );
}

Future<void> waitForNoFolder({
  required ProviderContainer container,
  required String folderName,
}) async {
  await waitForProviderValue<List<RecipeFolderEntry>>(
    container,
    recipeFolderNotifierProvider,
        (folders) => !folders.any((f) => f.name == folderName),
  );
}


