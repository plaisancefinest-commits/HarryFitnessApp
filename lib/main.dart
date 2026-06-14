import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/theme_provider.dart';
import 'providers/workout_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_colors.dart';

void main() {
  // sqflite only ships native bindings for iOS/Android; on desktop we
  // swap in the FFI implementation so the database works everywhere.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const HarryFitnessApp());
}

class HarryFitnessApp extends StatelessWidget {
  const HarryFitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'Harry Fitness',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(themeProvider.palette),
          home: const HomeScreen(),
        ),
      ),
    );
  }

  static bool _isDark(AppColors c) =>
      ThemeData.estimateBrightnessForColor(c.bg) == Brightness.dark;

  ThemeData _buildTheme(AppColors c) {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: c.bg,
      extensions: [c],
      colorScheme: _isDark(c)
          ? ColorScheme.dark(
              surface: c.bg,
              onSurface: c.ink,
              primary: c.accent,
              onPrimary: c.onAccent,
              secondary: c.fill,
              onSecondary: c.ink,
            )
          : ColorScheme.light(
              surface: c.bg,
              onSurface: c.ink,
              primary: c.accent,
              onPrimary: c.onAccent,
              secondary: c.fill,
              onSecondary: c.ink,
            ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: c.cardOutline == Colors.transparent
              ? BorderSide.none
              : BorderSide(color: c.cardOutline, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: c.cardOutline == Colors.transparent
              ? BorderSide.none
              : BorderSide(color: c.cardOutline, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.ink),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.ink,
        selectionColor: c.fillDeep,
        selectionHandleColor: c.ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: c.muted),
        suffixStyle: TextStyle(color: c.muted),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: c.borderStrong),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: c.ink),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textTheme: TextTheme(
        displaySmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: c.ink,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: c.ink,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: c.ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: c.muted,
          height: 1.5,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: c.faint,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
