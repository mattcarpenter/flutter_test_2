import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../localization/l10n_extension.dart';
import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/spacing.dart';
import '../../settings/widgets/settings_group_condensed.dart';
import '../models/help_topic.dart';
import '../providers/help_topics_provider.dart';
import '../widgets/help_topic_accordion.dart';

class HelpPage extends ConsumerStatefulWidget {
  const HelpPage({super.key});

  @override
  ConsumerState<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends ConsumerState<HelpPage> {
  /// Track which topic is currently expanded (by file path for uniqueness).
  /// Null means none are expanded.
  String? _expandedTopicPath;

  void _handleToggle(String topicPath) {
    setState(() {
      if (_expandedTopicPath == topicPath) {
        // Collapse if already expanded
        _expandedTopicPath = null;
      } else {
        // Expand this one, collapse any other
        _expandedTopicPath = topicPath;
      }
    });
  }

  /// Get localized section name from folder key
  String _getSectionName(BuildContext context, String folderKey) {
    return switch (folderKey) {
      'adding-recipes' => context.l10n.helpSectionAddingRecipes,
      'quick-questions' => context.l10n.helpSectionQuickQuestions,
      'learn-more' => context.l10n.helpSectionLearnMore,
      'troubleshooting' => context.l10n.helpSectionTroubleshooting,
      _ => folderKey,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Get current locale code
    final localeCode = Localizations.localeOf(context).languageCode;
    final helpTopicsAsync = ref.watch(helpTopicsProvider(localeCode));

    return AdaptiveSliverPage(
      title: context.l10n.helpTitle,
      automaticallyImplyLeading: true,
      previousPageTitle: context.l10n.settingsTitle,
      slivers: [
        helpTopicsAsync.when(
          data: (sections) => SliverToBoxAdapter(
            child: _buildContent(context, sections),
          ),
          loading: () => const SliverFillRemaining(
            child: Center(
              child: CupertinoActivityIndicator(),
            ),
          ),
          error: (error, stack) => SliverFillRemaining(
            child: Center(
              child: Text('${context.l10n.helpLoadError}: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, List<HelpSection> sections) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: AppSpacing.xl),

        // Render each section
        for (final section in sections) ...[
          _buildSection(context, section),
          SizedBox(height: AppSpacing.settingsGroupGap),
        ],

        // Bottom spacing
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSection(BuildContext context, HelpSection section) {
    if (section.topics.isEmpty) {
      return const SizedBox.shrink();
    }

    return SettingsGroupCondensed(
      header: _getSectionName(context, section.folderKey),
      children: [
        for (final topic in section.topics)
          HelpTopicAccordion(
            topic: topic,
            isExpanded: _expandedTopicPath == topic.filePath,
            onToggle: () => _handleToggle(topic.filePath),
          ),
      ],
    );
  }
}
