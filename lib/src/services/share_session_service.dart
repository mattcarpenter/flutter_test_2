import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_group_channel.dart';
import 'logging/app_logger.dart';

/// Model for a shared item within a share session
class ShareSessionItem {
  final String type;
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

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (url != null) 'url': url,
      if (title != null) 'title': title,
      if (text != null) 'text': text,
      if (fileName != null) 'fileName': fileName,
      if (originalFileName != null) 'originalFileName': originalFileName,
      if (mimeType != null) 'mimeType': mimeType,
      if (sizeBytes != null) 'sizeBytes': sizeBytes,
      if (uniformTypeIdentifier != null) 'uniformTypeIdentifier': uniformTypeIdentifier,
    };
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

  factory ShareSession.fromJson(
    Map<String, dynamic> json,
    String sessionPath,
  ) {
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

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'createdAt': createdAt.toIso8601String(),
      if (sourceApp != null) 'sourceApp': sourceApp,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  bool get hasUrls => items.any((item) => item.isUrl);
  bool get hasText => items.any((item) => item.isText);
  bool get hasImages => items.any((item) => item.isImage);
  bool get hasFiles => items.any((item) => item.isFile);
}

/// Service for reading and managing share sessions from the App Group container
class ShareSessionService {
  final String containerPath;

  ShareSessionService(this.containerPath);

  String get _sessionsPath => '$containerPath/share_sessions';

  /// Read a share session by ID
  Future<ShareSession?> readSession(String sessionId) async {
    try {
      final sessionPath = '$_sessionsPath/$sessionId';
      final sessionFile = File('$sessionPath/manifest.json');

      if (!await sessionFile.exists()) {
        AppLogger.warning('Share session not found: $sessionId');
        return null;
      }

      final jsonString = await sessionFile.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      final session = ShareSession.fromJson(json, sessionPath);
      AppLogger.info('Read share session: $sessionId with ${session.items.length} items');

      return session;
    } catch (e, stack) {
      AppLogger.error('Failed to read share session: $sessionId', e, stack);
      return null;
    }
  }

  /// Delete a share session and all its files
  Future<void> deleteSession(String sessionId) async {
    try {
      final sessionPath = '$_sessionsPath/$sessionId';
      final sessionDir = Directory(sessionPath);

      if (await sessionDir.exists()) {
        await sessionDir.delete(recursive: true);
        AppLogger.info('Deleted share session: $sessionId');
      }
    } catch (e, stack) {
      AppLogger.error('Failed to delete share session: $sessionId', e, stack);
    }
  }

  /// Clean up old share sessions (older than 24 hours)
  Future<void> cleanupOldSessions() async {
    try {
      final sessionsDir = Directory(_sessionsPath);

      if (!await sessionsDir.exists()) {
        return;
      }

      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(hours: 24));

      await for (final entity in sessionsDir.list()) {
        if (entity is Directory) {
          final sessionFile = File('${entity.path}/session.json');

          if (await sessionFile.exists()) {
            final stat = await sessionFile.stat();
            if (stat.modified.isBefore(cutoff)) {
              await entity.delete(recursive: true);
              AppLogger.debug('Cleaned up old session: ${entity.path}');
            }
          }
        }
      }

      AppLogger.info('Completed share session cleanup');
    } catch (e, stack) {
      AppLogger.error('Failed to cleanup old share sessions', e, stack);
    }
  }

  /// Get all available session IDs
  Future<List<String>> getAvailableSessions() async {
    try {
      final sessionsDir = Directory(_sessionsPath);

      if (!await sessionsDir.exists()) {
        return [];
      }

      final sessionIds = <String>[];

      await for (final entity in sessionsDir.list()) {
        if (entity is Directory) {
          final sessionFile = File('${entity.path}/session.json');
          if (await sessionFile.exists()) {
            sessionIds.add(entity.path.split('/').last);
          }
        }
      }

      return sessionIds;
    } catch (e, stack) {
      AppLogger.error('Failed to get available sessions', e, stack);
      return [];
    }
  }
}

/// Provider for ShareSessionService
final shareSessionServiceProvider = FutureProvider<ShareSessionService>((ref) async {
  final containerPath = await AppGroupChannel.getContainerPath();

  if (containerPath == null) {
    throw Exception('Unable to access App Group container');
  }

  final service = ShareSessionService(containerPath);

  // Clean up old sessions on service initialization
  await service.cleanupOldSessions();

  return service;
});

/// Provider for checking if there's a pending share session
final pendingShareSessionProvider = FutureProvider<String?>((ref) async {
  try {
    final service = await ref.watch(shareSessionServiceProvider.future);
    final sessions = await service.getAvailableSessions();

    if (sessions.isEmpty) {
      return null;
    }

    // Return the most recent session (assuming sessions are sorted by creation time)
    // In a real implementation, you might want to sort by timestamp
    return sessions.first;
  } catch (e, stack) {
    AppLogger.error('Failed to check for pending share session', e, stack);
    return null;
  }
});
