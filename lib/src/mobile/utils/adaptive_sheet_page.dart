import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sheet/route.dart';
import 'package:sheet/sheet.dart';

Page<T> buildAdaptiveSheetPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  bool maintainState = true,
  double initialExtent = 1,
  List<double>? stops,
  bool draggable = true,
  SheetFit fit = SheetFit.expand,
  SheetPhysics? physics,
  Curve? animationCurve,
  Duration? duration,
  String? sheetLabel,
  String? barrierLabel,
  Color? barrierColor,
  bool barrierDismissible = true,
  double willPopThreshold = 0.5,
  Widget Function(BuildContext, Widget)? decorationBuilder,
}) {
  if (Platform.isIOS) {
    return CupertinoSheetPage<T>(
      child: child,
      maintainState: maintainState,
    );
  } else {
    return SheetPage<T>(
      child: Container(
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        child: child,
      ),
      fit: fit,
      animationCurve: Curves.easeOutExpo,
    );
  }
}
