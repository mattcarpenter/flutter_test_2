import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  Widget build(BuildContext context) {
    final helpTopicsAsync = ref.watch(helpTopicsProvider);

    return AdaptiveSliverPage(
      title: 'Help',
      automaticallyImplyLeading: true,
      previousPageTitle: 'Settings',
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
              child: Text('Failed to load help topics: $error'),
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
      header: section.name,
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
