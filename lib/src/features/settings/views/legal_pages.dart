import 'package:flutter/widgets.dart';

import '../../../localization/l10n_extension.dart';
import 'web_view_page.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WebViewPage(
      title: context.l10n.settingsPrivacyPolicy,
      url: 'https://www.stockpot.app/privacy-policy',
      previousPageTitle: context.l10n.settingsTitle,
    );
  }
}

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return WebViewPage(
      title: context.l10n.settingsTermsOfUse,
      url: 'https://www.stockpot.app/terms-of-use',
      previousPageTitle: context.l10n.settingsTitle,
    );
  }
}
