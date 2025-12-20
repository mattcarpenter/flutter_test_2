# iOS Share Extension Implementation Plan

## Overview

This document outlines the implementation of an iOS Share Extension that allows users to share content (URLs, text, images, videos, files) from any app into the Stockpot recipe app. The extension normalizes all shared content into a session manifest + copied files in an App Group container, then opens the Flutter app via URL scheme with only a sessionId.

**Phase 1 Scope (This Document):**
- Receive shared content from other apps
- Copy files to App Group container
- Open Flutter app with session ID
- Display shared content info in a Wolt modal (inspection only)
- No actual import/processing of shared recipes

---

## Confirmed Decisions

| Decision | Choice | Notes |
|----------|--------|-------|
| **Implementation Approach** | Native Swift | Full control over file copying, progress UI, and session manifest architecture |
| **Share Extension UI** | Minimal | Just "Importing..." progress indicator for large files; no custom branding or folder picker |
| **Flutter Modal Actions** | Close button only | No "Import as Recipe", "Save as Clipping", etc. - those are Phase 2 |
| **Modal Style** | `WoltModalType.alertDialog()` | Matches existing clipping extraction modal pattern |

---

## 1. Approach Selection

### Options Considered

| Approach | Pros | Cons |
|----------|------|------|
| **share_handler** package | Active, minimal native code, handles App Group/deep linking | Less control over extension UI, limited customization |
| **share_intent_package** | Zero-config setup, newest | Black-box setup, less documentation |
| **Native Swift** (Recommended) | Full control, custom UI for large files, matches requirements exactly | More native code to maintain |

### Decision: Native Swift Approach

**Rationale:**

1. **File Copying Control**: Need to show native "Importing..." progress for large files before opening Flutter app. Third-party packages immediately dismiss the extension and open the app, which doesn't allow for progress indication during file copying.

2. **Session Manifest Architecture**: The requirement to normalize all content into a manifest + files in App Group before opening Flutter is not how existing packages work. They pass data directly via deep link parameters or shared preferences.

3. **UTType Flexibility**: Need to accept any UTType (url/text/image/movie/data). Native approach gives direct access to `NSItemProvider` APIs for type detection and loading.

4. **Memory Safety**: iOS extensions have ~50MB memory limit. Native Swift keeps the extension lightweight; embedding Flutter UI in extensions can exceed limits on physical devices.

5. **Future-Proofing**: Having native code gives flexibility to add custom share extension UI (e.g., "Save to Folder" picker) in future phases.

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ SHARE EXTENSION FLOW                                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  External App (Safari, Photos, etc.)                                         │
│        │                                                                     │
│        ▼                                                                     │
│  [Share Sheet] → User taps Stockpot                                          │
│        │                                                                     │
│        ▼                                                                     │
│  ┌────────────────────────────────────────────────┐                          │
│  │  ShareViewController (Native Swift)            │                          │
│  │                                                │                          │
│  │  1. Detect content types (UTType inspection)   │                          │
│  │  2. For small payloads: copy immediately       │                          │
│  │  3. For large payloads: show "Importing..."    │                          │
│  │  4. Write session manifest to App Group        │                          │
│  │  5. Copy files to App Group container          │                          │
│  │  6. Open app via URL scheme with sessionId     │                          │
│  └────────────────────────────────────────────────┘                          │
│        │                                                                     │
│        ▼                                                                     │
│  app.stockpot.app://share?sessionId=<UUID>                                   │
│        │                                                                     │
│        ▼                                                                     │
│  ┌────────────────────────────────────────────────┐                          │
│  │  Flutter App                                   │                          │
│  │                                                │                          │
│  │  1. Deep link listener receives sessionId      │                          │
│  │  2. Read manifest from App Group               │                          │
│  │  3. Show Wolt modal with share details         │                          │
│  │  4. (Future: Process/import shared content)    │                          │
│  └────────────────────────────────────────────────┘                          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Session Manifest Format

The share extension writes a JSON manifest to the App Group container. Flutter reads this manifest using the session ID.

### Manifest Location
```
App Group Container/
├── share_sessions/
│   ├── <sessionId>/
│   │   ├── manifest.json
│   │   ├── file_0.jpg       (optional)
│   │   ├── file_1.mp4       (optional)
│   │   └── ...
```

### Manifest Schema

```json
{
  "sessionId": "550e8400-e29b-41d4-a716-446655440000",
  "createdAt": "2025-12-20T10:30:00Z",
  "sourceApp": "com.apple.mobilesafari",
  "items": [
    {
      "type": "url",
      "url": "https://www.seriouseats.com/classic-apple-pie",
      "title": "Classic Apple Pie Recipe"
    },
    {
      "type": "text",
      "text": "This is the shared text content..."
    },
    {
      "type": "image",
      "fileName": "file_0.jpg",
      "originalFileName": "photo.jpg",
      "mimeType": "image/jpeg",
      "sizeBytes": 245678
    },
    {
      "type": "movie",
      "fileName": "file_1.mp4",
      "originalFileName": "video.mp4",
      "mimeType": "video/mp4",
      "sizeBytes": 15234567
    },
    {
      "type": "data",
      "fileName": "file_2.pdf",
      "originalFileName": "recipe.pdf",
      "mimeType": "application/pdf",
      "sizeBytes": 98765,
      "uniformTypeIdentifier": "com.adobe.pdf"
    }
  ]
}
```

### Item Types

| Type | Description | Key Fields |
|------|-------------|------------|
| `url` | Web URL | `url`, `title` (optional) |
| `text` | Plain text | `text` |
| `image` | Image file | `fileName`, `mimeType`, `sizeBytes` |
| `movie` | Video file | `fileName`, `mimeType`, `sizeBytes` |
| `data` | Generic file | `fileName`, `mimeType`, `sizeBytes`, `uniformTypeIdentifier` |

---

## 4. iOS Native Implementation

### 4.1 Xcode Configuration

#### New Target: ShareExtension
- **Type**: Share Extension
- **Name**: ShareExtension
- **Bundle Identifier**: `app.stockpot.app.ShareExtension`
- **Deployment Target**: iOS 14.0
- **Language**: Swift

#### Entitlements (Both Runner and ShareExtension)

```xml
<!-- Runner.entitlements - ADD to existing -->
<key>com.apple.security.application-groups</key>
<array>
    <string>group.app.stockpot.app</string>
</array>

<!-- ShareExtension.entitlements - NEW FILE -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.app.stockpot.app</string>
    </array>
</dict>
</plist>
```

#### ShareExtension Info.plist

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>NSExtensionActivationRule</key>
        <dict>
            <!-- Accept various content types -->
            <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
            <integer>1</integer>
            <key>NSExtensionActivationSupportsText</key>
            <true/>
            <key>NSExtensionActivationSupportsImageWithMaxCount</key>
            <integer>10</integer>
            <key>NSExtensionActivationSupportsMovieWithMaxCount</key>
            <integer>3</integer>
            <key>NSExtensionActivationSupportsFileWithMaxCount</key>
            <integer>10</integer>
        </dict>
    </dict>
    <key>NSExtensionMainStoryboard</key>
    <string>MainInterface</string>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.share-services</string>
</dict>
```

### 4.2 ShareViewController.swift

```swift
import UIKit
import Social
import UniformTypeIdentifiers
import MobileCoreServices

class ShareViewController: UIViewController {

    private let appGroupId = "group.app.stockpot.app"
    private let urlScheme = "app.stockpot.app"

    // UI elements for large file progress
    private var progressView: UIProgressView?
    private var statusLabel: UILabel?
    private var containerView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        processSharedItems()
    }

    // MARK: - Processing

    private func processSharedItems() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            completeWithError("No items to share")
            return
        }

        let sessionId = UUID().uuidString
        var manifestItems: [[String: Any]] = []
        let dispatchGroup = DispatchGroup()
        var hasLargeFiles = false
        var totalBytesToCopy: Int64 = 0

        // First pass: detect if we need progress UI
        for extensionItem in extensionItems {
            guard let attachments = extensionItem.attachments else { continue }

            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) ||
                   provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    // Estimate size - show progress for any media
                    hasLargeFiles = true
                }
            }
        }

        if hasLargeFiles {
            showProgressUI()
        }

        // Second pass: process items
        for extensionItem in extensionItems {
            guard let attachments = extensionItem.attachments else { continue }

            for (index, provider) in attachments.enumerated() {
                dispatchGroup.enter()

                processAttachment(
                    provider: provider,
                    sessionId: sessionId,
                    fileIndex: index
                ) { [weak self] item in
                    if let item = item {
                        manifestItems.append(item)
                    }
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            // Write manifest
            let manifest: [String: Any] = [
                "sessionId": sessionId,
                "createdAt": ISO8601DateFormatter().string(from: Date()),
                "sourceApp": self.sourceAppBundleId() ?? "unknown",
                "items": manifestItems
            ]

            if self.writeManifest(manifest, sessionId: sessionId) {
                self.openMainApp(sessionId: sessionId)
            } else {
                self.completeWithError("Failed to save shared content")
            }
        }
    }

    private func processAttachment(
        provider: NSItemProvider,
        sessionId: String,
        fileIndex: Int,
        completion: @escaping ([String: Any]?) -> Void
    ) {
        // Check for URL
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (data, error) in
                if let url = data as? URL {
                    completion([
                        "type": "url",
                        "url": url.absoluteString,
                        "title": provider.suggestedName ?? ""
                    ])
                } else {
                    completion(nil)
                }
            }
            return
        }

        // Check for plain text
        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (data, error) in
                if let text = data as? String {
                    completion([
                        "type": "text",
                        "text": text
                    ])
                } else {
                    completion(nil)
                }
            }
            return
        }

        // Check for image
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            copyFileToAppGroup(
                provider: provider,
                typeIdentifier: UTType.image.identifier,
                sessionId: sessionId,
                fileIndex: fileIndex,
                itemType: "image",
                completion: completion
            )
            return
        }

        // Check for movie
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            copyFileToAppGroup(
                provider: provider,
                typeIdentifier: UTType.movie.identifier,
                sessionId: sessionId,
                fileIndex: fileIndex,
                itemType: "movie",
                completion: completion
            )
            return
        }

        // Generic data/file
        if provider.hasItemConformingToTypeIdentifier(UTType.data.identifier) {
            copyFileToAppGroup(
                provider: provider,
                typeIdentifier: UTType.data.identifier,
                sessionId: sessionId,
                fileIndex: fileIndex,
                itemType: "data",
                completion: completion
            )
            return
        }

        completion(nil)
    }

    private func copyFileToAppGroup(
        provider: NSItemProvider,
        typeIdentifier: String,
        sessionId: String,
        fileIndex: Int,
        itemType: String,
        completion: @escaping ([String: Any]?) -> Void
    ) {
        provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] (url, error) in
            guard let self = self, let sourceUrl = url else {
                completion(nil)
                return
            }

            guard let containerUrl = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: self.appGroupId
            ) else {
                completion(nil)
                return
            }

            let sessionDir = containerUrl.appendingPathComponent("share_sessions/\(sessionId)")

            do {
                try FileManager.default.createDirectory(
                    at: sessionDir,
                    withIntermediateDirectories: true,
                    attributes: nil
                )

                let fileExtension = sourceUrl.pathExtension
                let fileName = "file_\(fileIndex).\(fileExtension)"
                let destUrl = sessionDir.appendingPathComponent(fileName)

                try FileManager.default.copyItem(at: sourceUrl, to: destUrl)

                let attributes = try FileManager.default.attributesOfItem(atPath: destUrl.path)
                let fileSize = attributes[.size] as? Int64 ?? 0

                let mimeType = UTType(filenameExtension: fileExtension)?.preferredMIMEType ?? "application/octet-stream"

                var item: [String: Any] = [
                    "type": itemType,
                    "fileName": fileName,
                    "originalFileName": sourceUrl.lastPathComponent,
                    "mimeType": mimeType,
                    "sizeBytes": fileSize
                ]

                if itemType == "data" {
                    item["uniformTypeIdentifier"] = typeIdentifier
                }

                DispatchQueue.main.async {
                    self.updateProgress(description: "Copied \(sourceUrl.lastPathComponent)")
                }

                completion(item)

            } catch {
                print("Error copying file: \(error)")
                completion(nil)
            }
        }
    }

    // MARK: - Manifest Writing

    private func writeManifest(_ manifest: [String: Any], sessionId: String) -> Bool {
        guard let containerUrl = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        ) else {
            return false
        }

        let manifestUrl = containerUrl
            .appendingPathComponent("share_sessions/\(sessionId)/manifest.json")

        do {
            let data = try JSONSerialization.data(withJSONObject: manifest, options: .prettyPrinted)
            try data.write(to: manifestUrl)
            return true
        } catch {
            print("Error writing manifest: \(error)")
            return false
        }
    }

    // MARK: - App Opening

    private func openMainApp(sessionId: String) {
        guard let url = URL(string: "\(urlScheme)://share?sessionId=\(sessionId)") else {
            completeWithError("Failed to create URL")
            return
        }

        // Use responder chain to open URL (extension limitation)
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                break
            }
            responder = responder?.next
        }

        // Alternative method for iOS 13+
        extensionContext?.completeRequest(returningItems: nil) { [weak self] _ in
            // Open URL after extension dismisses
            self?.openURL(url)
        }
    }

    @objc private func openURL(_ url: URL) {
        // Use selector-based approach for iOS extensions
        let selector = sel_registerName("openURL:")
        var responder: UIResponder? = self
        while responder != nil {
            if responder!.responds(to: selector) {
                responder!.perform(selector, with: url)
                break
            }
            responder = responder?.next
        }
    }

    // MARK: - Progress UI

    private func showProgressUI() {
        let container = UIView()
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = 16
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        let label = UILabel()
        label.text = "Importing..."
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.progress = 0
        container.addSubview(progress)

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(spinner)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 280),
            container.heightAnchor.constraint(equalToConstant: 120),

            spinner.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            spinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            progress.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            progress.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            progress.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])

        self.containerView = container
        self.statusLabel = label
        self.progressView = progress
    }

    private func updateProgress(description: String) {
        statusLabel?.text = description
    }

    // MARK: - Helpers

    private func sourceAppBundleId() -> String? {
        // Try to get source app bundle ID from extension context
        // This may not always be available
        return nil
    }

    private func completeWithError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.extensionContext?.cancelRequest(withError: NSError(
                domain: "ShareExtension",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: message]
            ))
        })
        present(alert, animated: true)
    }
}
```

### 4.3 MainInterface.storyboard

A minimal storyboard with just the view controller:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0">
    <scenes>
        <scene sceneID="main">
            <objects>
                <viewController id="ShareViewController"
                    customClass="ShareViewController"
                    customModule="ShareExtension"
                    sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="view">
                        <color key="backgroundColor" systemColor="systemBackgroundColor"/>
                    </view>
                </viewController>
            </objects>
        </scene>
    </scenes>
</document>
```

---

## 5. Flutter Implementation

### 5.1 Deep Link Handling

Update the existing deep link listener to handle share sessions.

**File:** `lib/src/services/share_session_service.dart` (NEW)

```dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/logging/app_logger.dart';

/// Model for a shared item in the session manifest
class ShareSessionItem {
  final String type; // url, text, image, movie, data
  final String? url;
  final String? title;
  final String? text;
  final String? fileName;
  final String? originalFileName;
  final String? mimeType;
  final int? sizeBytes;
  final String? uniformTypeIdentifier;

  ShareSessionItem({
    required this.type,
    this.url,
    this.title,
    this.text,
    this.fileName,
    this.originalFileName,
    this.mimeType,
    this.sizeBytes,
    this.uniformTypeIdentifier,
  });

  factory ShareSessionItem.fromJson(Map<String, dynamic> json) {
    return ShareSessionItem(
      type: json['type'] as String,
      url: json['url'] as String?,
      title: json['title'] as String?,
      text: json['text'] as String?,
      fileName: json['fileName'] as String?,
      originalFileName: json['originalFileName'] as String?,
      mimeType: json['mimeType'] as String?,
      sizeBytes: json['sizeBytes'] as int?,
      uniformTypeIdentifier: json['uniformTypeIdentifier'] as String?,
    );
  }

  bool get isUrl => type == 'url';
  bool get isText => type == 'text';
  bool get isImage => type == 'image';
  bool get isMovie => type == 'movie';
  bool get isData => type == 'data';
  bool get isFile => isImage || isMovie || isData;
}

/// Model for a complete share session
class ShareSession {
  final String sessionId;
  final DateTime createdAt;
  final String? sourceApp;
  final List<ShareSessionItem> items;
  final String sessionPath;

  ShareSession({
    required this.sessionId,
    required this.createdAt,
    this.sourceApp,
    required this.items,
    required this.sessionPath,
  });

  factory ShareSession.fromJson(Map<String, dynamic> json, String sessionPath) {
    return ShareSession(
      sessionId: json['sessionId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sourceApp: json['sourceApp'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((item) => ShareSessionItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      sessionPath: sessionPath,
    );
  }

  /// Get the full file path for a file item
  String getFilePath(ShareSessionItem item) {
    if (!item.isFile || item.fileName == null) {
      throw ArgumentError('Item is not a file or has no fileName');
    }
    return '$sessionPath/${item.fileName}';
  }

  /// Summary for display
  String get summary {
    final counts = <String, int>{};
    for (final item in items) {
      counts[item.type] = (counts[item.type] ?? 0) + 1;
    }
    return counts.entries.map((e) => '${e.value} ${e.key}(s)').join(', ');
  }
}

/// Service for reading share session data from App Group container
class ShareSessionService {
  static const String _appGroupId = 'group.app.stockpot.app';

  /// Read a share session by ID
  Future<ShareSession?> readSession(String sessionId) async {
    try {
      final containerPath = await _getAppGroupContainerPath();
      if (containerPath == null) {
        AppLogger.warning('App Group container not available');
        return null;
      }

      final sessionPath = '$containerPath/share_sessions/$sessionId';
      final manifestFile = File('$sessionPath/manifest.json');

      if (!await manifestFile.exists()) {
        AppLogger.warning('Session manifest not found: $sessionId');
        return null;
      }

      final jsonString = await manifestFile.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      return ShareSession.fromJson(json, sessionPath);
    } catch (e, stack) {
      AppLogger.error('Failed to read share session', e, stack);
      return null;
    }
  }

  /// Delete a session after processing (cleanup)
  Future<void> deleteSession(String sessionId) async {
    try {
      final containerPath = await _getAppGroupContainerPath();
      if (containerPath == null) return;

      final sessionDir = Directory('$containerPath/share_sessions/$sessionId');
      if (await sessionDir.exists()) {
        await sessionDir.delete(recursive: true);
        AppLogger.debug('Deleted share session: $sessionId');
      }
    } catch (e, stack) {
      AppLogger.error('Failed to delete share session', e, stack);
    }
  }

  /// Clean up old sessions (older than 1 hour)
  Future<void> cleanupOldSessions() async {
    try {
      final containerPath = await _getAppGroupContainerPath();
      if (containerPath == null) return;

      final sessionsDir = Directory('$containerPath/share_sessions');
      if (!await sessionsDir.exists()) return;

      final cutoff = DateTime.now().subtract(const Duration(hours: 1));

      await for (final entity in sessionsDir.list()) {
        if (entity is Directory) {
          final manifestFile = File('${entity.path}/manifest.json');
          if (await manifestFile.exists()) {
            final stat = await manifestFile.stat();
            if (stat.modified.isBefore(cutoff)) {
              await entity.delete(recursive: true);
              AppLogger.debug('Cleaned up old session: ${entity.path}');
            }
          }
        }
      }
    } catch (e, stack) {
      AppLogger.error('Failed to cleanup old sessions', e, stack);
    }
  }

  Future<String?> _getAppGroupContainerPath() async {
    if (!Platform.isIOS) return null;

    // On iOS, we need to access the App Group container
    // This requires using a method channel or plugin
    // For now, we'll use a known path pattern
    // In production, use a plugin like `shared_preference_app_group`

    // The App Group container path on iOS follows this pattern:
    // ~/Library/Group Containers/<app-group-id>/

    // We'll implement this via method channel in the next step
    return await _getAppGroupPath();
  }

  Future<String?> _getAppGroupPath() async {
    // This will be implemented via a platform channel
    // For now, return null and implement the channel
    return null;
  }
}

/// Provider for ShareSessionService
final shareSessionServiceProvider = Provider<ShareSessionService>((ref) {
  return ShareSessionService();
});

/// Provider for the current pending share session
final pendingShareSessionProvider = StateProvider<ShareSession?>((ref) => null);
```

### 5.2 Platform Channel for App Group Access

**File:** `lib/src/services/app_group_channel.dart` (NEW)

```dart
import 'package:flutter/services.dart';

class AppGroupChannel {
  static const _channel = MethodChannel('app.stockpot.app/app_group');

  /// Get the App Group container path
  static Future<String?> getContainerPath() async {
    try {
      final path = await _channel.invokeMethod<String>('getContainerPath');
      return path;
    } on PlatformException catch (e) {
      print('Failed to get App Group path: ${e.message}');
      return null;
    }
  }
}
```

**File:** `ios/Runner/AppDelegate.swift` (MODIFY)

Add method channel handler:

```swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: "app.stockpot.app/app_group",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { [weak self] (call, result) in
            if call.method == "getContainerPath" {
                let path = FileManager.default.containerURL(
                    forSecurityApplicationGroupIdentifier: "group.app.stockpot.app"
                )?.path
                result(path)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

### 5.3 Share Session Modal

**File:** `lib/src/features/share/views/share_session_modal.dart` (NEW)

```dart
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../services/logging/app_logger.dart';
import '../../../services/share_session_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_circle_button.dart';

/// Shows the share session modal to display shared content details
Future<void> showShareSessionModal(
  BuildContext context,
  WidgetRef ref, {
  required String sessionId,
}) async {
  AppLogger.info('Opening share session modal: $sessionId');

  final service = ref.read(shareSessionServiceProvider);
  final session = await service.readSession(sessionId);

  if (session == null) {
    AppLogger.warning('Share session not found: $sessionId');
    if (context.mounted) {
      _showErrorDialog(context, 'Could not load shared content.');
    }
    return;
  }

  // Store session for potential later use
  ref.read(pendingShareSessionProvider.notifier).state = session;

  if (!context.mounted) return;

  WoltModalSheet.show<void>(
    context: context,
    useRootNavigator: true,
    modalTypeBuilder: (_) => WoltModalType.alertDialog(),
    pageListBuilder: (modalContext) => [
      WoltModalSheetPage(
        navBarHeight: 55,
        backgroundColor: AppColors.of(modalContext).background,
        surfaceTintColor: Colors.transparent,
        hasTopBarLayer: false,
        isTopBarLayerAlwaysVisible: false,
        trailingNavBarWidget: Padding(
          padding: EdgeInsets.only(right: AppSpacing.lg),
          child: AppCircleButton(
            icon: AppCircleButtonIcon.close,
            variant: AppCircleButtonVariant.neutral,
            onPressed: () {
              // Clean up session on close
              service.deleteSession(sessionId);
              ref.read(pendingShareSessionProvider.notifier).state = null;
              Navigator.of(modalContext, rootNavigator: true).pop();
            },
          ),
        ),
        child: _ShareSessionContent(session: session),
      ),
    ],
  );
}

class _ShareSessionContent extends StatelessWidget {
  final ShareSession session;

  const _ShareSessionContent({required this.session});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Shared Content',
            style: AppTypography.h4.copyWith(
              color: AppColors.of(context).textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Session: ${session.sessionId.substring(0, 8)}...',
            style: AppTypography.caption.copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Summary
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.of(context).surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Summary',
                  style: AppTypography.label.copyWith(
                    color: AppColors.of(context).textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  session.summary,
                  style: AppTypography.body.copyWith(
                    color: AppColors.of(context).textSecondary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: AppSpacing.lg),

          // Items list
          Text(
            'Items (${session.items.length})',
            style: AppTypography.label.copyWith(
              color: AppColors.of(context).textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),

          ...session.items.map((item) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ShareItemTile(item: item, session: session),
          )),

          SizedBox(height: AppSpacing.lg),

          // Debug info
          Text(
            'Debug Info',
            style: AppTypography.label.copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Created: ${session.createdAt.toLocal()}',
            style: AppTypography.caption.copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
          if (session.sourceApp != null)
            Text(
              'Source: ${session.sourceApp}',
              style: AppTypography.caption.copyWith(
                color: AppColors.of(context).textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _ShareItemTile extends StatelessWidget {
  final ShareSessionItem item;
  final ShareSession session;

  const _ShareItemTile({
    required this.item,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.of(context).border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildIcon(context),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(),
                  style: AppTypography.body.copyWith(
                    color: AppColors.of(context).textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_getSubtitle() != null)
                  Text(
                    _getSubtitle()!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.of(context).textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    IconData iconData;
    Color iconColor;

    switch (item.type) {
      case 'url':
        iconData = CupertinoIcons.link;
        iconColor = CupertinoColors.systemBlue;
        break;
      case 'text':
        iconData = CupertinoIcons.doc_text;
        iconColor = CupertinoColors.systemGreen;
        break;
      case 'image':
        iconData = CupertinoIcons.photo;
        iconColor = CupertinoColors.systemPurple;
        break;
      case 'movie':
        iconData = CupertinoIcons.videocam;
        iconColor = CupertinoColors.systemRed;
        break;
      default:
        iconData = CupertinoIcons.doc;
        iconColor = CupertinoColors.systemGray;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  String _getTitle() {
    if (item.isUrl) {
      return item.title?.isNotEmpty == true ? item.title! : item.url ?? 'URL';
    }
    if (item.isText) {
      final text = item.text ?? '';
      return text.length > 100 ? '${text.substring(0, 100)}...' : text;
    }
    if (item.isFile) {
      return item.originalFileName ?? item.fileName ?? 'File';
    }
    return item.type;
  }

  String? _getSubtitle() {
    if (item.isUrl) {
      return item.url;
    }
    if (item.isFile && item.sizeBytes != null) {
      return '${item.mimeType ?? item.type} - ${_formatBytes(item.sizeBytes!)}';
    }
    return null;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

void _showErrorDialog(BuildContext context, String message) {
  showCupertinoDialog(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: const Text('Error'),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('OK'),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ],
    ),
  );
}
```

### 5.4 Deep Link Handler Update

**File:** Update `lib/src/services/auth_service.dart` or create new handler

Add share session handling to the deep link listener:

```dart
// In the deep link handling code, add:

void _handleDeepLink(Uri uri) {
  if (uri.path == '/share' || uri.host == 'share') {
    final sessionId = uri.queryParameters['sessionId'];
    if (sessionId != null) {
      _handleShareSession(sessionId);
    }
  }
  // ... existing auth handling
}

void _handleShareSession(String sessionId) {
  // Get the current context and show the modal
  // This may require navigating to the app first if in background
  AppLogger.info('Received share session: $sessionId');

  // Store the session ID for processing when app is ready
  // The app's main widget will check for pending sessions on startup
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      final container = ProviderScope.containerOf(context);
      final ref = container;
      showShareSessionModal(context, ref, sessionId: sessionId);
    }
  });
}
```

---

## 6. Implementation Checklist

### Phase 1: iOS Setup

- [ ] **Xcode Configuration**
  - [ ] Create ShareExtension target
  - [ ] Set bundle ID: `app.stockpot.app.ShareExtension`
  - [ ] Set deployment target: iOS 14.0
  - [ ] Add App Groups entitlement to Runner
  - [ ] Add App Groups entitlement to ShareExtension
  - [ ] Configure ShareExtension Info.plist with NSExtension keys

- [ ] **Native Swift Code**
  - [ ] Create ShareViewController.swift
  - [ ] Create MainInterface.storyboard
  - [ ] Implement content type detection
  - [ ] Implement file copying to App Group
  - [ ] Implement manifest writing
  - [ ] Implement progress UI for large files
  - [ ] Implement URL scheme opening

- [ ] **Method Channel**
  - [ ] Add App Group path method channel to AppDelegate.swift

### Phase 2: Flutter Implementation

- [ ] **Services**
  - [ ] Create ShareSessionService
  - [ ] Create AppGroupChannel
  - [ ] Create ShareSession and ShareSessionItem models

- [ ] **UI**
  - [ ] Create ShareSessionModal
  - [ ] Create _ShareSessionContent widget
  - [ ] Create _ShareItemTile widget

- [ ] **Deep Linking**
  - [ ] Update deep link handler to recognize `/share` path
  - [ ] Handle share session ID from URL
  - [ ] Show modal when app opens with share session

### Phase 3: Testing

- [ ] Test sharing URL from Safari
- [ ] Test sharing text from Notes
- [ ] Test sharing image from Photos
- [ ] Test sharing video from Photos
- [ ] Test sharing PDF from Files
- [ ] Test sharing multiple items
- [ ] Test large file progress UI
- [ ] Test session cleanup

---

## 7. Future Enhancements (Phase 2+)

### Phase 2: Import Actions
- **Modal Action Buttons**: Add "Import as Recipe", "Save as Clipping", "Add to Shopping List" buttons
- **URL Fetching**: Fetch and parse recipe content from shared URLs
- **Text Extraction**: Process shared text to extract recipe data
- **Image Import**: Save shared images as recipe photos

### Phase 3+: Advanced Features
- **Custom Share Extension UI**: Add folder picker in extension for direct-to-folder saving
- **Background Processing**: Queue shared items for processing when app is closed
- **Recipe Detection**: Auto-detect recipe content from shared URLs/text
- **Image OCR**: Extract recipe text from shared images
- **Batch Import**: Handle multiple recipes in one share action

---

## 8. Key Files Summary

### New iOS Files
| File | Purpose |
|------|---------|
| `ios/ShareExtension/ShareViewController.swift` | Main extension logic |
| `ios/ShareExtension/MainInterface.storyboard` | Extension UI |
| `ios/ShareExtension/Info.plist` | Extension configuration |
| `ios/ShareExtension/ShareExtension.entitlements` | Extension entitlements |

### Modified iOS Files
| File | Change |
|------|--------|
| `ios/Runner/Runner.entitlements` | Add App Groups |
| `ios/Runner/AppDelegate.swift` | Add method channel |
| `ios/Runner.xcodeproj/project.pbxproj` | New target configuration |

### New Dart Files
| File | Purpose |
|------|---------|
| `lib/src/services/share_session_service.dart` | Session reading/cleanup |
| `lib/src/services/app_group_channel.dart` | Platform channel for App Group |
| `lib/src/features/share/views/share_session_modal.dart` | Wolt modal UI |

### Modified Dart Files
| File | Change |
|------|--------|
| `lib/src/services/auth_service.dart` | Add share deep link handling |

---

## 9. Security Considerations

1. **Session Expiry**: Sessions are cleaned up after 1 hour to prevent stale data accumulation
2. **Path Validation**: File paths are validated to prevent directory traversal attacks
3. **Size Limits**: Extension checks file sizes before copying to prevent storage abuse
4. **No Sensitive Data**: Session manifests don't contain sensitive user data
5. **App Group Isolation**: Data is isolated within the app group, not accessible to other apps