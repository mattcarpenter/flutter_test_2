import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:recipe_app/src/models/recipe_folder.model.dart';
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'src/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<void> _configureMacosWindowUtils() async {
  const config = MacosWindowUtilsConfig(
    toolbarStyle: NSWindowToolbarStyle.unified,
  );
  await config.apply();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await BaseRepository.configure(databaseFactory);

  await BaseRepository().initialize();

  // Set up the SettingsController, which will glue user settings to multiple
  // Flutter Widgets.
  final settingsController = SettingsController(SettingsService());

  final directory = await getApplicationDocumentsDirectory();
  print('SQLite DB Path: ${directory.path}');

  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  if (Platform.isMacOS) {
    await _configureMacosWindowUtils();
  }

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(ProviderScope(child: MyApp(settingsController: settingsController)));
}
