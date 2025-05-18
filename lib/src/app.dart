import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/src/providers/recipe_provider.dart';
import 'package:recipe_app/src/windows/app.dart';
import 'macos/app.dart';
import 'mobile/adaptive_app.dart';
import 'settings/settings_controller.dart';
import 'providers/app_services_provider.dart';

/// The Widget that configures your application.
class MyApp extends ConsumerWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize background services
    ref.watch(appServicesProvider);

    // Seed data (async) import seed recipes
    ref.read(recipeNotifierProvider.notifier).importSeedRecipes(limit: 100);

    // Glue the SettingsController to the MaterialApp.
    //
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        if (Platform.isIOS || Platform.isAndroid) {
          return const AdaptiveApp2();
        } else if (Platform.isWindows) {
          return const WindowsApp();
        } else if (Platform.isMacOS) {
          return const MacApp();
        }

        return const AdaptiveApp2();
      },
    );
  }
}
