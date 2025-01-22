import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test_2/src/mobile/app.dart';
import 'package:flutter_test_2/src/windows/app.dart';
import 'macos/app.dart';
import 'settings/settings_controller.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    // Glue the SettingsController to the MaterialApp.
    //
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        if (Platform.isIOS || Platform.isAndroid) {
          return const AdaptiveApp();
        } else if (Platform.isWindows) {
          return const WindowsApp();
        } else if (Platform.isMacOS) {
          return const MacApp();
        }

        return const AdaptiveApp();
      },
    );
  }
}
