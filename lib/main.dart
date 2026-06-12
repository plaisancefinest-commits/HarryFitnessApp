import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/workout_provider.dart';
import 'screens/home_screen.dart';

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
      ],
      child: MaterialApp(
        title: 'Harry Fitness',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const HomeScreen(),
      ),
    );
  }

  ThemeData _buildTheme() {
    const neutral100 = Color(0xFFF7F5F2);
    const neutral200 = Color(0xFFEDEAE5);
    const neutral800 = Color(0xFF2C2C2C);
    const accent = Color(0xFF1A1A1A);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: neutral100,
      colorScheme: const ColorScheme.light(
        surface: neutral100,
        onSurface: neutral800,
        primary: accent,
        onPrimary: Colors.white,
        secondary: neutral200,
        onSecondary: neutral800,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: neutral800,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: neutral800,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: neutral800,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF6B6B6B),
          height: 1.5,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF9E9E9E),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
