import 'package:flutter/cupertino.dart';

class RecipesPage extends StatelessWidget {
  final String title;

  const RecipesPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
        'Hello, $title!',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      );
  }
}
