import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CupertinoApp(
    home: CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Test Title'),
        border: Border(
          bottom: BorderSide(
            color: Colors.red,
            width: 2.0,
          ),
        ),
      ),
      child: Center(
        child: Text('Hello, World!'),
      ),
    ),
  ));
}
