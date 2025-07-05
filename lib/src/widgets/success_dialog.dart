import 'package:flutter/cupertino.dart';

class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  
  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
  });
  
  static Future<void> show(
    BuildContext context, {
    String title = 'Success',
    required String message,
  }) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => SuccessDialog(
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
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}