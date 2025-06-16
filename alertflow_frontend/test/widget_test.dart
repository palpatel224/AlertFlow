// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:alertflow_frontend/providers/alert_provider.dart';
import 'package:alertflow_frontend/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen widget test', (WidgetTester tester) async {
    // Build a minimal app for testing
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (context) => AlertProvider(),
          child: const HomeScreen(),
        ),
      ),
    );

    // Verify that the app bar title is present
    expect(find.text('AlertFlow'), findsOneWidget);

    // Verify that the tabs are present
    expect(find.text('All Alerts'), findsOneWidget);
    expect(find.text('Nearby'), findsOneWidget);
    expect(find.text('Critical'), findsOneWidget);
  });
}
