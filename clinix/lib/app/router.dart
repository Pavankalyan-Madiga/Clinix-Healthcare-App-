import 'package:clinix/features/conflicts/conflicts_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:clinix/features/auth/presentation/login_page.dart';
import 'package:clinix/features/auth/presentation/profile_page.dart';
import 'package:clinix/features/home/presentation/home_page.dart';
import 'package:clinix/features/more/presentation/settings_page.dart';
import 'package:clinix/features/more/presentation/about_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),

    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),

    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),

    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),

    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutPage(),
    ),

    GoRoute(
      path: '/conflicts',
      builder: (context, state) => const ConflictsPage(),
    ),
  ],

  errorBuilder: (context, state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Text(
          'No page found for ${state.uri}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  },
);