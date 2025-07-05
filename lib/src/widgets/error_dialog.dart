import 'package:flutter/cupertino.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  
  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
  });
  
  static Future<void> show(
    BuildContext context, {
    String title = 'Error',
    required String message,
  }) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(message),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}