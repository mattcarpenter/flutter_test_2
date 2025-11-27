import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../services/logging/log_export_service.dart';
import '../../../services/logging/app_logger.dart';
import '../widgets/settings_group_condensed.dart';
import '../widgets/settings_row_condensed.dart';

/// Provider to get the formatted log file size.
final _logFileSizeProvider = FutureProvider<String>((ref) async {
  return LogExportService.getLogFileSizeFormatted();
});

class SupportPage extends ConsumerWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final logSizeAsync = ref.watch(_logFileSizeProvider);

    return AdaptiveSliverPage(
      title: 'Support',
      automaticallyImplyLeading: true,
      previousPageTitle: 'Settings',
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.xl),

              // Logs section
              SettingsGroupCondensed(
                header: 'Diagnostics',
                children: [
                  SettingsRowCondensed(
                    title: 'Export Logs',
                    value: logSizeAsync.when(
                      data: (size) => size,
                      loading: () => '...',
                      error: (_, __) => 'Error',
                    ),
                    leading: Icon(
                      CupertinoIcons.doc_text,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () => _exportLogs(context, ref),
                  ),
                  SettingsRowCondensed(
                    title: 'Clear Logs',
                    leading: Icon(
                      CupertinoIcons.trash,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () => _clearLogs(context, ref),
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.settingsGroupGap),

              // Contact section
              SettingsGroupCondensed(
                header: 'Contact',
                children: [
                  SettingsRowCondensed(
                    title: 'Email Support',
                    leading: Icon(
                      CupertinoIcons.mail,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () => _openEmailSupport(context),
                  ),
                ],
              ),

              // Bottom spacing
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _exportLogs(BuildContext context, WidgetRef ref) async {
    AppLogger.info('Exporting logs');

    // Get the position for iPad/macOS share popover
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    final result = await LogExportService.shareLogs(
      sharePositionOrigin: sharePositionOrigin,
    );

    // Only show alert if no logs exist (null), not if user dismissed (false)
    if (result == null && context.mounted) {
      _showAlert(
        context,
        title: 'No Logs Available',
        message: 'There are no logs to export yet.',
      );
    }
  }

  Future<void> _clearLogs(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Clear Logs?',
      message: 'This will delete all diagnostic logs. This action cannot be undone.',
      confirmLabel: 'Clear',
      isDestructive: true,
    );

    if (confirmed == true) {
      final success = await LogExportService.clearLogs();

      // Refresh the file size
      ref.invalidate(_logFileSizeProvider);

      if (context.mounted) {
        _showAlert(
          context,
          title: success ? 'Logs Cleared' : 'Error',
          message: success
              ? 'All diagnostic logs have been deleted.'
              : 'Failed to clear logs. Please try again.',
        );
      }
    }
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _showAlert(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEmailSupport(BuildContext context) async {
    try {
      // Gather device and app info
      final packageInfo = await PackageInfo.fromPlatform();
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'Not signed in';

      final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      final platform = Platform.operatingSystem;
      final osVersion = Platform.operatingSystemVersion;

      final body = '''


---
Please describe your issue above this line
---
User ID: $userId
App Version: $appVersion
Platform: $platform
OS Version: $osVersion
''';

      final uri = Uri(
        scheme: 'mailto',
        path: 'support@stockpot.app',
        query: _encodeQueryParameters({
          'subject': 'Stockpot Support Request',
          'body': body,
        }),
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          _showAlert(
            context,
            title: 'Unable to Open Email',
            message: 'Please email us at support@stockpot.app',
          );
        }
      }
    } catch (e) {
      AppLogger.error('Failed to open email client', e);
      if (context.mounted) {
        _showAlert(
          context,
          title: 'Error',
          message: 'Unable to open email client. Please email us at support@stockpot.app',
        );
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
