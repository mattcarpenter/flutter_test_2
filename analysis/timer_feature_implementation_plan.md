# Recipe Timer Feature - Implementation Plan

## Overview

This document outlines the comprehensive plan for implementing recipe step timers in the app. The feature allows users to:
- Tap detected time expressions in recipe steps to start timers
- View and manage active timers in the global status bar
- Receive platform notifications when timers expire (even when app is backgrounded)
- Extend or dismiss timers via modal dialogs

---

## Part 1: Architecture Analysis

### 1.1 Current State

#### Existing Infrastructure We Can Leverage

| Component | Location | Current Capability |
|-----------|----------|-------------------|
| `RecipeTextRenderer` | `lib/src/utils/recipe_text_renderer.dart` | Token-based rich text with tappable spans |
| `GlobalStatusBar` | `lib/src/mobile/global_status_bar.dart` | Animated status bar showing active cooks on left side |
| `CookModal` | `lib/src/features/recipes/widgets/cook_modal/` | Recipe step display with navigation |
| `AdaptivePullDownButton` | `lib/src/widgets/adaptive_pull_down/` | Platform-aware dropdown menus |
| `CupertinoAlertDialog` | Various widgets | Standard pattern for confirmations/alerts |
| `PowerSync Schema` | `lib/database/schema.dart` | `Table.localOnly()` pattern for local-only tables |
| `CookEntry` model | `lib/database/models/cooks.dart` | Reference for timer model structure |
| `Step` model | `lib/database/models/steps.dart` | Has `timerDurationSeconds` field (currently unused for detection) |

#### Current Step Display Flow

```
Step.text (raw string like "Bake for 25 minutes until golden")
    ↓
RecipeTextRenderer (parses links, bold, italic)
    ↓
RichText with formatted spans
```

**Surfaces that display steps:**
1. `RecipeStepsView` (`lib/src/features/recipes/widgets/recipe_view/recipe_steps_view.dart`)
2. `CookStepDisplay` (`lib/src/features/recipes/widgets/cook_modal/cook_content.dart`)

### 1.2 Key Architectural Decisions

#### Decision 1: Duration Detection Approach

**Option A:** Inline detection in RecipeTextRenderer (chosen)
- Add a new `_TokenType.duration` to existing token system
- Consistent with existing link/bold/italic pattern
- Reusable across recipe page and cook modal

**Rationale:**
- Leverages existing token-based architecture
- Minimal code duplication
- Consistent styling and behavior

#### Decision 2: Timer Storage Strategy

**Option A:** Local-only Drift table (chosen)
- Use `Table.localOnly()` in PowerSync schema
- No Supabase DDL, RLS policies, or sync rules needed
- Timers are inherently device-specific

**Rationale:**
- Timers are ephemeral and device-bound
- No need to sync across devices
- Simpler implementation
- Consistent with existing queue tables pattern

#### Decision 3: Notification Strategy

**Option A:** flutter_local_notifications (chosen)
- Cross-platform support (iOS, Android, macOS)
- Supports scheduled notifications with `UNTimeIntervalNotificationTrigger` on iOS
- Well-maintained, widely used
- Handles permission requests gracefully

**Rationale:**
- Platform-agnostic approach
- Single codebase for all platforms
- Mature package with good documentation
- Handles iOS/Android permission differences

#### Decision 4: Timer State Management

**Option A:** Drift + Provider pattern (chosen)
- Store timers in local SQLite via Drift
- Watch timers via Riverpod provider (similar to `cookNotifierProvider`)
- Calculate remaining time on each tick

**Rationale:**
- Consistent with existing patterns
- Timers persist across app restarts
- Easy to query active timers

---

## Part 2: Duration Detection Service

### 2.1 Supported Patterns

The duration detector must handle these patterns:

#### English Patterns
| Pattern | Example | Parsed Value |
|---------|---------|--------------|
| X minute(s) | "5 minutes", "1 minute" | 5 min, 1 min |
| X min | "5 min", "10 min" | 5 min, 10 min |
| X hour(s) | "2 hours", "1 hour" | 120 min, 60 min |
| X hr(s) | "2 hrs", "1 hr" | 120 min, 60 min |
| X second(s) | "30 seconds", "45 seconds" | 0.5 min, 0.75 min |
| X sec | "30 sec" | 0.5 min |
| Combined | "1 hour 30 minutes" | 90 min |
| Combined | "1 hour and 30 minutes" | 90 min |
| Range | "10-15 minutes" | 10-15 min (use lower bound) |
| Hyphenated | "25-minute" (adjective) | 25 min |
| To | "5 to 10 minutes" | 5-10 min (use lower bound) |

#### Japanese Patterns
| Pattern | Example | Parsed Value |
|---------|---------|--------------|
| X分 | "5分", "30分" | 5 min, 30 min |
| X時間 | "1時間", "2時間" | 60 min, 120 min |
| X秒 | "30秒" | 0.5 min |
| Combined | "1時間30分" | 90 min |
| Kanji numbers | "五分", "十分" | 5 min, 10 min |
| Half | "30分半" | 30.5 min |

### 2.2 Data Models

```dart
/// A detected duration in step text
class DetectedDuration {
  final int startIndex;        // Position in original string
  final int endIndex;          // End position in original string
  final String matchedText;    // Original matched text (e.g., "25 minutes")
  final Duration duration;     // Parsed duration value
  final Duration? rangeMax;    // For ranges like "10-15 minutes"

  const DetectedDuration({
    required this.startIndex,
    required this.endIndex,
    required this.matchedText,
    required this.duration,
    this.rangeMax,
  });
}
```

### 2.3 Duration Detection Service

**File:** `lib/src/services/duration_detection_service.dart` (new)

```dart
class DurationDetectionService {
  /// Detect all duration expressions in text
  List<DetectedDuration> detectDurations(String text);

  /// Parse a duration string to Duration
  Duration? parseDuration(String text);

  /// Check if text contains any duration expressions
  bool hasDurations(String text);
}
```

### 2.4 Regex Patterns

```dart
// English patterns
static final _englishPatterns = [
  // Combined hours and minutes: "1 hour 30 minutes", "1 hour and 30 minutes"
  RegExp(r'(\d+)\s*(?:hours?|hrs?)\s*(?:and\s*)?(\d+)\s*(?:minutes?|mins?)', caseSensitive: false),

  // Hours only: "2 hours", "1 hour", "2 hrs"
  RegExp(r'(\d+)\s*(?:hours?|hrs?)', caseSensitive: false),

  // Minutes with range: "10-15 minutes", "10 to 15 minutes"
  RegExp(r'(\d+)\s*(?:-|to)\s*(\d+)\s*(?:minutes?|mins?)', caseSensitive: false),

  // Minutes only: "25 minutes", "5 min"
  RegExp(r'(\d+)\s*(?:minutes?|mins?)', caseSensitive: false),

  // Hyphenated adjective: "25-minute"
  RegExp(r'(\d+)-(?:minute|min)', caseSensitive: false),

  // Seconds: "30 seconds", "45 sec"
  RegExp(r'(\d+)\s*(?:seconds?|secs?)', caseSensitive: false),
];

// Japanese patterns
static final _japanesePatterns = [
  // Combined: "1時間30分"
  RegExp(r'(\d+|[一二三四五六七八九十]+)時間(\d+|[一二三四五六七八九十]+)分'),

  // Hours: "2時間"
  RegExp(r'(\d+|[一二三四五六七八九十]+)時間'),

  // Minutes: "30分"
  RegExp(r'(\d+|[一二三四五六七八九十]+)分'),

  // Seconds: "30秒"
  RegExp(r'(\d+|[一二三四五六七八九十]+)秒'),
];
```

### 2.5 Integration with RecipeTextRenderer

Extend the existing token system:

```dart
enum _TokenType {
  bold,
  italic,
  link,
  recipeLink,
  duration,  // NEW
}

class _ParsedToken {
  // ... existing fields
  final Duration? duration;     // NEW: For duration tokens
  final Duration? durationMax;  // NEW: For range durations
}
```

Add duration detection to `_parseTokens()` method with a new callback parameter:

```dart
class RecipeTextRenderer extends ConsumerStatefulWidget {
  final String text;
  final TextStyle baseStyle;
  final bool enableRecipeLinks;
  final bool enableDurationLinks;           // NEW
  final void Function(Duration, String)?    // NEW: Callback when duration tapped
      onDurationTap;

  // ...
}
```

---

## Part 3: Timer Data Model

### 3.1 Timer Table Schema

**File:** `lib/database/schema.dart`

Add to schema constant:
```dart
const timersTable = 'timers';

// Add to Schema list:
Table.localOnly(timersTable, [
  Column.text('recipe_id'),
  Column.text('recipe_name'),
  Column.text('step_id'),
  Column.integer('step_number'),      // 1-indexed display number
  Column.integer('total_steps'),      // Total steps in recipe
  Column.text('detected_text'),       // Original matched text (e.g., "25 minutes")
  Column.integer('duration_seconds'), // Original duration in seconds
  Column.integer('end_timestamp'),    // Unix timestamp (ms) when timer expires
  Column.integer('created_at'),       // When timer was started
  Column.text('notification_id'),     // Platform notification ID for cancellation
]),
```

### 3.2 Timer Model

**File:** `lib/database/models/timers.dart` (new)

```dart
import 'package:drift/drift.dart';

@DataClassName('TimerEntry')
class Timers extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get recipeId => text()();
  TextColumn get recipeName => text()();
  TextColumn get stepId => text()();
  IntColumn get stepNumber => integer()();
  IntColumn get totalSteps => integer()();
  TextColumn get detectedText => text()();
  IntColumn get durationSeconds => integer()();
  IntColumn get endTimestamp => integer()();
  IntColumn get createdAt => integer()();
  TextColumn get notificationId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Extension for convenience methods
extension TimerEntryX on TimerEntry {
  /// Time remaining until expiration
  Duration get remaining {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = endTimestamp - now;
    return Duration(milliseconds: diff.clamp(0, endTimestamp));
  }

  /// Whether timer is still active (not expired)
  bool get isActive => remaining.inMilliseconds > 0;

  /// Whether timer has expired
  bool get isExpired => !isActive;

  /// Original duration as Duration object
  Duration get originalDuration => Duration(seconds: durationSeconds);

  /// Format step as "X of Y"
  String get stepDisplay => '$stepNumber of $totalSteps';
}
```

### 3.3 Timer Repository

**File:** `lib/src/repositories/timer_repository.dart` (new)

```dart
class TimerRepository {
  final AppDatabase _db;

  TimerRepository(this._db);

  /// Watch all active timers (end_timestamp > now)
  Stream<List<TimerEntry>> watchActiveTimers() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.timers.select()
      ..where((t) => t.endTimestamp.isBiggerThanValue(now))
      ..orderBy([(t) => OrderingTerm.asc(t.endTimestamp)]))
      .watch();
  }

  /// Get all active timers
  Future<List<TimerEntry>> getActiveTimers() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.timers.select()
      ..where((t) => t.endTimestamp.isBiggerThanValue(now)))
      .get();
  }

  /// Create a new timer
  Future<String> createTimer({
    required String recipeId,
    required String recipeName,
    required String stepId,
    required int stepNumber,
    required int totalSteps,
    required String detectedText,
    required int durationSeconds,
    String? notificationId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final endTimestamp = now + (durationSeconds * 1000);
    final id = const Uuid().v4();

    await _db.timers.insertOne(TimersCompanion.insert(
      id: Value(id),
      recipeId: recipeId,
      recipeName: recipeName,
      stepId: stepId,
      stepNumber: stepNumber,
      totalSteps: totalSteps,
      detectedText: detectedText,
      durationSeconds: durationSeconds,
      endTimestamp: endTimestamp,
      createdAt: now,
      notificationId: Value(notificationId),
    ));

    return id;
  }

  /// Extend a timer by adding seconds
  Future<void> extendTimer(String timerId, int additionalSeconds) async {
    final timer = await (_db.timers.select()
      ..where((t) => t.id.equals(timerId)))
      .getSingleOrNull();

    if (timer == null) return;

    final newEndTimestamp = timer.endTimestamp + (additionalSeconds * 1000);

    await (_db.timers.update()
      ..where((t) => t.id.equals(timerId)))
      .write(TimersCompanion(
        endTimestamp: Value(newEndTimestamp),
      ));
  }

  /// Cancel/delete a timer
  Future<void> cancelTimer(String timerId) async {
    await (_db.timers.delete()
      ..where((t) => t.id.equals(timerId)))
      .go();
  }

  /// Clean up expired timers (older than 1 hour)
  Future<void> cleanupExpiredTimers() async {
    final cutoff = DateTime.now().millisecondsSinceEpoch - (60 * 60 * 1000);
    await (_db.timers.delete()
      ..where((t) => t.endTimestamp.isSmallerThanValue(cutoff)))
      .go();
  }

  /// Update notification ID
  Future<void> updateNotificationId(String timerId, String notificationId) async {
    await (_db.timers.update()
      ..where((t) => t.id.equals(timerId)))
      .write(TimersCompanion(
        notificationId: Value(notificationId),
      ));
  }
}
```

---

## Part 4: Timer Provider

### 4.1 Provider Structure

**File:** `lib/src/providers/timer_provider.dart` (new)

```dart
/// Repository provider
final timerRepositoryProvider = Provider<TimerRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TimerRepository(db);
});

/// Notifier for timer operations
class TimerNotifier extends StateNotifier<AsyncValue<List<TimerEntry>>> {
  final TimerRepository _repository;
  final NotificationService _notificationService;
  StreamSubscription? _subscription;
  Timer? _tickTimer;

  TimerNotifier(this._repository, this._notificationService)
      : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // Watch active timers from database
    _subscription = _repository.watchActiveTimers().listen(
      (timers) {
        state = AsyncValue.data(timers);
        _updateTickTimer(timers);
      },
      onError: (e, s) => state = AsyncValue.error(e, s),
    );

    // Clean up old expired timers
    _repository.cleanupExpiredTimers();
  }

  void _updateTickTimer(List<TimerEntry> timers) {
    _tickTimer?.cancel();
    if (timers.isNotEmpty) {
      // Tick every second to update remaining time displays
      _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        // Force rebuild by re-emitting current state
        if (state.hasValue) {
          state = AsyncValue.data(state.value!);
        }
      });
    }
  }

  /// Start a new timer
  Future<String> startTimer({
    required String recipeId,
    required String recipeName,
    required String stepId,
    required int stepNumber,
    required int totalSteps,
    required String detectedText,
    required Duration duration,
  }) async {
    // Schedule notification
    final notificationId = await _notificationService.scheduleTimerNotification(
      recipeName: recipeName,
      stepNumber: stepNumber,
      duration: duration,
    );

    // Create timer entry
    final timerId = await _repository.createTimer(
      recipeId: recipeId,
      recipeName: recipeName,
      stepId: stepId,
      stepNumber: stepNumber,
      totalSteps: totalSteps,
      detectedText: detectedText,
      durationSeconds: duration.inSeconds,
      notificationId: notificationId,
    );

    return timerId;
  }

  /// Extend a timer
  Future<void> extendTimer(String timerId, Duration extension) async {
    final timer = state.value?.firstWhereOrNull((t) => t.id == timerId);
    if (timer == null) return;

    // Cancel old notification
    if (timer.notificationId != null) {
      await _notificationService.cancelNotification(timer.notificationId!);
    }

    // Extend in database
    await _repository.extendTimer(timerId, extension.inSeconds);

    // Schedule new notification with extended time
    final updatedTimer = await _repository.getTimer(timerId);
    if (updatedTimer != null) {
      final newNotificationId = await _notificationService.scheduleTimerNotification(
        recipeName: updatedTimer.recipeName,
        stepNumber: updatedTimer.stepNumber,
        duration: updatedTimer.remaining,
      );
      await _repository.updateNotificationId(timerId, newNotificationId);
    }
  }

  /// Cancel a timer
  Future<void> cancelTimer(String timerId) async {
    final timer = state.value?.firstWhereOrNull((t) => t.id == timerId);

    // Cancel notification
    if (timer?.notificationId != null) {
      await _notificationService.cancelNotification(timer!.notificationId!);
    }

    await _repository.cancelTimer(timerId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }
}

/// Main timer notifier provider
final timerNotifierProvider = StateNotifierProvider<TimerNotifier, AsyncValue<List<TimerEntry>>>((ref) {
  final repository = ref.watch(timerRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return TimerNotifier(repository, notificationService);
});

/// Active timers only
final activeTimersProvider = Provider<List<TimerEntry>>((ref) {
  final timersAsync = ref.watch(timerNotifierProvider);
  return timersAsync.value?.where((t) => t.isActive).toList() ?? [];
});

/// Check if there are any active timers
final hasActiveTimersProvider = Provider<bool>((ref) {
  return ref.watch(activeTimersProvider).isNotEmpty;
});

/// Timer for a specific recipe
final timersForRecipeProvider = Provider.family<List<TimerEntry>, String>((ref, recipeId) {
  final timers = ref.watch(activeTimersProvider);
  return timers.where((t) => t.recipeId == recipeId).toList();
});
```

---

## Part 5: Notification Service

### 5.1 Package Selection

**Recommended Package:** `flutter_local_notifications`

Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_local_notifications: ^17.2.4
```

**Why this package:**
- Supports iOS, Android, macOS, Linux
- Handles `UNTimeIntervalNotificationTrigger` on iOS
- Supports scheduled notifications
- Good permission handling
- Active maintenance

### 5.2 Notification Service Implementation

**File:** `lib/src/services/notification_service.dart` (new)

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,  // We'll request explicitly
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _initialized = true;
  }

  /// Request notification permissions
  /// Returns true if granted, false if denied
  Future<bool> requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      // Android 13+ requires explicit permission request
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? true;  // Older Android versions don't need permission
    }
    return true;
  }

  /// Check if notifications are permitted
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isIOS || Platform.isMacOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return result?.isEnabled ?? false;
    } else if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? true;
    }
    return true;
  }

  /// Schedule a timer notification
  /// Returns the notification ID for later cancellation
  Future<String> scheduleTimerNotification({
    required String recipeName,
    required int stepNumber,
    required Duration duration,
  }) async {
    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final idString = notificationId.toString();

    // Android notification details
    const androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Recipe Timers',
      channelDescription: 'Notifications for recipe cooking timers',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
    );

    // iOS notification details
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    // Schedule notification
    final scheduledDate = tz.TZDateTime.now(tz.local).add(duration);

    await _plugin.zonedSchedule(
      notificationId,
      'Timer Done!',
      'Step $stepNumber of $recipeName is ready',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    return idString;
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(String notificationId) async {
    final id = int.tryParse(notificationId);
    if (id != null) {
      await _plugin.cancel(id);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    // Handle iOS foreground notification (older iOS versions)
    AppLogger.debug('Received local notification: $title');
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap
    // Could navigate to timer or recipe
    AppLogger.debug('Notification response: ${response.payload}');
  }
}

/// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
```

### 5.3 Platform-Specific Configuration

#### iOS Configuration

**File:** `ios/Runner/Info.plist`

Add these keys:
```xml
<!-- Notification permissions description -->
<key>NSUserNotificationAlertStyle</key>
<string>alert</string>

<!-- Time Sensitive notifications (iOS 15+) -->
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

**File:** `ios/Runner/AppDelegate.swift`

Add notification delegate setup:
```swift
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Set notification delegate for foreground handling
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

#### Android Configuration

**File:** `android/app/src/main/AndroidManifest.xml`

Add these permissions and configurations:
```xml
<manifest ...>
    <!-- Notification permission (Android 13+) -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    <!-- Exact alarms for precise timer notifications -->
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>

    <!-- Vibration -->
    <uses-permission android:name="android.permission.VIBRATE"/>

    <application ...>
        <!-- Notification channel for Android 8+ -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="timer_channel"/>

        <!-- Boot receiver to reschedule notifications after reboot -->
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

### 5.4 Permission Handling Strategy

**App Store Review Considerations:**

1. **Request at Appropriate Time:** Don't request permission on first launch. Wait until user attempts to start their first timer.

2. **Pre-permission Prompt:** Show a custom dialog explaining why we need notifications before triggering the system prompt:

```dart
Future<bool> requestTimerNotificationPermission(BuildContext context) async {
  final notificationService = NotificationService();

  // Check if already granted
  if (await notificationService.areNotificationsEnabled()) {
    return true;
  }

  // Show explanation dialog first
  final shouldRequest = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('Enable Timer Notifications'),
      content: const Text(
        'Get notified when your cooking timers are done, '
        'even when the app is in the background.',
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Not Now'),
          onPressed: () => Navigator.pop(context, false),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('Enable'),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );

  if (shouldRequest == true) {
    return await notificationService.requestPermissions();
  }

  return false;
}
```

3. **Graceful Degradation:** Timers work without notifications - they just won't alert when app is backgrounded.

4. **Settings Deep Link:** If permission denied, offer to open Settings:

```dart
if (!granted) {
  await showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('Notifications Disabled'),
      content: const Text(
        'Timer notifications are disabled. '
        'You can enable them in Settings.',
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        CupertinoDialogAction(
          child: const Text('Open Settings'),
          onPressed: () {
            Navigator.pop(context);
            AppSettings.openAppSettings(type: AppSettingsType.notification);
          },
        ),
      ],
    ),
  );
}
```

---

## Part 6: Global Status Bar Integration

### 6.1 Layout Structure

The status bar will display:
- **Left side:** Active cooks (existing)
- **Right side:** Active timers (new)

```
┌──────────────────────────────────────────────────────────────┐
│ 🔥 Chicken Parmesan                           ⏱️ Step 3 of 6 │
│ [Instructions] [Recipe] [✓]                        4:32      │
└──────────────────────────────────────────────────────────────┘
```

### 6.2 Timer Display Component

**File:** `lib/src/mobile/global_status_bar.dart`

Add to the existing status bar:

```dart
// In build method, add timer section
Widget _buildTimerSection(BuildContext context, List<TimerEntry> activeTimers) {
  if (activeTimers.isEmpty) return const SizedBox.shrink();

  final colors = AppColors.of(context);
  final firstTimer = activeTimers.first;

  return Expanded(
    child: GestureDetector(
      onTap: () => _showTimerMenu(context, firstTimer),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer header (step info)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.timer,
                size: 14,
                color: colors.textPrimary,
              ),
              const SizedBox(width: 4),
              Text(
                'Step ${firstTimer.stepDisplay}',
                style: AppTypography.caption.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Countdown
          Text(
            _formatCountdown(firstTimer.remaining),
            style: AppTypography.h5.copyWith(
              color: colors.textPrimary,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          // Recipe name (if room)
          Text(
            firstTimer.recipeName,
            style: AppTypography.caption.copyWith(
              color: colors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

String _formatCountdown(Duration remaining) {
  final hours = remaining.inHours;
  final minutes = remaining.inMinutes.remainder(60);
  final seconds = remaining.inSeconds.remainder(60);

  if (hours > 0) {
    return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes}:${seconds.toString().padLeft(2, '0')}';
}
```

### 6.3 Timer Pull-Down Menu

When timer is tapped, show adaptive pull-down menu:

```dart
void _showTimerMenu(BuildContext context, TimerEntry timer) {
  final ref = ProviderScope.containerOf(context);

  showAdaptiveMenu(
    context: context,
    items: [
      AdaptiveMenuItem(
        title: 'Extend 1 minute',
        icon: const Icon(CupertinoIcons.plus_circle),
        onTap: () {
          ref.read(timerNotifierProvider.notifier)
              .extendTimer(timer.id, const Duration(minutes: 1));
        },
      ),
      AdaptiveMenuItem(
        title: 'Extend 5 minutes',
        icon: const Icon(CupertinoIcons.plus_circle_fill),
        onTap: () {
          ref.read(timerNotifierProvider.notifier)
              .extendTimer(timer.id, const Duration(minutes: 5));
        },
      ),
      AdaptiveMenuItem.divider(),
      AdaptiveMenuItem(
        title: 'Instructions',
        icon: const Icon(CupertinoIcons.book),
        onTap: () {
          // Check if there's an active cook for this recipe
          final activeCook = ref.read(
            activeCookForRecipeProvider(timer.recipeId)
          );
          if (activeCook != null) {
            showCookModal(context, cookId: activeCook.id, recipeId: timer.recipeId);
          } else {
            // Start a new cook at this step
            _startCookAtStep(context, timer);
          }
        },
      ),
      AdaptiveMenuItem(
        title: 'View Recipe',
        icon: const Icon(CupertinoIcons.doc_text),
        onTap: () {
          context.push('/recipe/${timer.recipeId}');
        },
      ),
      AdaptiveMenuItem.divider(),
      AdaptiveMenuItem(
        title: 'Cancel Timer',
        icon: const Icon(CupertinoIcons.xmark_circle),
        isDestructive: true,
        onTap: () {
          ref.read(timerNotifierProvider.notifier).cancelTimer(timer.id);
        },
      ),
    ],
  );
}
```

### 6.4 Visibility Logic Update

Update the status bar visibility condition:

```dart
// Current
final shouldShowStatusBar = activeCooks.isNotEmpty;

// Updated
final activeTimers = ref.watch(activeTimersProvider);
final shouldShowStatusBar = activeCooks.isNotEmpty || activeTimers.isNotEmpty;
```

### 6.5 Multiple Timers Handling

When multiple timers are active, show the one expiring soonest with a count indicator:

```dart
// Show count if multiple timers
if (activeTimers.length > 1) {
  return Stack(
    children: [
      _buildTimerDisplay(firstTimer),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${activeTimers.length}',
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
  );
}
```

---

## Part 7: Timer Expiration Modal

### 7.1 Modal Design

When a timer expires:
1. Play notification sound (if app is foreground)
2. Show Wolt modal with options

**File:** `lib/src/features/timers/widgets/timer_expired_modal.dart` (new)

```dart
void showTimerExpiredModal(
  BuildContext context, {
  required TimerEntry timer,
}) {
  final ref = ProviderScope.containerOf(context);

  WoltModalSheet.show(
    context: context,
    useRootNavigator: true,
    pageListBuilder: (modalContext) => [
      WoltModalSheetPage(
        navBarHeight: 0,
        hasTopBarLayer: false,
        backgroundColor: AppColors.of(context).background,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Timer icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.of(context).primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.timer,
                  size: 40,
                  color: AppColors.of(context).primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                'Timer Done!',
                style: AppTypography.h3.copyWith(
                  color: AppColors.of(context).textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Details
              Text(
                '${timer.recipeName}\nStep ${timer.stepDisplay}',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.of(context).textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Original duration
              Text(
                timer.detectedText,
                style: AppTypography.caption.copyWith(
                  color: AppColors.of(context).textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: '+1 min',
                      variant: AppButtonVariants.secondaryOutline,
                      size: AppButtonSize.medium,
                      onPressed: () {
                        Navigator.pop(modalContext);
                        ref.read(timerNotifierProvider.notifier)
                            .extendTimer(timer.id, const Duration(minutes: 1));
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      text: '+5 min',
                      variant: AppButtonVariants.secondaryOutline,
                      size: AppButtonSize.medium,
                      onPressed: () {
                        Navigator.pop(modalContext);
                        ref.read(timerNotifierProvider.notifier)
                            .extendTimer(timer.id, const Duration(minutes: 5));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // OK button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'OK',
                  variant: AppButtonVariants.primaryFilled,
                  size: AppButtonSize.large,
                  shape: AppButtonShape.square,
                  onPressed: () {
                    Navigator.pop(modalContext);
                    ref.read(timerNotifierProvider.notifier)
                        .cancelTimer(timer.id);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
```

### 7.2 Expiration Detection

Add a listener that triggers the modal when timers expire:

```dart
// In TimerNotifier or a separate watcher widget
void _checkForExpiredTimers(List<TimerEntry> previousTimers, List<TimerEntry> currentTimers) {
  for (final prev in previousTimers) {
    final current = currentTimers.firstWhereOrNull((t) => t.id == prev.id);

    // Timer was active before, now expired or removed
    if (prev.isActive && (current == null || current.isExpired)) {
      // Show expiration modal
      _showExpirationModal(prev);
    }
  }
}
```

---

## Part 8: UI Integration

### 8.1 Start Timer Dialog

When user taps a duration in step text:

```dart
void showStartTimerDialog(
  BuildContext context, {
  required Recipe recipe,
  required Step step,
  required int stepNumber,
  required int totalSteps,
  required Duration duration,
  required String detectedText,
}) {
  final ref = ProviderScope.containerOf(context);

  showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('Start Timer?'),
      content: Text(
        'Start a $detectedText timer for\n'
        '${recipe.title}\n'
        'Step $stepNumber of $totalSteps',
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('Start'),
          onPressed: () async {
            Navigator.pop(context);

            // Check/request notification permission
            final notificationService = ref.read(notificationServiceProvider);
            final hasPermission = await notificationService.areNotificationsEnabled();

            if (!hasPermission && context.mounted) {
              await requestTimerNotificationPermission(context);
            }

            // Start the timer
            await ref.read(timerNotifierProvider.notifier).startTimer(
              recipeId: recipe.id,
              recipeName: recipe.title,
              stepId: step.id,
              stepNumber: stepNumber,
              totalSteps: totalSteps,
              detectedText: detectedText,
              duration: duration,
            );
          },
        ),
      ],
    ),
  );
}
```

### 8.2 RecipeTextRenderer Integration

Update to include duration detection:

```dart
// In recipe_steps_view.dart
RecipeTextRenderer(
  text: step.text,
  baseStyle: baseBodyStyle.copyWith(
    fontSize: scaledFontSize,
    color: colors.contentPrimary,
  ),
  enableRecipeLinks: true,
  enableDurationLinks: true,  // NEW
  onDurationTap: (duration, detectedText) {  // NEW
    showStartTimerDialog(
      context,
      recipe: recipe,
      step: step,
      stepNumber: stepNumber,
      totalSteps: totalSteps,
      duration: duration,
      detectedText: detectedText,
    );
  },
)
```

### 8.3 Duration Span Styling

Detected durations should be styled to indicate they're tappable:

```dart
// In RecipeTextRenderer._buildTokenSpan()
case _TokenType.duration:
  final recognizer = TapGestureRecognizer()
    ..onTap = () => widget.onDurationTap?.call(
      token.duration!,
      token.content,
    );
  _recognizers.add(recognizer);

  return TextSpan(
    text: token.content,
    style: widget.baseStyle.copyWith(
      color: Theme.of(context).primaryColor,
      fontWeight: FontWeight.w500,
    ),
    recognizer: recognizer,
  );
```

### 8.4 Cook Modal Integration

The cook modal also needs duration detection in step text:

```dart
// In cook_content.dart CookStepDisplay
// Apply same RecipeTextRenderer with duration detection
```

---

## Part 9: Testing Strategy

### 9.1 Unit Tests

#### Duration Detection Tests (`test/services/duration_detection_service_test.dart`)

```dart
group('DurationDetectionService', () {
  // English patterns
  test('detects simple minutes', () {
    final results = detectDurations('Bake for 25 minutes');
    expect(results, hasLength(1));
    expect(results[0].duration, equals(const Duration(minutes: 25)));
    expect(results[0].matchedText, equals('25 minutes'));
  });

  test('detects hours', () {
    final results = detectDurations('Let rise for 2 hours');
    expect(results[0].duration, equals(const Duration(hours: 2)));
  });

  test('detects combined hours and minutes', () {
    final results = detectDurations('Cook for 1 hour 30 minutes');
    expect(results[0].duration, equals(const Duration(hours: 1, minutes: 30)));
  });

  test('detects ranges and uses lower bound', () {
    final results = detectDurations('Simmer for 10-15 minutes');
    expect(results[0].duration, equals(const Duration(minutes: 10)));
    expect(results[0].rangeMax, equals(const Duration(minutes: 15)));
  });

  test('detects hyphenated adjective form', () {
    final results = detectDurations('Give it a 25-minute rest');
    expect(results[0].duration, equals(const Duration(minutes: 25)));
  });

  test('detects seconds', () {
    final results = detectDurations('Microwave for 30 seconds');
    expect(results[0].duration, equals(const Duration(seconds: 30)));
  });

  test('detects multiple durations in same text', () {
    final results = detectDurations('Cook 5 minutes, flip, then 3 minutes more');
    expect(results, hasLength(2));
  });

  // Japanese patterns
  test('detects Japanese minutes', () {
    final results = detectDurations('5分間蒸す');
    expect(results[0].duration, equals(const Duration(minutes: 5)));
  });

  test('detects Japanese hours', () {
    final results = detectDurations('1時間煮込む');
    expect(results[0].duration, equals(const Duration(hours: 1)));
  });

  test('detects Japanese combined time', () {
    final results = detectDurations('1時間30分');
    expect(results[0].duration, equals(const Duration(hours: 1, minutes: 30)));
  });

  test('detects kanji numbers', () {
    final results = detectDurations('五分待つ');
    expect(results[0].duration, equals(const Duration(minutes: 5)));
  });

  // Edge cases
  test('ignores non-time numbers', () {
    final results = detectDurations('Add 2 cups flour');
    expect(results, isEmpty);
  });

  test('handles text with no durations', () {
    final results = detectDurations('Mix well and serve');
    expect(results, isEmpty);
  });
});
```

#### Timer Repository Tests (`test/repositories/timer_repository_test.dart`)

```dart
group('TimerRepository', () {
  test('creates timer with correct end timestamp', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await repository.createTimer(
      recipeId: 'recipe-1',
      recipeName: 'Test Recipe',
      stepId: 'step-1',
      stepNumber: 1,
      totalSteps: 5,
      detectedText: '10 minutes',
      durationSeconds: 600,
    );

    final timer = await repository.getTimer(id);
    expect(timer!.endTimestamp, closeTo(now + 600000, 1000));
  });

  test('extends timer by adding seconds', () async {
    // Create and extend
    final id = await repository.createTimer(..., durationSeconds: 60);
    final originalEnd = (await repository.getTimer(id))!.endTimestamp;

    await repository.extendTimer(id, 120);

    final extended = await repository.getTimer(id);
    expect(extended!.endTimestamp, equals(originalEnd + 120000));
  });

  test('watchActiveTimers only returns non-expired', () async {
    // Create expired and active timers
    await repository.createTimer(..., durationSeconds: -60); // Already expired
    await repository.createTimer(..., durationSeconds: 300);  // Active

    final activeTimers = await repository.watchActiveTimers().first;
    expect(activeTimers, hasLength(1));
  });
});
```

### 9.2 Widget Tests

```dart
group('Timer UI', () {
  testWidgets('duration text is tappable and styled', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: RecipeTextRenderer(
            text: 'Bake for 25 minutes',
            baseStyle: const TextStyle(),
            enableDurationLinks: true,
            onDurationTap: (duration, text) {},
          ),
        ),
      ),
    );

    // Find the duration text
    final durationFinder = find.text('25 minutes');
    expect(durationFinder, findsOneWidget);

    // Verify it has primary color
    final textWidget = tester.widget<RichText>(find.byType(RichText));
    // ... verify styling
  });

  testWidgets('tapping duration shows start dialog', (tester) async {
    // ...
  });

  testWidgets('status bar shows active timer', (tester) async {
    // ...
  });
});
```

### 9.3 Integration Tests

```dart
group('Timer Integration', () {
  testWidgets('full timer flow: detect, start, expire, dismiss', (tester) async {
    // 1. Navigate to recipe with duration in step
    // 2. Tap duration text
    // 3. Confirm start timer
    // 4. Verify status bar shows timer
    // 5. Fast-forward time
    // 6. Verify expiration modal appears
    // 7. Dismiss modal
    // 8. Verify timer removed from status bar
  });

  testWidgets('extend timer works correctly', (tester) async {
    // ...
  });

  testWidgets('cancel timer removes from status bar', (tester) async {
    // ...
  });
});
```

---

## Part 10: Implementation Order

### Phase 1: Foundation (Duration Detection)
1. Create `DurationDetectionService` with English patterns
2. Add Japanese pattern support
3. Write comprehensive unit tests
4. Integrate with `RecipeTextRenderer` as new token type

### Phase 2: Data Layer (Timer Storage)
5. Add `timersTable` to PowerSync schema
6. Create `TimerEntry` Drift model
7. Create `TimerRepository` with CRUD operations
8. Run `build_runner` to generate code

### Phase 3: State Management
9. Create `TimerNotifier` and providers
10. Implement timer creation/extension/cancellation
11. Add tick timer for countdown updates

### Phase 4: Notifications
12. Add `flutter_local_notifications` dependency
13. Create `NotificationService`
14. Configure iOS platform settings
15. Configure Android platform settings
16. Implement permission request flow

### Phase 5: UI - Recipe Pages
17. Update `RecipeTextRenderer` to detect and style durations
18. Create start timer confirmation dialog
19. Integrate with `RecipeStepsView`
20. Integrate with `CookStepDisplay` (cook modal)

### Phase 6: UI - Status Bar
21. Add timer section to `GlobalStatusBar`
22. Implement timer countdown display
23. Create timer pull-down menu
24. Handle multiple timers display

### Phase 7: Expiration Handling
25. Create `TimerExpiredModal`
26. Implement expiration detection
27. Connect modal trigger to provider

### Phase 8: Polish
28. Handle edge cases (app backgrounded, multiple timers)
29. Add haptic feedback
30. Test on real devices (iOS and Android)
31. Performance optimization

---

## Part 11: File Changes Summary

### New Files to Create

| File | Purpose |
|------|---------|
| `lib/src/services/duration_detection_service.dart` | Detect time expressions in text |
| `lib/src/services/notification_service.dart` | Platform notification handling |
| `lib/database/models/timers.dart` | Timer Drift model |
| `lib/src/repositories/timer_repository.dart` | Timer database operations |
| `lib/src/providers/timer_provider.dart` | Timer state management |
| `lib/src/features/timers/widgets/timer_expired_modal.dart` | Expiration dialog |
| `lib/src/features/timers/widgets/start_timer_dialog.dart` | Start confirmation |
| `test/services/duration_detection_service_test.dart` | Detection tests |
| `test/repositories/timer_repository_test.dart` | Repository tests |

### Files to Modify

| File | Changes |
|------|---------|
| `lib/database/schema.dart` | Add `timersTable` local-only table |
| `lib/database/database.dart` | Add Timers table to database |
| `lib/src/utils/recipe_text_renderer.dart` | Add duration token type and styling |
| `lib/src/mobile/global_status_bar.dart` | Add timer section on right side |
| `lib/src/features/recipes/widgets/recipe_view/recipe_steps_view.dart` | Enable duration links |
| `lib/src/features/recipes/widgets/cook_modal/cook_content.dart` | Enable duration links |
| `pubspec.yaml` | Add `flutter_local_notifications` |
| `ios/Runner/Info.plist` | Add notification permissions |
| `ios/Runner/AppDelegate.swift` | Add notification delegate |
| `android/app/src/main/AndroidManifest.xml` | Add notification permissions |

---

## Part 12: Considerations and Edge Cases

### 12.1 Edge Cases to Handle

1. **App killed while timer running:**
   - Timer persists in database
   - On app launch, check for expired timers and show modal
   - Platform notification still fires

2. **Multiple timers for same recipe/step:**
   - Allow it (user might want backup timer)
   - Show most urgent in status bar

3. **Timer extends past midnight:**
   - No special handling needed (using Unix timestamps)

4. **Very long durations (hours):**
   - Display format adapts (HH:MM:SS vs MM:SS)
   - Same notification approach

5. **Device restart:**
   - Android: Boot receiver reschedules notifications
   - iOS: Notifications persist in system
   - App: Reads timers from database on launch

6. **Time zone changes:**
   - Using Unix timestamps, so no issue

7. **Duration in recipe title/notes:**
   - Only detect in step text (not title, description, notes)

### 12.2 Performance Considerations

1. **Tick timer for countdown:**
   - Only run when status bar is visible
   - 1-second interval is sufficient
   - Dispose when no active timers

2. **Database queries:**
   - Use stream for reactive updates
   - Index on `end_timestamp` for efficient queries

3. **Notification scheduling:**
   - Async, doesn't block UI
   - Clean up old notifications periodically

### 12.3 Accessibility

1. **VoiceOver/TalkBack:**
   - Duration spans should be announced as buttons
   - Countdown in status bar should be accessible

2. **Dynamic Type:**
   - Timer modal and status bar should respect font scaling

### 12.4 Localization

1. **Duration detection is language-aware:**
   - English patterns for en_* locales
   - Japanese patterns for ja_* locales
   - Can add more languages later

2. **UI strings:**
   - "Start Timer?", "Timer Done!", etc. should be localized
   - Use existing l10n infrastructure

---

## Part 13: Open Questions for Review

1. **Multiple timer display in status bar:**
   - Show count badge? (proposed)
   - Show all timers in scrollable row?
   - Expand to show all on tap?

2. **Timer notification sound:**
   - Use default system sound?
   - Custom sound for differentiation?
   - User preference setting?

3. **Timer for ranges (e.g., "10-15 minutes"):**
   - Use lower bound? (proposed)
   - Ask user to choose?
   - Show as "10 min" with note about range?

4. **Quick-start without confirmation:**
   - Always show confirmation dialog? (proposed)
   - Add setting for "quick start"?
   - Long-press for quick start, tap for confirm?

5. **Timer history/log:**
   - Keep completed timers for reference?
   - Show in cooking history?
   - Out of scope for initial implementation?

6. **Haptic feedback:**
   - On timer start?
   - On each second? (probably too much)
   - On expiration?

---

## Appendix A: Duration Regex Reference

### English Patterns (Priority Order)

```regex
# Combined hours and minutes (must be first)
(\d+)\s*(?:hours?|hrs?)\s*(?:and\s*)?(\d+)\s*(?:minutes?|mins?)

# Hours only
(\d+)\s*(?:hours?|hrs?)

# Minutes with range
(\d+)\s*(?:-|to)\s*(\d+)\s*(?:minutes?|mins?)

# Minutes only
(\d+)\s*(?:minutes?|mins?)

# Hyphenated adjective
(\d+)-(?:minute|min)

# Seconds with range
(\d+)\s*(?:-|to)\s*(\d+)\s*(?:seconds?|secs?)

# Seconds only
(\d+)\s*(?:seconds?|secs?)
```

### Japanese Patterns (Priority Order)

```regex
# Kanji number mapping
一=1, 二=2, 三=3, 四=4, 五=5, 六=6, 七=7, 八=8, 九=9, 十=10
十一=11, 十二=12, ... 二十=20, etc.

# Combined
(\d+|[一二三四五六七八九十]+)時間(\d+|[一二三四五六七八九十]+)分

# Hours
(\d+|[一二三四五六七八九十]+)時間

# Minutes
(\d+|[一二三四五六七八九十]+)分

# Seconds
(\d+|[一二三四五六七八九十]+)秒
```

---

## Appendix B: Notification Channel Configuration

### Android Notification Channel

```dart
const AndroidNotificationChannel timerChannel = AndroidNotificationChannel(
  'timer_channel',
  'Recipe Timers',
  description: 'Notifications for recipe cooking timers',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
  enableLights: true,
  ledColor: Color(0xFF2196F3),
);
```

### iOS Notification Categories

```dart
// For potential future action buttons on notifications
const DarwinNotificationCategory timerCategory = DarwinNotificationCategory(
  'timer_category',
  actions: [
    DarwinNotificationAction.plain(
      'extend_1',
      '+1 min',
      options: {DarwinNotificationActionOption.foreground},
    ),
    DarwinNotificationAction.plain(
      'extend_5',
      '+5 min',
      options: {DarwinNotificationActionOption.foreground},
    ),
    DarwinNotificationAction.plain(
      'dismiss',
      'Dismiss',
      options: {DarwinNotificationActionOption.destructive},
    ),
  ],
);
```