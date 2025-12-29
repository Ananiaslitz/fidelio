import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/verify_otp_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/verify-otp',
      builder: (context, state) {
        final phone = state.extra as String;
        return VerifyOTPScreen(phone: phone);
      },
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        // Add other authenticated routes here
      ],
    ),
  ],
);

