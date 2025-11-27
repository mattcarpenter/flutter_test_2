import 'package:flutter/cupertino.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../theme/colors.dart';

/// A simple webview page for displaying web content like Terms of Service, Privacy Policy, etc.
/// No navigation chrome - just the content with a back button in the nav bar.
class WebViewPage extends StatefulWidget {
  final String title;
  final String url;
  final String previousPageTitle;

  const WebViewPage({
    super.key,
    required this.title,
    required this.url,
    this.previousPageTitle = 'Settings',
  });

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  bool _isLoading = true;
  late final String _initialHost;

  @override
  void initState() {
    super.initState();
    _initialHost = Uri.parse(widget.url).host;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
        previousPageTitle: widget.previousPageTitle,
        backgroundColor: colors.background,
      ),
      child: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                transparentBackground: true,
              ),
              onLoadStart: (controller, url) {
                if (mounted) setState(() => _isLoading = true);
              },
              onLoadStop: (controller, url) {
                if (mounted) setState(() => _isLoading = false);
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final url = navigationAction.request.url;
                if (url == null) return NavigationActionPolicy.CANCEL;

                final requestHost = url.host;
                // Allow navigation within the same domain
                if (requestHost == _initialHost || requestHost.endsWith('.$_initialHost')) {
                  return NavigationActionPolicy.ALLOW;
                }
                // Block external links
                return NavigationActionPolicy.CANCEL;
              },
            ),
            if (_isLoading)
              Container(
                color: colors.background,
                child: const Center(
                  child: CupertinoActivityIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
