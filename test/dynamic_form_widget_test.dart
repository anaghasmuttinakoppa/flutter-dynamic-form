import 'package:flutter/material.dart';
import 'package:flutter_dynamic_form/flutter_dynamic_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final schema = <String, dynamic>{
    'title': 'User Registration',
    'fields': [
      {
        'type': 'text',
        'key': 'name',
        'label': 'Full Name',
        'required': true,
      },
      {
        'type': 'email',
        'key': 'email',
        'label': 'Email',
        'required': true,
      },
      {
        'type': 'number',
        'key': 'age',
        'label': 'Age',
      },
      {
        'type': 'password',
        'key': 'password',
        'label': 'Password',
        'required': true,
      },
      {
        'type': 'phone',
        'key': 'phone',
        'label': 'Phone',
      },
      {
        'type': 'multiline',
        'key': 'notes',
        'label': 'Notes',
      },
    ],
  };

  testWidgets('renders title and Phase 1 fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DynamicForm(json: schema),
        ),
      ),
    );

    expect(find.text('User Registration'), findsOneWidget);
    expect(find.text('Full Name'), findsWidgets);
    expect(find.text('Email'), findsWidgets);
    expect(find.text('Age'), findsWidgets);
    expect(find.text('Password'), findsWidgets);
    expect(find.text('Phone'), findsWidgets);
    expect(find.text('Notes'), findsWidgets);
    expect(find.text('Submit'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
  });

  testWidgets('submit surfaces validation errors', (tester) async {
    final controller = DynamicFormController();
    Map<String, String>? failed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DynamicForm(
            json: schema,
            controller: controller,
            onValidationFailed: (errors) => failed = errors,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(failed, isNotNull);
    expect(failed!.containsKey('name'), isTrue);
    expect(failed!.containsKey('email'), isTrue);
    expect(find.textContaining('required'), findsWidgets);

    controller.dispose();
  });

  testWidgets('successful submit returns values', (tester) async {
    final controller = DynamicFormController();
    Map<String, dynamic>? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DynamicForm(
            json: schema,
            controller: controller,
            onSubmit: (values) => submitted = values,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'Ada Lovelace');
    await tester.enterText(find.byType(TextField).at(1), 'ada@example.com');
    await tester.enterText(find.byType(TextField).at(2), '36');
    await tester.enterText(find.byType(TextField).at(3), 'secret123');
    await tester.enterText(find.byType(TextField).at(4), '+15550100');
    await tester.enterText(find.byType(TextField).at(5), 'Notes here');

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!['name'], 'Ada Lovelace');
    expect(submitted!['email'], 'ada@example.com');
    expect(submitted!['age'], 36);

    controller.dispose();
  });

  testWidgets('reset restores defaults', (tester) async {
    final controller = DynamicFormController();
    final withDefaults = <String, dynamic>{
      'title': 'Defaults',
      'fields': [
        {
          'type': 'text',
          'key': 'name',
          'label': 'Name',
          'defaultValue': 'Ada',
        },
      ],
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DynamicForm(
            json: withDefaults,
            controller: controller,
          ),
        ),
      ),
    );

    expect(find.text('Ada'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Grace');
    await tester.pump();
    expect(controller.values['name'], 'Grace');

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(controller.values['name'], 'Ada');
    expect(find.text('Ada'), findsOneWidget);

    controller.dispose();
  });
}
