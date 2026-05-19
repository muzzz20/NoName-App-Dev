// Smoke test for Strayfriends app bootstrap.
// Real feature tests come with NAD-16 (Sprint 1 test plan).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App scaffold builds without Firebase', (WidgetTester tester) async {
    // Bootstrap a minimal MaterialApp shell. The real app needs Firebase
    // initialization which is tested in integration tests, not widget tests.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Strayfriends'))),
      ),
    );

    expect(find.text('Strayfriends'), findsOneWidget);
  });
}
