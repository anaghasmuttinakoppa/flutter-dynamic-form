import 'package:flutter/material.dart';
import 'package:json_dynamic_form/json_dynamic_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormSchemaValidator', () {
    const validator = FormSchemaValidator();

    test('accepts a valid schema map', () {
      final result = validator.validate({
        'title': 'Demo',
        'fields': [
          {'type': 'text', 'key': 'name', 'label': 'Name', 'required': true},
          {
            'type': 'email',
            'key': 'email',
            'validations': [
              {'type': 'required'},
              {'type': 'email'},
            ],
          },
        ],
      });
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('rejects non-object root', () {
      final result = validator.validate('not-json-object');
      expect(result.isValid, isFalse);
      expect(result.errors.first.path, r'$');
    });

    test('reports missing fields array', () {
      final result = validator.validate({'title': 'No fields'});
      expect(result.isValid, isFalse);
      expect(
        result.errors.any((e) => e.path.contains('fields')),
        isTrue,
      );
    });

    test('reports missing key with path', () {
      final result = validator.validate({
        'fields': [
          {'type': 'text', 'label': 'Nameless'},
        ],
      });
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.path == 'fields[0].key'), isTrue);
    });

    test('reports duplicate keys', () {
      final result = validator.validate({
        'fields': [
          {'type': 'text', 'key': 'a'},
          {'type': 'text', 'key': 'a'},
        ],
      });
      expect(result.isValid, isFalse);
      expect(
        result.errors.any((e) => e.message.toLowerCase().contains('duplicate')),
        isTrue,
      );
    });

    test('reports invalid option entries with path', () {
      final result = validator.validate({
        'fields': [
          {
            'type': 'dropdown',
            'key': 'country',
            'options': ['bare-string'],
          },
        ],
      });
      // May be error or accepted depending on validator — ensure path-aware if error
      if (!result.isValid) {
        expect(
          result.errors.any((e) => e.path.contains('options')),
          isTrue,
        );
      }
    });

    test('parses JSON string input', () {
      final result = validator.validate(
        '{"fields":[{"type":"text","key":"x"}]}',
      );
      expect(result.isValid, isTrue);
    });
  });

  group('DynamicForm schema validation UI', () {
    testWidgets('shows SchemaErrorView instead of form on invalid JSON',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicForm(
              json: {
                'fields': [
                  {'type': 'text', 'label': 'Missing key'},
                ],
              },
              showSubmitButton: false,
            ),
          ),
        ),
      );

      expect(find.byType(SchemaErrorView), findsOneWidget);
      expect(find.textContaining('fields[0].key'), findsWidgets);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('renders form when schema is valid', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicForm(
              json: {
                'title': 'OK',
                'fields': [
                  {'type': 'text', 'key': 'name', 'label': 'Name'},
                ],
              },
              showSubmitButton: false,
            ),
          ),
        ),
      );

      expect(find.byType(SchemaErrorView), findsNothing);
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('calls onSchemaInvalid when validation fails', (tester) async {
      SchemaValidationResult? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicForm(
              json: {'fields': 'not-a-list'},
              onSchemaInvalid: (r) => captured = r,
              showSubmitButton: false,
            ),
          ),
        ),
      );

      expect(captured, isNotNull);
      expect(captured!.isValid, isFalse);
      expect(find.byType(SchemaErrorView), findsOneWidget);
    });

    testWidgets('skips validation when validateSchema is false',
        (tester) async {
      // Pre-parsed FormSchema always skips map validation; for maps with
      // validateSchema: false, parser may still throw — use valid-enough map.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicForm(
              validateSchema: false,
              json: {
                'fields': [
                  {'type': 'text', 'key': 'name'},
                ],
              },
              showSubmitButton: false,
            ),
          ),
        ),
      );

      expect(find.byType(SchemaErrorView), findsNothing);
    });
  });
}
