import 'package:flutter/services.dart';
import 'logging/app_logger.dart';

class AppGroupChannel {
  static const _channel = MethodChannel('app.stockpot.app/app_group');

  /// Get the App Group container path
  static Future<String?> getContainerPath() async {
    try {
      final path = await _channel.invokeMethod<String>('getContainerPath');
      return path;
    } on PlatformException catch (e) {
      AppLogger.error('Failed to get App Group path', e);
      return null;
    }
  }
}
