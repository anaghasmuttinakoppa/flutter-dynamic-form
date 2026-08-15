import 'package:json_driven_dynamic_form/json_driven_dynamic_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 2 parsing', () {
    test('parses selection and date field types', () {
      final schema = FormSchema.fromJson({
        'fields': [
          {
            'type': 'checkbox',
            'key': 'agree',
            'label': 'Agree',
          },
          {
            'type': 'switch',
            'key': 'notify',
          },
          {
            'type': 'dropdown',
            'key': 'country',
            'options': [
              {'value': 'IN', 'label': 'India'},
              'US',
            ],
          },
          {
            'type': 'radio',
            'key': 'color',
            'options': ['red', 'blue'],
          },
          {
            'type': 'chips',
            'key': 'tags',
            'options': ['a', 'b'],
          },
          {'type': 'date', 'key': 'dob'},
          {'type': 'time', 'key': 'slot'},
          {'type': 'datetime', 'key': 'when'},
        ],
      });

      expect(schema.fields.map((f) => f.type), [
        FieldType.checkbox,
        FieldType.switchField,
        FieldType.dropdown,
        FieldType.radio,
        FieldType.chips,
        FieldType.date,
        FieldType.time,
        FieldType.dateTime,
      ]);
      expect(schema.fields[0].defaultValue, false);
      expect(schema.fields[4].defaultValue, isA<List<dynamic>>());
      expect(schema.fields[2].options, hasLength(2));
    });

    test('parses visibleWhen conditions', () {
      final field = FormFieldSchema.fromJson({
        'type': 'text',
        'key': 'state',
        'visibleWhen': {
          'field': 'country',
          'operator': 'equals',
          'value': 'India',
        },
      });
      expect(field.visibleWhen, isNotNull);
      expect(field.visibleWhen!.conditions.first.field, 'country');
    });
  });

  group('Phase 3 nested + compare', () {
    test('parses nested groups with unique keys', () {
      final schema = FormSchema.fromJson({
        'fields': [
          {
            'type': 'group',
            'key': 'account',
            'label': 'Account',
            'fields': [
              {'type': 'email', 'key': 'email'},
              {'type': 'password', 'key': 'password'},
            ],
          },
        ],
      });

      expect(schema.fields.first.type, FieldType.group);
      expect(schema.leafFields.map((f) => f.key), ['email', 'password']);
      expect(schema.fieldByKey('email')?.type, FieldType.email);
    });

    test('rejects duplicate nested keys', () {
      expect(
        () => FormSchema.fromJson({
          'fields': [
            {'type': 'text', 'key': 'name'},
            {
              'type': 'group',
              'key': 'profile',
              'fields': [
                {'type': 'text', 'key': 'name'},
              ],
            },
          ],
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('compare validator matches another field', () {
      final field = FormFieldSchema.fromJson({
        'type': 'password',
        'key': 'confirm',
        'validators': [
          {
            'type': 'compare',
            'field': 'password',
            'operator': 'equals',
            'message': 'Must match',
          },
        ],
      });

      expect(
        Validators.validateField(
          field: field,
          value: 'secret',
          values: {'password': 'secret', 'confirm': 'secret'},
        ),
        isNull,
      );
      expect(
        Validators.validateField(
          field: field,
          value: 'nope',
          values: {'password': 'secret', 'confirm': 'nope'},
        ),
        'Must match',
      );
    });
  });

  group('Controller conditions', () {
    late DynamicFormController controller;

    setUp(() {
      controller = DynamicFormController();
      controller.bind(
        FormSchema.fromJson({
          'fields': [
            {
              'type': 'dropdown',
              'key': 'country',
              'options': ['India', 'Other'],
            },
            {
              'type': 'text',
              'key': 'state',
              'required': true,
              'visibleWhen': {
                'field': 'country',
                'operator': 'equals',
                'value': 'India',
              },
            },
            {
              'type': 'number',
              'key': 'age',
              'defaultValue': 20,
            },
            {
              'type': 'checkbox',
              'key': 'terms',
              'enabledWhen': {'field': 'age', 'op': 'gte', 'value': 18},
            },
          ],
        }),
      );
    });

    tearDown(() => controller.dispose());

    test('visibility reacts to values', () {
      expect(controller.isVisible('state'), isFalse);
      controller.updateField('country', 'India', validate: false);
      expect(controller.isVisible('state'), isTrue);
      controller.updateField('country', 'Other', validate: false);
      expect(controller.isVisible('state'), isFalse);
    });

    test('validate skips hidden required fields', () {
      controller.updateField('country', 'Other', validate: false);
      expect(controller.validate(), isTrue);
      controller.updateField('country', 'India', validate: false);
      expect(controller.validate(), isFalse);
      expect(controller.errors.containsKey('state'), isTrue);
    });

    test('enabledWhen disables fields', () {
      expect(controller.isEnabled('terms'), isTrue);
      controller.updateField('age', 15, validate: false);
      expect(controller.isEnabled('terms'), isFalse);
    });

    test('nestedValues nests group children', () {
      controller.bind(
        FormSchema.fromJson({
          'fields': [
            {
              'type': 'group',
              'key': 'account',
              'fields': [
                {
                  'type': 'email',
                  'key': 'email',
                  'defaultValue': 'a@b.co',
                },
              ],
            },
            {'type': 'text', 'key': 'name', 'defaultValue': 'Ada'},
          ],
        }),
      );
      expect(controller.nestedValues['account'], {'email': 'a@b.co'});
      expect(controller.nestedValues['name'], 'Ada');
    });
  });
}
