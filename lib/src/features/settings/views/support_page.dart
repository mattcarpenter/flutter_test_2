import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../localization/l10n_extension.dart';
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
      title: context.l10n.settingsSupport,
      automaticallyImplyLeading: true,
      previousPageTitle: context.l10n.settingsTitle,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.xl),

              // Logs section
              SettingsGroupCondensed(
                header: context.l10n.settingsSupportDiagnostics,
                children: [
                  SettingsRowCondensed(
                    title: context.l10n.settingsSupportExportLogs,
                    value: logSizeAsync.when(
                      data: (size) => size,
                      loading: () => context.l10n.commonLoading,
                      error: (_, __) => context.l10n.commonError,
                    ),
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedFile01,
                      size: 22,
                      color: colors.primary,
                    ),
                    onTap: () => _exportLogs(context, ref),
                  ),
                  SettingsRowCondensed(
                    title: context.l10n.settingsSupportClearLogs,
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedDelete02,
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
                header: context.l10n.settingsSupportContact,
                children: [
                  SettingsRowCondensed(
                    title: context.l10n.settingsSupportEmailSupport,
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedMail01,
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
        title: context.l10n.settingsSupportNoLogs,
        message: context.l10n.settingsSupportNoLogsMessage,
      );
    }
  }

  Future<void> _clearLogs(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: context.l10n.settingsSupportClearLogsTitle,
      message: context.l10n.settingsSupportClearLogsMessage,
      confirmLabel: context.l10n.commonClear,
      isDestructive: true,
    );

    if (confirmed == true) {
      final success = await LogExportService.clearLogs();

      // Refresh the file size
      ref.invalidate(_logFileSizeProvider);

      if (context.mounted) {
        _showAlert(
          context,
          title: success ? context.l10n.settingsSupportLogsCleared : context.l10n.commonError,
          message: success
              ? context.l10n.settingsSupportLogsClearedMessage
              : context.l10n.settingsSupportLogsClearFailed,
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
            child: Text(context.l10n.commonCancel),
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
            child: Text(context.l10n.commonOk),
          ),
        ],
      ),
    );
  }

  Future<void> _openEmailSupport(BuildContext context) async {
    try {
      // Gather device and app info
      final packageInfo = await PackageInfo.fromPlatform();
      final userId = Supabase.instance.client.auth.currentUser?.id ?? context.l10n.settingsSupportNotSignedIn;

      final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      final platform = Platform.operatingSystem;
      final osVersion = Platform.operatingSystemVersion;

      final body = context.l10n.settingsSupportEmailBody(userId, appVersion, platform, osVersion);

      final uri = Uri(
        scheme: 'mailto',
        path: 'support@stockpot.app',
        query: _encodeQueryParameters({
          'subject': context.l10n.settingsSupportEmailSubject,
          'body': body,
        }),
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          _showAlert(
            context,
            title: context.l10n.settingsSupportEmailError,
            message: context.l10n.settingsSupportEmailErrorMessage,
          );
        }
      }
    } catch (e) {
      AppLogger.error('Failed to open email client', e);
      if (context.mounted) {
        _showAlert(
          context,
          title: context.l10n.commonError,
          message: context.l10n.settingsSupportEmailErrorMessage,
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
