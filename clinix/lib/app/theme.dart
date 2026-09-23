import 'package:flutter/material.dart';

class ClinixTheme {
  static const primary = Color(0xFF147DE5);
  static const background = Color(0xFFF7F9FC);
  static const textPrimary = Color(0xFF152A5B);
  static const textSecondary = Color(0xFF667494);

  static final lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
  );
}