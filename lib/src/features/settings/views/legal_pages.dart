import 'package:flutter/widgets.dart';

import 'web_view_page.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebViewPage(
      title: 'Privacy Policy',
      url: 'https://www.stockpot.app/privacy-policy',
    );
  }
}

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebViewPage(
      title: 'Terms of Use',
      url: 'https://www.stockpot.app/terms-of-use',
    );
  }
}
