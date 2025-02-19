import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sheet/route.dart';
import 'package:sheet/sheet.dart';

bool isTablet(BuildContext context) {
  return MediaQuery.of(context).size.shortestSide >= 600;
}

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



    if (isTablet(context)) {
      return DialogPage(builder: (context) => child);
    }
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

class DialogPage<T> extends Page<T> {
  final Offset? anchorPoint;
  final Color? barrierColor;
  final bool barrierDismissible;
  final String? barrierLabel;
  final bool useSafeArea;
  final CapturedThemes? themes;
  final WidgetBuilder builder;

  const DialogPage({
    required this.builder,
    this.anchorPoint,
    this.barrierColor = Colors.black26,
    this.barrierDismissible = true,
    this.barrierLabel,
    this.useSafeArea = true,
    this.themes,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) => DialogRoute<T>(
    context: context,
    settings: this,
    builder: (context) => Dialog(
      child: builder(context),
    ),
    anchorPoint: anchorPoint,
    barrierColor: barrierColor,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    useSafeArea: useSafeArea,
    themes: themes,
  );
}

