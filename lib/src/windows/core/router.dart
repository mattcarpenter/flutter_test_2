import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_view.dart';
import '../layout/shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  routes: [
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) {
        return Shell(
          shellContext: context,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeView(),
        ),
      ],
    ),
  ],
);
