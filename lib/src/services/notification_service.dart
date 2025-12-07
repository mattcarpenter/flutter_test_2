import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'logging/app_logger.dart';

/// Exception thrown when notification operations fail
class NotificationApiException implements Exception {
  final String message;
  final String? code;
  final NotificationErrorType type;

  NotificationApiException({
    required this.message,
    this.code,
    required this.type,
  });

  @override
  String toString() => 'NotificationApiException: $message';
}

/// Types of notification errors
enum NotificationErrorType {
  permissionDenied,
  platformNotSupported,
  schedulingFailed,
  initializationFailed,
  unknown,
}

/// Service for managing local notifications for recipe timers.
///
/// This service handles platform-specific notification initialization,
/// permission requests, and scheduling timer notifications.
///
/// Usage:
/// ```dart
/// final notificationService = NotificationService.instance;
/// await notificationService.initialize();
///
/// if (await notificationService.areNotificationsEnabled()) {
///   final id = await notificationService.scheduleTimerNotification(
///     recipeName: 'Chocolate Cake',
///     stepNumber: 3,
///     duration: Duration(minutes: 25),
///   );
/// }
/// ```
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Android notification channel configuration
  static const String _channelId = 'timer_channel';
  static const String _channelName = 'Recipe Timers';
  static const String _channelDescription =
      'Notifications for recipe cooking timers';

  /// Initialize the notification service.
  ///
  /// Must be called once at app startup before using other methods.
  /// Safe to call multiple times - subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.debug('NotificationService already initialized');
      return;
    }

    try {
      AppLogger.debug('Initializing NotificationService');

      // Initialize timezone data for scheduled notifications
      tz_data.initializeTimeZones();
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
      AppLogger.debug('Timezone initialized: ${tz.local.name}');

      if (Platform.isAndroid) {
        await _initializeAndroid();
      } else if (Platform.isIOS || Platform.isMacOS) {
        await _initializeApple();
      } else {
        AppLogger.warning(
          'NotificationService: Platform ${Platform.operatingSystem} not supported',
        );
        throw NotificationApiException(
          message: 'Platform ${Platform.operatingSystem} not supported',
          type: NotificationErrorType.platformNotSupported,
        );
      }

      _isInitialized = true;
      AppLogger.info('NotificationService initialized successfully');
    } catch (e, stack) {
      AppLogger.error('Failed to initialize NotificationService', e, stack);
      throw NotificationApiException(
        message: 'Failed to initialize notifications: $e',
        type: NotificationErrorType.initializationFailed,
      );
    }
  }

  /// Initialize Android-specific notification settings
  Future<void> _initializeAndroid() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Create high-priority notification channel for timers
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Create the notification channel
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    AppLogger.debug('Android notification channel created: $_channelId');
  }

  /// Initialize iOS/macOS-specific notification settings
  Future<void> _initializeApple() async {
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We'll request explicitly
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const macosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final initSettings = InitializationSettings(
      iOS: iosSettings,
      macOS: macosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    AppLogger.debug('Apple notification settings initialized');
  }

  /// Handle notification tap responses
  void _handleNotificationResponse(NotificationResponse response) {
    AppLogger.debug(
      'Notification tapped: id=${response.id}, payload=${response.payload}',
    );
    // Future enhancement: Navigate to cook modal or recipe when notification is tapped
  }

  /// Request notification permissions from the user.
  ///
  /// Returns true if permissions were granted, false otherwise.
  /// On Android 12 and below, this always returns true as permissions
  /// are granted at install time.
  Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      AppLogger.warning(
        'Attempting to request permissions before initialization',
      );
      await initialize();
    }

    try {
      AppLogger.debug('Requesting notification permissions');

      if (Platform.isAndroid) {
        // Android 13+ requires runtime permission request
        final androidImplementation =
            _notifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          final granted = await androidImplementation.requestNotificationsPermission();
          AppLogger.info('Android notification permission granted: $granted');
          return granted ?? false;
        }

        // Android 12 and below - permissions granted at install time
        return true;
      } else if (Platform.isIOS) {
        final iosImplementation =
            _notifications.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();

        if (iosImplementation != null) {
          final granted = await iosImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          AppLogger.info('iOS notification permission granted: $granted');
          return granted ?? false;
        }
      } else if (Platform.isMacOS) {
        final macosImplementation =
            _notifications.resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>();

        if (macosImplementation != null) {
          final granted = await macosImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          AppLogger.info('macOS notification permission granted: $granted');
          return granted ?? false;
        }
      }

      AppLogger.warning('Could not resolve platform implementation');
      return false;
    } catch (e, stack) {
      AppLogger.error('Failed to request notification permissions', e, stack);
      throw NotificationApiException(
        message: 'Failed to request permissions: $e',
        type: NotificationErrorType.permissionDenied,
      );
    }
  }

  /// Check if notifications are currently enabled.
  ///
  /// Returns true if the user has granted notification permissions.
  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) {
      AppLogger.warning(
        'Checking permissions before initialization',
      );
      await initialize();
    }

    try {
      if (Platform.isAndroid) {
        final androidImplementation =
            _notifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          final granted = await androidImplementation.areNotificationsEnabled();
          return granted ?? false;
        }

        // Fallback for older Android versions
        return true;
      } else if (Platform.isIOS) {
        // For iOS, check permission status
        final iosImplementation =
            _notifications.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();

        if (iosImplementation != null) {
          final granted = await iosImplementation.checkPermissions();
          // Consider enabled if alert permission is granted
          return granted?.isEnabled ?? false;
        }
      } else if (Platform.isMacOS) {
        // For macOS, check permission status
        final macosImplementation =
            _notifications.resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>();

        if (macosImplementation != null) {
          final granted = await macosImplementation.checkPermissions();
          // Consider enabled if alert permission is granted
          return granted?.isEnabled ?? false;
        }
      }

      AppLogger.warning('Could not check notification permissions for platform');
      return false;
    } catch (e, stack) {
      AppLogger.error('Failed to check notification permissions', e, stack);
      return false;
    }
  }

  /// Schedule a timer notification for a recipe step.
  ///
  /// Returns the notification ID as a string, which can be used to cancel
  /// the notification later.
  ///
  /// Throws [NotificationApiException] if scheduling fails.
  Future<String> scheduleTimerNotification({
    required String recipeName,
    required int stepNumber,
    required Duration duration,
  }) async {
    if (!_isInitialized) {
      AppLogger.warning('Scheduling notification before initialization');
      await initialize();
    }

    try {
      // Generate unique notification ID from timestamp
      final notificationId = (DateTime.now().millisecondsSinceEpoch / 1000).floor();

      // Calculate scheduled time
      final scheduledTime = tz.TZDateTime.now(tz.local).add(duration);

      AppLogger.debug(
        'Scheduling timer notification: id=$notificationId, '
        'recipe="$recipeName", step=$stepNumber, duration=$duration',
      );

      if (Platform.isAndroid) {
        await _scheduleAndroidNotification(
          notificationId: notificationId,
          recipeName: recipeName,
          stepNumber: stepNumber,
          scheduledTime: scheduledTime,
        );
      } else if (Platform.isIOS || Platform.isMacOS) {
        await _scheduleAppleNotification(
          notificationId: notificationId,
          recipeName: recipeName,
          stepNumber: stepNumber,
          scheduledTime: scheduledTime,
        );
      }

      final notificationIdStr = notificationId.toString();
      AppLogger.info(
        'Timer notification scheduled: id=$notificationIdStr, '
        'fires at ${scheduledTime.toIso8601String()}',
      );

      return notificationIdStr;
    } catch (e, stack) {
      AppLogger.error('Failed to schedule timer notification', e, stack);
      throw NotificationApiException(
        message: 'Failed to schedule notification: $e',
        type: NotificationErrorType.schedulingFailed,
      );
    }
  }

  /// Schedule Android-specific notification
  Future<void> _scheduleAndroidNotification({
    required int notificationId,
    required String recipeName,
    required int stepNumber,
    required tz.TZDateTime scheduledTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      notificationId,
      'Timer Done!',
      'Step $stepNumber of $recipeName is ready',
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule iOS/macOS-specific notification
  Future<void> _scheduleAppleNotification({
    required int notificationId,
    required String recipeName,
    required int stepNumber,
    required tz.TZDateTime scheduledTime,
  }) async {
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const macosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const notificationDetails = NotificationDetails(
      iOS: iosDetails,
      macOS: macosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      'Timer Done!',
      'Step $stepNumber of $recipeName is ready',
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel a scheduled notification by its ID.
  ///
  /// Safe to call even if the notification doesn't exist or has already fired.
  Future<void> cancelNotification(String notificationId) async {
    if (!_isInitialized) {
      AppLogger.warning('Cancelling notification before initialization');
      await initialize();
    }

    try {
      final id = int.parse(notificationId);
      await _notifications.cancel(id);
      AppLogger.debug('Cancelled notification: id=$notificationId');
    } catch (e, stack) {
      AppLogger.error('Failed to cancel notification: id=$notificationId', e, stack);
      // Don't throw - cancellation failures shouldn't block the app
    }
  }

  /// Cancel all scheduled notifications.
  ///
  /// This is useful when the user finishes or exits a cook session.
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) {
      AppLogger.warning('Cancelling all notifications before initialization');
      await initialize();
    }

    try {
      await _notifications.cancelAll();
      AppLogger.info('Cancelled all notifications');
    } catch (e, stack) {
      AppLogger.error('Failed to cancel all notifications', e, stack);
      // Don't throw - cancellation failures shouldn't block the app
    }
  }
}
