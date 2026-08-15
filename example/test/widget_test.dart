import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home lists Phase 1–5 demos', (tester) async {
    await tester.pumpWidget(const DynamicFormExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('json_dynamic_form'), findsOneWidget);
    expect(find.text('Simple Form'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Media Upload'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Media Upload'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Advanced Controls'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Advanced Controls'), findsOneWidget);
  });
}
