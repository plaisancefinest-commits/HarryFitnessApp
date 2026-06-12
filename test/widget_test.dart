import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harry_fitness_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Tests run on the host (desktop) VM, so use the FFI database backend.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const HarryFitnessApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
