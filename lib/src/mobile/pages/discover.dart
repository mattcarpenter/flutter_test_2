import 'package:flutter/cupertino.dart';

class DiscoverPage extends StatelessWidget {
  final String title;
  final bool enableTitleTransition;

  const DiscoverPage({super.key, required this.title, this.enableTitleTransition = false});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
      ),
      child: Center(
        child: Text(
          'Hello, $title!',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
