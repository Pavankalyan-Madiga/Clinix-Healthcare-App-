import 'package:clinix/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets(
    'Clinix app loads',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ClinixApp(),
        ),
      );

      await tester.pump();
      await tester.pump(
        const Duration(milliseconds: 500),
      );

      expect(
        find.byType(MaterialApp),
        findsOneWidget,
      );
    },
  );
}