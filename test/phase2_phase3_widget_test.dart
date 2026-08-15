import 'package:flutter/material.dart';
import 'package:json_dynamic_form/json_dynamic_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders Phase 2 selection fields', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DynamicForm(
            json: {
              'title': 'Prefs',
              'fields': [
                {
                  'type': 'checkbox',
                  'key': 'agree',
                  'label': 'I agree',
                },
                {
                  'type': 'switch',
                  'key': 'alerts',
                  'label': 'Alerts',
                },
                {
                  'type': 'dropdown',
                  'key': 'country',
                  'label': 'Country',
                  'options': [
                    {'value': 'IN', 'label': 'India'},
                    {'value': 'US', 'label': 'United States'},
                  ],
                },
                {
                  'type': 'chips',
                  'key': 'tags',
                  'label': 'Tags',
                  'options': ['Flutter', 'Dart'],
                },
              ],
            },
          ),
        ),
      ),
    );

    expect(find.text('Prefs'), findsOneWidget);
    expect(find.text('I agree'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Country'), findsWidgets);
    expect(find.text('Tags'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
  });

  testWidgets('conditional field appears when condition met', (tester) async {
    final controller = DynamicFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DynamicForm(
            controller: controller,
            json: const {
              'fields': [
                {
                  'type': 'dropdown',
                  'key': 'country',
                  'label': 'Country',
                  'options': ['India', 'Other'],
                },
                {
                  'type': 'text',
                  'key': 'state',
                  'label': 'State',
                  'visibleWhen': {
                    'field': 'country',
                    'operator': 'equals',
                    'value': 'India',
                  },
                },
              ],
            },
          ),
        ),
      ),
    );

    expect(find.text('State'), findsNothing);

    controller.updateField('country', 'India', validate: false);
    await tester.pumpAndSettle();

    expect(find.text('State'), findsWidgets);

    controller.dispose();
  });

  testWidgets('nested group renders children', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DynamicForm(
            json: {
              'title': 'Nested',
              'fields': [
                {
                  'type': 'group',
                  'key': 'account',
                  'label': 'Account',
                  'fields': [
                    {
                      'type': 'email',
                      'key': 'email',
                      'label': 'Email',
                    },
                  ],
                },
              ],
            },
          ),
        ),
      ),
    );

    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Email'), findsWidgets);
  });
}
