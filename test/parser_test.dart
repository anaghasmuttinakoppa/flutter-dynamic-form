import 'package:flutter_dynamic_form/flutter_dynamic_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormSchemaParser', () {
    const parser = FormSchemaParser();

    test('parses a map with Phase 1 fields', () {
      final schema = parser.parseMap(<String, dynamic>{
        'title': 'User Registration',
        'fields': [
          {
            'type': 'text',
            'key': 'name',
            'label': 'Full Name',
            'required': true,
          },
          {'type': 'email', 'key': 'email', 'required': true},
          {'type': 'number', 'key': 'age'},
        ],
      });

      expect(schema.title, 'User Registration');
      expect(schema.fields, hasLength(3));
      expect(schema.fields[0].type, FieldType.text);
      expect(schema.fields[0].required, isTrue);
      expect(
        schema.fields[0].validators
            .any((r) => r.type == ValidatorType.required),
        isTrue,
      );
      expect(schema.fields[1].type, FieldType.email);
      expect(
        schema.fields[1].validators.any((r) => r.type == ValidatorType.email),
        isTrue,
      );
      expect(schema.fields[2].type, FieldType.number);
    });

    test('parses a JSON string', () {
      const source = '''
      {
        "title": "Demo",
        "fields": [
          {"type": "password", "key": "password", "required": true},
          {"type": "phone", "key": "phone"},
          {"type": "multiline", "key": "notes"}
        ]
      }
      ''';

      final schema = parser.parseString(source);
      expect(schema.fields.map((f) => f.type), [
        FieldType.password,
        FieldType.phone,
        FieldType.multiline,
      ]);
      expect(schema.fields.first.obscureText, isTrue);
    });

    test('rejects duplicate keys', () {
      expect(
        () => parser.parseMap(<String, dynamic>{
          'fields': [
            {'type': 'text', 'key': 'name'},
            {'type': 'email', 'key': 'name'},
          ],
        }),
        throwsA(isA<FormSchemaParseException>()),
      );
    });

    test('rejects missing key', () {
      expect(
        () => parser.parseMap(<String, dynamic>{
          'fields': [
            {'type': 'text', 'label': 'No key'},
          ],
        }),
        throwsA(isA<FormSchemaParseException>()),
      );
    });
  });

  group('FieldType', () {
    test('aliases map correctly', () {
      expect(FieldType.fromString('textarea'), FieldType.multiline);
      expect(FieldType.fromString('tel'), FieldType.phone);
      expect(FieldType.fromString('integer'), FieldType.number);
      expect(FieldType.fromString('weird'), FieldType.unknown);
    });
  });
}
